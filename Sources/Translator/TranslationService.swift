import AVFoundation
import Foundation
import SwiftUI
import Translation

// MARK: - Языки

struct AppLanguage: Identifiable, Equatable {
    let googleCode: String // код для Google ("en", "zh-CN")
    let appleCode: String  // код для Apple Translation ("en", "zh")
    let speechCode: String // голос озвучки ("en-US")
    let nameRu: String

    var id: String { googleCode }
    var appleLanguage: Locale.Language { Locale.Language(identifier: appleCode) }

    static let all: [AppLanguage] = [
        AppLanguage(googleCode: "ru", appleCode: "ru", speechCode: "ru-RU", nameRu: "Русский"),
        AppLanguage(googleCode: "en", appleCode: "en", speechCode: "en-US", nameRu: "Английский"),
        AppLanguage(googleCode: "es", appleCode: "es", speechCode: "es-ES", nameRu: "Испанский"),
        AppLanguage(googleCode: "de", appleCode: "de", speechCode: "de-DE", nameRu: "Немецкий"),
        AppLanguage(googleCode: "fr", appleCode: "fr", speechCode: "fr-FR", nameRu: "Французский"),
        AppLanguage(googleCode: "it", appleCode: "it", speechCode: "it-IT", nameRu: "Итальянский"),
        AppLanguage(googleCode: "pt", appleCode: "pt", speechCode: "pt-BR", nameRu: "Португальский"),
        AppLanguage(googleCode: "zh-CN", appleCode: "zh", speechCode: "zh-CN", nameRu: "Китайский"),
        AppLanguage(googleCode: "ja", appleCode: "ja", speechCode: "ja-JP", nameRu: "Японский"),
        AppLanguage(googleCode: "ko", appleCode: "ko", speechCode: "ko-KR", nameRu: "Корейский"),
        AppLanguage(googleCode: "tr", appleCode: "tr", speechCode: "tr-TR", nameRu: "Турецкий"),
        AppLanguage(googleCode: "uk", appleCode: "uk", speechCode: "uk-UA", nameRu: "Украинский"),
    ]

    static func by(google code: String) -> AppLanguage? {
        all.first { $0.googleCode == code }
    }
}

enum OfflineState {
    case installed, supported, unsupported
}

// MARK: - История переводов

struct HistoryEntry: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let pair: String   // «Английский → Русский»
    let engine: String
    let input: String
    let output: String
}

enum TranslationService {
    /// Есть кириллица — переводим на английский, иначе — на русский
    /// (используется в тестовом режиме и для умного «Авто» пары ru/en).
    static func detectDirection(for text: String) -> (source: String, target: String) {
        hasCyrillic(text) ? ("ru", "en") : ("en", "ru")
    }

    static func hasCyrillic(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
    }
}

// MARK: - Модель

@MainActor
final class TranslatorModel: ObservableObject {
    /// Практический предел бесплатной точки Google за один запрос.
    static let maxInputChars = 5000
    static let historyLimit = 10
    /// Порог, после которого офлайн-перевод заметно нагружает процессор.
    static let offlineHeavyThreshold = 600
    static let offlineUpdateCheckInterval: TimeInterval = 7 * 24 * 60 * 60

    @Published var inputText = ""
    @Published var outputText = ""
    @Published var sourceCode = "auto" // "auto" или googleCode
    @Published var targetCode = "ru"
    @Published var isTranslating = false
    @Published var engineUsed = ""
    @Published var errorMessage: String?
    @Published var notice: String?
    @Published var offlineStatusText = "Проверяю офлайн-перевод…"
    @Published var offlineReady = false
    @Published var offlineUpdateMessage: String?
    @Published var offlineUpdateCodes: [String] = []
    @Published var history: [HistoryEntry] = []
    /// Состояние офлайн-пары «язык ↔ английский» для каждого языка.
    @Published var appleStatuses: [String: OfflineState] = [:]

    /// Конфигурация для view с .translationTask (движок Apple).
    @Published var appleConfig: TranslationSession.Configuration?

    var enginePrivacyText: String {
        if engineUsed.contains("Google") {
            return L10n.t("engine.google.privacy")
        }
        if engineUsed.contains("Apple") {
            return L10n.t("engine.apple.privacy")
        }
        if settings?.offlineOnly ?? false {
            return L10n.t("engine.offline.only")
        }
        return L10n.t("engine.pending")
    }

    var onDownloadRequest: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenHistory: (() -> Void)?
    weak var settings: SettingsStore?

    private let google = GoogleTranslateEngine()
    private let speech = AVSpeechSynthesizer()
    private var translationTask: Task<Void, Never>?
    private var autoTranslateTask: Task<Void, Never>?
    private var lastDetectedSource: String?
    private var lastTargetCode: String?
    private var offlineUpdateCheckTask: Task<Void, Never>?

    private var appleContinuation: CheckedContinuation<String, Error>?
    private var pendingAppleText: String?
    private var appleTimeoutTask: Task<Void, Never>?

    enum AppleError: LocalizedError {
        case timeout

        var errorDescription: String? {
            switch self {
            case .timeout: return "Офлайн-движок не ответил."
            }
        }
    }

    init() {
        history = Self.loadHistory()
    }

    // MARK: - Публичные действия

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard text.count <= Self.maxInputChars else {
            errorMessage = "Слишком длинный текст: максимум \(Self.maxInputChars) символов за раз, сейчас \(text.count). Разбейте на части."
            return
        }
        translationTask?.cancel()
        translationTask = Task { await performTranslation(text) }
    }

    /// Автоперевод с задержкой после набора текста.
    func scheduleAutoTranslate() {
        guard settings?.autoTranslate ?? true else { return }
        autoTranslateTask?.cancel()
        autoTranslateTask = Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            translate()
        }
    }

    func copyResult() {
        guard !outputText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
    }

    func requestLanguageDownload() {
        errorMessage = nil
        onDownloadRequest?()
    }

    func dismissOfflineUpdateNotice() {
        offlineUpdateMessage = nil
        offlineUpdateCodes = []
    }

    func requestOpenSettings() {
        onOpenSettings?()
    }

    func requestOpenHistory() {
        onOpenHistory?()
    }

    func swapLanguages() {
        if sourceCode == "auto" {
            let newSource = targetCode
            targetCode = lastDetectedSource.flatMap { AppLanguage.by(google: $0)?.googleCode }
                ?? (targetCode == "ru" ? "en" : "ru")
            sourceCode = newSource
        } else {
            swap(&sourceCode, &targetCode)
        }
        if sourceCode == targetCode {
            targetCode = sourceCode == "ru" ? "en" : "ru"
        }
    }

    // MARK: - Озвучка

    func speakOutput() {
        speak(outputText, googleCode: lastTargetCode ?? targetCode)
    }

    func speakInput() {
        let code: String
        if sourceCode != "auto" {
            code = sourceCode
        } else if let detected = lastDetectedSource, AppLanguage.by(google: detected) != nil {
            code = detected
        } else {
            code = TranslationService.hasCyrillic(inputText) ? "ru" : "en"
        }
        speak(inputText, googleCode: code)
    }

    private func speak(_ text: String, googleCode: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if speech.isSpeaking {
            speech.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: trimmed)
        if let language = AppLanguage.by(google: googleCode),
           let voice = AVSpeechSynthesisVoice(language: language.speechCode) {
            utterance.voice = voice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        speech.speak(utterance)
    }

    // MARK: - История

    func clearHistory() {
        history = []
        Self.saveHistory(history)
    }

    private func recordHistory(input: String, output: String, source: String?, target: String, engine: String) {
        let sourceName: String
        if let source, let lang = AppLanguage.by(google: source) {
            sourceName = lang.nameRu
        } else if let detected = lastDetectedSource, let lang = AppLanguage.by(google: detected) {
            sourceName = "Авто (\(lang.nameRu))"
        } else {
            sourceName = "Авто"
        }
        let targetName = AppLanguage.by(google: target)?.nameRu ?? target
        let entry = HistoryEntry(
            date: Date(),
            pair: "\(sourceName) → \(targetName)",
            engine: engine,
            input: input,
            output: output
        )
        history.insert(entry, at: 0)
        if history.count > Self.historyLimit {
            history = Array(history.prefix(Self.historyLimit))
        }
        Self.saveHistory(history)
    }

    private static func loadHistory() -> [HistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: "history"),
              let entries = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else { return [] }
        return entries
    }

    private static func saveHistory(_ entries: [HistoryEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "history")
        }
    }

    // MARK: - Основная логика: Google → Apple

    /// Определяет исходный (nil = авто) и целевой языки с «умной» парой ru/en:
    /// если язык не выбран, текст кириллический, а цель — русский,
    /// переводим на английский.
    private func resolvedPair(for text: String) -> (source: String?, target: String) {
        var target = targetCode
        let source: String? = sourceCode == "auto" ? nil : sourceCode
        if source == nil, target == "ru", TranslationService.hasCyrillic(text) {
            target = "en"
        }
        return (source, target)
    }

    private func performTranslation(_ text: String) async {
        isTranslating = true
        errorMessage = nil
        notice = nil
        defer { isTranslating = false }

        let (source, target) = resolvedPair(for: text)

        if settings?.offlineOnly ?? false {
            notice = "Режим только офлайн: текст не отправляется в интернет."
        } else {
            do {
                let result = try await google.translate(text, from: source ?? "auto", to: target)
                guard !Task.isCancelled else { return }
                lastDetectedSource = result.detectedSource
                lastTargetCode = target
                outputText = result.text
                engineUsed = "Google · онлайн"
                recordHistory(input: text, output: result.text, source: source, target: target, engine: engineUsed)
                return
            } catch {
                guard !Task.isCancelled else { return }
            }
        }

        // Онлайн отключён или не сработал — пробуем офлайн-движок Apple.
        do {
            let result = try await translateWithApple(text, source: source, target: target)
            guard !Task.isCancelled else { return }
            lastTargetCode = target
            outputText = result
            engineUsed = "Apple · офлайн"
            if text.count > Self.offlineHeavyThreshold {
                notice = "Офлайн-перевод длинных текстов работает медленнее и нагружает процессор."
            }
            recordHistory(input: text, output: result, source: source, target: target, engine: engineUsed)
        } catch {
            guard !Task.isCancelled else { return }
            if settings?.offlineOnly ?? false, !offlineReady {
                errorMessage = "Включён режим только офлайн, но языки для этой пары не скачаны. Откройте «Офлайн-языки…» и подготовьте нужные языки."
            } else if offlineReady {
                errorMessage = "Не удалось перевести: \(error.localizedDescription)"
            } else {
                errorMessage = "Нет интернета, а офлайн-языки для этой пары не скачаны. Нажмите «Офлайн-языки…» внизу."
            }
        }
    }

    // MARK: - Движок Apple Translation

    private func translateWithApple(_ text: String, source: String?, target: String) async throws -> String {
        appleContinuation?.resume(throwing: AppleError.timeout)
        appleContinuation = nil
        appleTimeoutTask?.cancel()

        pendingAppleText = text
        return try await withCheckedThrowingContinuation { continuation in
            appleContinuation = continuation
            pokeAppleConfig(source: source, target: target)

            appleTimeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self, !Task.isCancelled else { return }
                self.appleContinuation?.resume(throwing: AppleError.timeout)
                self.appleContinuation = nil
                self.pendingAppleText = nil
            }
        }
    }

    /// Обновляет конфигурацию так, чтобы .translationTask сработал заново.
    private func pokeAppleConfig(source: String?, target: String) {
        let sourceLang = source.flatMap { AppLanguage.by(google: $0)?.appleLanguage }
        let targetLang = AppLanguage.by(google: target)?.appleLanguage
            ?? Locale.Language(identifier: target)
        if var config = appleConfig, config.source == sourceLang, config.target == targetLang {
            config.invalidate()
            appleConfig = config
        } else {
            appleConfig = TranslationSession.Configuration(source: sourceLang, target: targetLang)
        }
    }

    /// Вызывается из view, когда система выдала TranslationSession.
    func runAppleSession(_ session: TranslationSession) async {
        guard let text = pendingAppleText, let continuation = appleContinuation else { return }
        pendingAppleText = nil
        appleContinuation = nil
        appleTimeoutTask?.cancel()

        do {
            let response = try await session.translate(text)
            continuation.resume(returning: response.targetText)
        } catch {
            continuation.resume(throwing: error)
        }
    }

    // MARK: - Статусы офлайн-языков

    func refreshAppleStatus(recordSnapshot: Bool = false, checkForUpdates: Bool = false) async {
        let availability = LanguageAvailability()
        let english = Locale.Language(identifier: "en")
        var statuses: [String: OfflineState] = [:]
        for language in AppLanguage.all where language.googleCode != "en" {
            let status = await availability.status(from: language.appleLanguage, to: english)
            switch status {
            case .installed: statuses[language.googleCode] = .installed
            case .supported: statuses[language.googleCode] = .supported
            case .unsupported: statuses[language.googleCode] = .unsupported
            @unknown default: statuses[language.googleCode] = .unsupported
            }
        }
        appleStatuses = statuses
        if checkForUpdates {
            detectOfflineUpdates(from: statuses)
        } else if recordSnapshot {
            saveInstalledOfflineLanguages(from: statuses)
        }
        updateOfflineFooter()
    }

    func schedulePeriodicOfflineUpdateCheck() {
        guard shouldCheckOfflineUpdates() else { return }
        offlineUpdateCheckTask?.cancel()
        offlineUpdateCheckTask = Task { [weak self] in
            await self?.refreshAppleStatus(checkForUpdates: true)
        }
    }

    /// Пара доступна офлайн, если оба языка скачаны (английский встроен как опора).
    func isOfflinePairReady(_ first: String, _ second: String) -> Bool {
        func ready(_ code: String) -> Bool {
            code == "en" || appleStatuses[code] == .installed
        }
        return ready(first) && ready(second)
    }

    func updateOfflineFooter() {
        let source = sourceCode == "auto"
            ? (targetCode == "ru" ? "en" : "ru")
            : sourceCode
        let ready = isOfflinePairReady(source, targetCode)
        offlineReady = ready
        let sourceName = AppLanguage.by(google: source)?.nameRu ?? source
        let targetName = AppLanguage.by(google: targetCode)?.nameRu ?? targetCode
        offlineStatusText = ready
            ? "Офлайн \(sourceName) ↔ \(targetName): готов"
            : "Офлайн \(sourceName) ↔ \(targetName): не скачан"
    }

    private func shouldCheckOfflineUpdates(now: Date = Date()) -> Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: "offlineUpdateLastCheck") as? Date else {
            return true
        }
        return now.timeIntervalSince(lastCheck) >= Self.offlineUpdateCheckInterval
    }

    private func detectOfflineUpdates(from statuses: [String: OfflineState]) {
        let defaults = UserDefaults.standard
        let previouslyInstalled = Set(defaults.stringArray(forKey: "offlineInstalledLanguageCodes") ?? [])

        defaults.set(Date(), forKey: "offlineUpdateLastCheck")
        saveInstalledOfflineLanguages(from: statuses)

        let changed = previouslyInstalled.filter { statuses[$0] == .supported }
        guard !changed.isEmpty else { return }

        offlineUpdateCodes = Array(changed).sorted()
        updateOfflineUpdateMessage()
    }

    private func saveInstalledOfflineLanguages(from statuses: [String: OfflineState]) {
        let installed = statuses.compactMap { code, state in
            state == .installed ? code : nil
        }
        UserDefaults.standard.set(installed.sorted(), forKey: "offlineInstalledLanguageCodes")

        guard !offlineUpdateCodes.isEmpty else { return }
        offlineUpdateCodes = offlineUpdateCodes.filter { !installed.contains($0) }
        updateOfflineUpdateMessage()
    }

    private func updateOfflineUpdateMessage() {
        guard !offlineUpdateCodes.isEmpty else {
            offlineUpdateMessage = nil
            return
        }
        let names = offlineUpdateCodes
            .compactMap { AppLanguage.by(google: $0)?.nameRu }
            .joined(separator: ", ")
        offlineUpdateMessage = "Для офлайн-языков доступна подготовка обновления: \(names)."
    }
}
