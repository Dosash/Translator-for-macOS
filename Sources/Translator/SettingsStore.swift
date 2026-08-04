import AppKit
import Carbon.HIToolbox
import Foundation
import ServiceManagement

struct Hotkey: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32 // модификаторы Carbon (controlKey, optionKey, …)
    var display: String   // например «⌃⌥T»
}

enum PanelSizeMode: String, CaseIterable, Identifiable {
    case compact
    case standard
    case wide

    var id: String { rawValue }

    static func stored(_ rawValue: String?) -> PanelSizeMode {
        PanelSizeMode(rawValue: rawValue ?? "") ?? .standard
    }

    var nameRu: String {
        localizedName
    }

    var caption: String {
        localizedCaption
    }

    var localizedName: String {
        switch self {
        case .compact: return L10n.t("panel.compact")
        case .standard: return L10n.t("panel.standard")
        case .wide: return L10n.t("panel.wide")
        }
    }

    var localizedCaption: String {
        switch self {
        case .compact: return L10n.t("panel.compact.caption")
        case .standard: return L10n.t("panel.standard.caption")
        case .wide: return L10n.t("panel.wide.caption")
        }
    }

    var panelWidth: CGFloat {
        switch self {
        case .compact: return 360
        case .standard: return 400
        case .wide: return 500
        }
    }

    var textAreaHeight: CGFloat {
        switch self {
        case .compact: return 72
        case .standard: return 84
        case .wide: return 116
        }
    }

    var resultHeight: CGFloat {
        switch self {
        case .compact: return 72
        case .standard: return 84
        case .wide: return 126
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var selectionHotkey: Hotkey {
        didSet { saveHotkey(selectionHotkey, key: "selectionHotkey"); onHotkeysChanged?() }
    }
    @Published var clipboardHotkey: Hotkey {
        didSet { saveHotkey(clipboardHotkey, key: "clipboardHotkey"); onHotkeysChanged?() }
    }
    @Published var autoTranslate: Bool {
        didSet { UserDefaults.standard.set(autoTranslate, forKey: "autoTranslate") }
    }
    @Published var offlineOnly: Bool {
        didSet { UserDefaults.standard.set(offlineOnly, forKey: "offlineOnly") }
    }
    @Published var appTheme: AppTheme {
        didSet { UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme") }
    }
    @Published var panelSizeMode: PanelSizeMode {
        didSet { UserDefaults.standard.set(panelSizeMode.rawValue, forKey: "panelSizeMode") }
    }
    @Published var appLanguage: AppUILanguage {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage") }
    }
    @Published var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }
    }
    @Published var hasCompletedFirstRun: Bool {
        didSet { UserDefaults.standard.set(hasCompletedFirstRun, forKey: "hasCompletedFirstRun") }
    }
    @Published var loginItemMessage: String?
    @Published var updateMessage: String?
    @Published var isCheckingForUpdates = false

    /// Пока идёт запись сочетания, глобальные хоткеи надо снять,
    /// иначе нажатие текущего сочетания сработает, а не запишется.
    @Published var isRecordingHotkey = false {
        didSet { onRecordingStateChanged?(isRecordingHotkey) }
    }

    var onHotkeysChanged: (() -> Void)?
    var onRecordingStateChanged: ((Bool) -> Void)?

    init() {
        let defaults = UserDefaults.standard
        Self.migrateDefaultThemeIfNeeded(defaults: defaults)

        selectionHotkey = Self.loadHotkey(key: "selectionHotkey") ?? Hotkey(
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(controlKey | optionKey),
            display: "⌃⌥T"
        )
        clipboardHotkey = Self.loadHotkey(key: "clipboardHotkey") ?? Hotkey(
            keyCode: UInt32(kVK_ANSI_C),
            modifiers: UInt32(controlKey | optionKey),
            display: "⌃⌥C"
        )
        autoTranslate = defaults.object(forKey: "autoTranslate") as? Bool ?? true
        offlineOnly = defaults.object(forKey: "offlineOnly") as? Bool ?? false
        appTheme = AppTheme.stored(defaults.string(forKey: "appTheme"))
        panelSizeMode = PanelSizeMode.stored(defaults.string(forKey: "panelSizeMode"))
        appLanguage = AppUILanguage.stored(defaults.string(forKey: "appLanguage"))
        launchAtLogin = SMAppService.mainApp.status == .enabled
        hasCompletedFirstRun = defaults.object(forKey: "hasCompletedFirstRun") as? Bool ?? false
    }

    private static func migrateDefaultThemeIfNeeded(defaults: UserDefaults) {
        let migrationKey = "didMigrateDefaultThemeToCalmGlass"
        guard defaults.object(forKey: migrationKey) == nil else { return }

        if defaults.string(forKey: "appTheme") == nil || defaults.string(forKey: "appTheme") == AppTheme.frostGlass.rawValue {
            defaults.set(AppTheme.calmGlass.rawValue, forKey: "appTheme")
        }
        defaults.set(true, forKey: migrationKey)
    }

    func completeFirstRun() {
        hasCompletedFirstRun = true
    }

    func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        updateMessage = nil
        Task {
            let result = await UpdateChecker.check()
            isCheckingForUpdates = false
            updateMessage = result.message
        }
    }

    // MARK: - Автозапуск

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemMessage = nil
        } catch {
            loginItemMessage = "Не удалось изменить автозапуск: \(error.localizedDescription)"
        }
    }

    // MARK: - Хранение сочетаний

    private func saveHotkey(_ hotkey: Hotkey, key: String) {
        UserDefaults.standard.set(
            ["keyCode": Int(hotkey.keyCode), "modifiers": Int(hotkey.modifiers), "display": hotkey.display],
            forKey: key
        )
    }

    private static func loadHotkey(key: String) -> Hotkey? {
        guard
            let dict = UserDefaults.standard.dictionary(forKey: key),
            let keyCode = dict["keyCode"] as? Int,
            let modifiers = dict["modifiers"] as? Int,
            let display = dict["display"] as? String
        else { return nil }
        return Hotkey(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers), display: display)
    }
}
