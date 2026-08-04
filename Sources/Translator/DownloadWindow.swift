import SwiftUI
import Translation

/// Отдельное окно управления офлайн-языками.
/// Скачивание нельзя запускать из панели: системный диалог корректно
/// прикрепляется только к обычному окну.
struct DownloadView: View {
    @ObservedObject var model: TranslatorModel
    var onClose: () -> Void

    @AppStorage("appTheme") private var appTheme = AppTheme.frostGlass.rawValue
    @State private var busyCode: String?
    @State private var config: TranslationSession.Configuration?
    @State private var message: String?
    @State private var messageIsError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                LogoMark(size: 30)
                Text(L10n.t("offline.languages"))
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            Text(L10n.t("offline.intro"))
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            if let updateMessage = model.offlineUpdateMessage {
                updateBanner(updateMessage)
            }

            VStack(spacing: 0) {
                ForEach(languages) { language in
                    languageRow(language)
                    if language.id != languages.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 4)
            .themedSurface(cornerRadius: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )

            if let message {
                Text(message)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(messageIsError ? Theme.roseInk : Theme.sage)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(L10n.t("offline.disk.note"))
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.45))
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button(L10n.t("close")) { onClose() }
                    .buttonStyle(PillButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 380)
        .themedPanel(cornerRadius: 0)
        .id(appTheme)
        .task {
            await model.refreshAppleStatus()
        }
        .translationTask(config) { session in
            do {
                try await session.prepareTranslation()
                message = "Готово — язык скачан."
                messageIsError = false
            } catch {
                message = "Не получилось скачать: \(error.localizedDescription)"
                messageIsError = true
            }
            busyCode = nil
            await model.refreshAppleStatus(recordSnapshot: true)
        }
    }

    private var languages: [AppLanguage] {
        AppLanguage.all
    }

    @ViewBuilder
    private func languageRow(_ language: AppLanguage) -> some View {
        if language.googleCode == "en" {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.sage)
                    .frame(width: 7, height: 7)
                Text(L10n.languageName(language.googleCode))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(L10n.t("base.language"))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.sage)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        } else {
            let state = model.appleStatuses[language.googleCode]
            HStack(spacing: 8) {
                Circle()
                    .fill(state == .installed ? Theme.sage : (state == .unsupported ? Theme.ink.opacity(0.25) : Theme.rose))
                    .frame(width: 7, height: 7)
                Text(L10n.languageName(language.googleCode))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if busyCode == language.googleCode {
                    ProgressView().controlSize(.small).tint(Theme.sage)
                } else {
                    switch state {
                    case .installed:
                        Text(L10n.t("downloaded"))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Theme.sage)
                    case .unsupported:
                        Text(L10n.t("unsupported"))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Theme.ink.opacity(0.4))
                    default:
                        Button(model.offlineUpdateCodes.contains(language.googleCode) ? L10n.t("update") : L10n.t("download")) {
                            startDownload(language)
                        }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.sage)
                            .disabled(busyCode != nil)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
    }

    private func startDownload(_ language: AppLanguage) {
        busyCode = language.googleCode
        messageIsError = false
        message = "Если появится системный запрос на скачивание — подтвердите его."
        config = TranslationSession.Configuration(
            source: language.appleLanguage,
            target: Locale.Language(identifier: "en")
        )
    }

    private func updateBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.sage)
            Text(message)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(L10n.t("later")) { model.dismissOfflineUpdateNotice() }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.45))
        }
        .padding(10)
        .themedSurface(cornerRadius: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }
}
