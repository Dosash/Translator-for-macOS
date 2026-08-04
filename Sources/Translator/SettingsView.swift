import SwiftUI
import Carbon.HIToolbox

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @State private var axTrusted = SelectionGrabber.isTrusted

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                sectionTitle(L10n.t("section.language"))
                sectionCard {
                    languageRow
                }

                sectionTitle(L10n.t("section.theme"))
                sectionCard {
                    themeRow
                }

                sectionTitle(L10n.t("section.panel"))
                sectionCard {
                    panelSizeRow
                }

                sectionTitle(L10n.t("section.hotkeys"))
                sectionCard {
                    hotkeyRow(
                        title: L10n.t("hotkey.selection"),
                        caption: "Имитирует ⌘C — требует разрешения «Универсальный доступ»",
                        hotkey: $settings.selectionHotkey
                    )
                    Divider()
                    serviceRow
                    Divider()
                    hotkeyRow(
                        title: L10n.t("hotkey.clipboard"),
                        caption: "Переводит то, что уже скопировано (⌘C)",
                        hotkey: $settings.clipboardHotkey
                    )
                    Divider()
                    permissionRow
                }

                sectionTitle(L10n.t("section.behavior"))
                sectionCard {
                    toggleRow(
                        title: L10n.t("auto.translate"),
                        isOn: $settings.autoTranslate
                    )
                    Divider()
                    toggleRow(
                        title: L10n.t("offline.only"),
                        caption: L10n.t("offline.only.caption"),
                        isOn: $settings.offlineOnly
                    )
                    Divider()
                    toggleRow(
                        title: L10n.t("launch.login"),
                        isOn: $settings.launchAtLogin
                    )
                    if let message = settings.loginItemMessage {
                        Text(message)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Theme.roseInk)
                    }
                }

                sectionTitle(L10n.t("section.updates"))
                sectionCard {
                    updateRow
                }

                Text(L10n.t("version.footer"))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(18)
        }
        .frame(width: 460, height: 560)
        .themedPanel(cornerRadius: 0)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            axTrusted = SelectionGrabber.isTrusted
        }
    }

    // MARK: - Блоки

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.sage)
                    .frame(width: 34, height: 34)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.t("settings"))
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(L10n.t("settings.subtitle"))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
            Spacer()
        }
    }

    private var languageRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t("section.language"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(L10n.t("language.caption"))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Menu {
                ForEach(AppUILanguage.allCases) { language in
                    Button {
                        settings.appLanguage = language
                    } label: {
                        if settings.appLanguage == language {
                            Label(language.displayName, systemImage: "checkmark")
                        } else {
                            Text(language.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(settings.appLanguage.displayName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Capsule().fill(Theme.controlFill))
                .overlay(Capsule().stroke(Theme.controlStroke, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .environment(\.colorScheme, Theme.isDark ? .dark : .light)
        }
    }

    private var panelSizeRow: some View {
        HStack(spacing: 8) {
            ForEach(PanelSizeMode.allCases) { mode in
                panelSizeButton(mode)
            }
        }
    }

    private func panelSizeButton(_ mode: PanelSizeMode) -> some View {
        let isSelected = settings.panelSizeMode == mode
        return Button {
            settings.panelSizeMode = mode
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.sage : Theme.secondaryText)
                    Text(mode.nameRu)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                Text(mode.caption)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .lineLimit(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Theme.selectedControlFill : Theme.controlFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Theme.sage : Theme.controlStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var updateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("check.version"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(L10n.t("update.caption"))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button(settings.isCheckingForUpdates ? L10n.t("checking") : L10n.t("check")) {
                    settings.checkForUpdates()
                }
                .buttonStyle(PillButtonStyle())
                .disabled(settings.isCheckingForUpdates)
            }
            if let message = settings.updateMessage {
                Text(message)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var serviceRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Перевести выделенное без разрешений")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Системная служба — разрешения не нужны. Сменить сочетание: Системные настройки → Клавиатура → Сочетания клавиш → Службы")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Text("⇧⌘E")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sage)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.controlFill))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.cardStroke, lineWidth: 1))
        }
    }

    private var themeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(AppTheme.allCases) { theme in
                    themePreview(theme)
                }
            }
        }
    }

    private func themePreview(_ theme: AppTheme) -> some View {
        let isSelected = settings.appTheme == theme
        return Button {
            settings.appTheme = theme
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient(
                        colors: themePreviewColors(theme),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Circle()
                            .fill(themePreviewAccent(theme))
                            .shadow(
                                color: themePreviewGlow(theme),
                                radius: theme == .neonGlass ? 5 : 2
                            )
                            .frame(width: 12, height: 12)
                    )
                    .frame(width: 28, height: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(theme.nameRu)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Text(theme.caption)
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.48))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.ink)
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Theme.selectedControlFill : Theme.controlFill)
            )
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Theme.sage : Theme.controlStroke, lineWidth: isSelected ? 2 : 1)
                    if isSelected {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.sage)
                                Spacer()
                            }
                        }
                        .padding(8)
                    }
                }
            )
            .shadow(color: isSelected ? Theme.glow : .clear, radius: isSelected ? 8 : 0, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func themePreviewColors(_ theme: AppTheme) -> [Color] {
        switch theme {
        case .calmGlass:
            return [Color(hex: 0xF8FBFA), Color(hex: 0xEAF6F2), Color(hex: 0xEAF2F8)]
        case .neonGlass:
            return [Color(hex: 0x0A1524), Color(hex: 0x28113A)]
        case .frostGlass:
            return [Color(hex: 0xF7FAFD), Color(hex: 0xD8E2EC)]
        }
    }

    private func themePreviewAccent(_ theme: AppTheme) -> Color {
        theme == .calmGlass ? Color(hex: 0x28A97A) : Theme.systemAccent
    }

    private func themePreviewGlow(_ theme: AppTheme) -> Color {
        switch theme {
        case .calmGlass:
            return Color(hex: 0x8FCAB9).opacity(0.55)
        case .neonGlass:
            return Theme.systemAccent.opacity(0.8)
        case .frostGlass:
            return Color.white.opacity(0.8)
        }
    }

    private var permissionRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(axTrusted ? Theme.sage : Theme.rose)
                    .frame(width: 7, height: 7)
                Text(axTrusted
                    ? "Разрешение «Универсальный доступ» выдано"
                    : "Для перевода выделенного нужно разрешение «Универсальный доступ»")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                Spacer()
                if !axTrusted {
                    Button("Выдать…") {
                        SelectionGrabber.promptForPermission()
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        )
                    }
                    .buttonStyle(PillButtonStyle())
                }
            }
            if !axTrusted {
                Text("Настройки → Конфиденциальность и безопасность → Универсальный доступ → включите «Translator». Если Translator уже в списке, но не работает — удалите его кнопкой «−», добавьте заново и перезапустите переводчик.")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func hotkeyRow(title: String, caption: String, hotkey: Binding<Hotkey>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(caption)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.5))
            }
            Spacer()
            HotkeyRecorderView(hotkey: hotkey, isRecordingGlobal: $settings.isRecordingHotkey)
        }
    }

    private func toggleRow(title: String, caption: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                if let caption {
                    Text(caption)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Theme.sage)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.sage)
            .padding(.leading, 4)
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .themedSurface(cornerRadius: 12)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.cardStroke, lineWidth: 1))
    }
}

// MARK: - Рекордер сочетания клавиш

struct HotkeyRecorderView: View {
    @Binding var hotkey: Hotkey
    @Binding var isRecordingGlobal: Bool

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            isRecording ? stopRecording() : startRecording()
        } label: {
            Text(isRecording ? "Нажмите сочетание…" : hotkey.display)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(isRecording ? Theme.roseInk : Theme.ink)
                .frame(minWidth: 96)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isRecording ? Theme.rose.opacity(0.25) : Theme.controlFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isRecording ? Theme.rose : Theme.cardStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("Нажмите, затем введите новое сочетание. Esc — отмена.")
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        isRecordingGlobal = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handle(event)
            return nil // событие поглощаем, чтобы оно не ушло дальше
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
        isRecordingGlobal = false
    }

    private func handle(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return
        }

        let carbonModifiers = Self.carbonModifiers(from: event.modifierFlags)
        // Требуем ⌘, ⌃ или ⌥, чтобы не перехватывать обычный набор текста.
        let hasRealModifier = carbonModifiers & UInt32(cmdKey | controlKey | optionKey) != 0
        guard hasRealModifier else { return }

        hotkey = Hotkey(
            keyCode: UInt32(event.keyCode),
            modifiers: carbonModifiers,
            display: Self.modifierSymbols(from: event.modifierFlags) + Self.keyLabel(for: event)
        )
        stopRecording()
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        return modifiers
    }

    private static func modifierSymbols(from flags: NSEvent.ModifierFlags) -> String {
        var symbols = ""
        if flags.contains(.control) { symbols += "⌃" }
        if flags.contains(.option) { symbols += "⌥" }
        if flags.contains(.shift) { symbols += "⇧" }
        if flags.contains(.command) { symbols += "⌘" }
        return symbols
    }

    private static func keyLabel(for event: NSEvent) -> String {
        switch Int(event.keyCode) {
        case kVK_Space: return "Пробел"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        default:
            return event.charactersIgnoringModifiers?.uppercased() ?? "?"
        }
    }
}
