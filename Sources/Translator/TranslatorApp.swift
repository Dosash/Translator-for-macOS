import AppKit
import SwiftUI
import Translation

@main
enum TranslatorMain {
    static func main() {
        let args = CommandLine.arguments

        // Тестовый режим для проверки онлайн-движка из терминала:
        //   ./Translator --test-translate "hello world"
        if let index = args.firstIndex(of: "--test-translate"), args.count > index + 1 {
            let text = args[index + 1]
            let semaphore = DispatchSemaphore(value: 0)
            Task.detached {
                do {
                    let (source, target) = TranslationService.detectDirection(for: text)
                    let engine = GoogleTranslateEngine()
                    let result = try await engine.translate(text, from: source, to: target)
                    print(result.text)
                } catch {
                    FileHandle.standardError.write(Data("Ошибка: \(error.localizedDescription)\n".utf8))
                }
                semaphore.signal()
            }
            semaphore.wait()
            return
        }

        // Проверка статуса офлайн-языков Apple Translation:
        //   ./Translator --test-offline
        // Важно: главный run loop должен работать, иначе ответы XPC не приходят.
        if args.contains("--test-offline") {
            Task.detached {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                print("TIMEOUT: система не ответила за 30 секунд")
                exit(2)
            }
            Task { @MainActor in
                let availability = LanguageAvailability()
                let languages = await availability.supportedLanguages
                let relevant = languages.filter {
                    ["ru", "en"].contains($0.languageCode?.identifier ?? "")
                }
                print("Варианты ru/en в системе: \(relevant.map(\.maximalIdentifier).sorted())")
                for (source, target) in [("ru", "en"), ("en", "ru")] {
                    let status = await availability.status(
                        from: Locale.Language(identifier: source),
                        to: Locale.Language(identifier: target)
                    )
                    print("\(source) → \(target): \(String(describing: status))")
                }
                exit(0)
            }
            RunLoop.main.run()
            return
        }

        // Проверка системной службы: отправляет текст запущенному переводчику
        // тем же путём, что и «Службы» в macOS:
        //   ./Translator --test-service "hello world"
        if let index = args.firstIndex(of: "--test-service"), args.count > index + 1 {
            let pboard = NSPasteboard(name: NSPasteboard.Name("TranslatorServiceTest"))
            pboard.clearContents()
            pboard.setString(args[index + 1], forType: .string)
            let delivered = NSPerformService("Перевести выделенный текст", pboard)
            print(delivered ? "SERVICE OK" : "SERVICE FAIL")
            return
        }

        // Полный тест офлайн-движка (нужно окно, т.к. Translation — SwiftUI API):
        //   ./Translator --test-apple "hello world"
        if let index = args.firstIndex(of: "--test-apple"), args.count > index + 1 {
            let app = NSApplication.shared
            let delegate = AppleTestDelegate(text: args[index + 1])
            app.delegate = delegate
            app.run()
            return
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

// MARK: - Тест офлайн-движка

@MainActor
final class AppleTestDelegate: NSObject, NSApplicationDelegate {
    private let text: String
    private var window: NSWindow?

    init(text: String) {
        self.text = text
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 120),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "Тест офлайн-перевода"
        window.contentViewController = NSHostingController(rootView: AppleTestView(text: text))
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct AppleTestView: View {
    let text: String
    @State private var config: TranslationSession.Configuration?

    var body: some View {
        Text("Тестирую офлайн-перевод…")
            .padding(30)
            .onAppear {
                let (source, target) = TranslationService.detectDirection(for: text)
                config = TranslationSession.Configuration(
                    source: Locale.Language(identifier: source),
                    target: Locale.Language(identifier: target)
                )
            }
            .translationTask(config) { session in
                do {
                    let response = try await session.translate(text)
                    print("OFFLINE OK: \(response.targetText)")
                } catch {
                    print("OFFLINE FAIL: \(error)")
                }
                NSApp.terminate(nil)
            }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel!
    private var bubble: BubblePanel!
    private let model = TranslatorModel()
    private let hotkey = HotkeyManager()
    private let settings = SettingsStore()
    private var downloadWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?
    private var firstRunWindow: NSWindow?
    private var panelWasVisibleBeforeAux = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        model.settings = settings
        model.onDownloadRequest = { [weak self] in
            self?.showDownloadWindow()
        }
        model.onOpenSettings = { [weak self] in
            self?.showSettingsWindow()
        }
        model.onOpenHistory = { [weak self] in
            self?.showHistoryWindow()
        }
        settings.onHotkeysChanged = { [weak self] in
            self?.registerHotkeys()
        }
        settings.onRecordingStateChanged = { [weak self] isRecording in
            if isRecording {
                self?.hotkey.unregisterAll()
            } else {
                self?.registerHotkeys()
            }
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = MenuBarIcon.make()
            button.toolTip = "Переводчик"
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        panel = FloatingPanel(
            contentViewController: NSHostingController(rootView: TranslatorView(model: model))
        )

        bubble = BubblePanel(
            contentViewController: NSHostingController(rootView: BubbleView(
                model: model,
                onReplace: { [weak self] in self?.replaceSelectionWithTranslation() },
                onExpand: { [weak self] in
                    self?.bubble.hide()
                    self?.showPanel()
                }
            ))
        )

        registerHotkeys()
        model.schedulePeriodicOfflineUpdateCheck()

        if !settings.hasCompletedFirstRun {
            Task { @MainActor in
                showFirstRunWindow()
            }
        }

        // Системная служба «Перевести выделенный текст» — работает без
        // каких-либо разрешений (текст передаёт сама macOS).
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    /// Вызывается системой: правый клик → Службы → «Перевести выделенный
    /// текст» или сочетание ⇧⌘6 на выделенном тексте.
    @objc func translateSelectedText(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        let text = pboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }
        showPanel()
        model.inputText = text
        model.translate()
    }

    private func registerHotkeys() {
        hotkey.setHotkey(
            id: HotkeyManager.selectionHotkeyID,
            keyCode: settings.selectionHotkey.keyCode,
            modifiers: settings.selectionHotkey.modifiers
        ) { [weak self] in
            self?.translateSelection()
        }
        hotkey.setHotkey(
            id: HotkeyManager.clipboardHotkeyID,
            keyCode: settings.clipboardHotkey.keyCode,
            modifiers: settings.clipboardHotkey.modifiers
        ) { [weak self] in
            self?.translateClipboard()
        }
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        if panel.isVisible {
            panel.hide()
        } else if panel.justHidByOutsideClick {
            // Клик по иконке уже закрыл панель — не открываем её тут же снова.
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button else { return }
        bubble.hide()
        panel.show(under: button)
    }

    private func translateClipboard() {
        showPanel()
        let clipboard = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !clipboard.isEmpty else {
            model.errorMessage = "Буфер обмена пуст: сначала скопируйте текст (⌘C)."
            return
        }
        model.inputText = clipboard
        model.translate()
    }

    private func translateSelection() {
        DebugLog.write("hotkey выделения: нажат; AX trusted = \(SelectionGrabber.isTrusted)")
        guard SelectionGrabber.isTrusted else {
            showPanel()
            model.errorMessage = "Сочетание \(settings.selectionHotkey.display) имитирует ⌘C и требует разрешения «Универсальный доступ» (выдать можно в Настройках). Без разрешения: выделите текст и нажмите ⇧⌘E — сработает системная служба."
            return
        }
        Task { @MainActor in
            let selected = await SelectionGrabber.grabSelectedText()?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            // Точные координаты выделения — или, если программа их не отдаёт,
            // место у курсора мыши.
            let anchor = SelectionLocator.selectionRect() ?? SelectionLocator.mouseRect()
            panel.hide()
            guard let selected, !selected.isEmpty else {
                model.errorMessage = "Не удалось получить выделенный текст — возможно, ничего не выделено."
                bubble.show(near: anchor)
                return
            }
            // Прячем прошлый результат, чтобы облако не мигнуло старым переводом.
            model.errorMessage = nil
            model.outputText = ""
            model.engineUsed = ""
            model.inputText = selected
            model.translate()
            bubble.show(near: anchor)
        }
    }

    /// Кнопка «Заменить» в облаке: закрываем облако (фокус вернётся в целевую
    /// программу, где текст всё ещё выделен) и вставляем перевод через ⌘V.
    private func replaceSelectionWithTranslation() {
        let translation = model.outputText
        guard !translation.isEmpty else { return }
        bubble.hide()
        Task { @MainActor in
            await TextInserter.paste(translation)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let selectionItem = NSMenuItem(
            title: "\(L10n.t("hotkey.selection")) (\(settings.selectionHotkey.display))",
            action: #selector(menuTranslateSelection),
            keyEquivalent: ""
        )
        selectionItem.target = self
        menu.addItem(selectionItem)

        let clipboardItem = NSMenuItem(
            title: "\(L10n.t("hotkey.clipboard")) (\(settings.clipboardHotkey.display))",
            action: #selector(menuTranslateClipboard),
            keyEquivalent: ""
        )
        clipboardItem.target = self
        menu.addItem(clipboardItem)

        menu.addItem(.separator())

        let historyItem = NSMenuItem(
            title: L10n.t("history"),
            action: #selector(menuOpenHistory),
            keyEquivalent: ""
        )
        historyItem.target = self
        menu.addItem(historyItem)

        let settingsItem = NSMenuItem(
            title: L10n.t("settings"),
            action: #selector(menuOpenSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: L10n.t("quit"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func menuTranslateClipboard() {
        translateClipboard()
    }

    @objc private func menuTranslateSelection() {
        translateSelection()
    }

    @objc private func menuOpenSettings() {
        showSettingsWindow()
    }

    @objc private func menuOpenHistory() {
        showHistoryWindow()
    }

    private func showFirstRunWindow() {
        rememberPanelBeforeAux()

        if let firstRunWindow {
            firstRunWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Первый запуск"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentViewController = NSHostingController(rootView: FirstRunView(
            settings: settings,
            onOpenOfflineLanguages: { [weak self] in self?.showDownloadWindow() },
            onDone: { [weak self] in self?.firstRunWindow?.close() }
        ))
        window.center()
        firstRunWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showSettingsWindow() {
        rememberPanelBeforeAux()

        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Настройки переводчика"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentViewController = NSHostingController(rootView: SettingsView(settings: settings))
        window.center()
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Вспомогательное окно (настройки, история, офлайн-языки) закрылось:
    /// когда закрыто последнее из них, панель снова всплывает и, если её
    /// успели закрыть, возвращается на место.
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        let auxWindows = [settingsWindow, historyWindow, downloadWindow, firstRunWindow].compactMap { $0 }
        guard auxWindows.contains(where: { $0 === closingWindow }) else { return }

        if closingWindow === downloadWindow {
            downloadWindow = nil
        } else if closingWindow === settingsWindow {
            settingsWindow = nil
        } else if closingWindow === historyWindow {
            historyWindow = nil
        } else if closingWindow === firstRunWindow {
            firstRunWindow = nil
        }

        let stillOpen = auxWindows.filter { $0 !== closingWindow && $0.isVisible }
        guard stillOpen.isEmpty else { return }

        panel.keepsVisibleBehindOtherWindows = false
        if panelWasVisibleBeforeAux && !panel.isVisible {
            showPanel()
        }
        panelWasVisibleBeforeAux = false
    }

    private func showDownloadWindow() {
        rememberPanelBeforeAux()

        if let downloadWindow {
            downloadWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Офлайн-языки"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentViewController = NSHostingController(
            rootView: DownloadView(model: model) { [weak self] in
                self?.downloadWindow?.close()
            }
        )
        window.center()
        downloadWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showHistoryWindow() {
        rememberPanelBeforeAux()

        if let historyWindow {
            historyWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "История переводов"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentViewController = NSHostingController(rootView: HistoryView(model: model))
        window.center()
        historyWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Панель не прячем: она остаётся видна позади вспомогательного окна.
    private func rememberPanelBeforeAux() {
        panelWasVisibleBeforeAux = panel.isVisible || panelWasVisibleBeforeAux
        panel.keepsVisibleBehindOtherWindows = true
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
