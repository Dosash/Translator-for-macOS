import SwiftUI
import Translation

struct TranslatorView: View {
    @ObservedObject var model: TranslatorModel
    @AppStorage("appTheme") private var appTheme = AppTheme.calmGlass.rawValue
    @AppStorage("panelSizeMode") private var panelSizeMode = PanelSizeMode.standard.rawValue
    @AppStorage("offlineOnly") private var offlineOnly = false
    @AppStorage("appLanguage") private var appLanguage = AppUILanguage.system.rawValue
    @State private var justCopied = false

    private var panelMode: PanelSizeMode {
        PanelSizeMode.stored(panelSizeMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            languageRow
            inputCard
            actionRow
            resultCard

            if let notice = model.notice {
                Text(notice)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.sage)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Theme.roseInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.rose.opacity(0.28)))
            }

            if let message = model.offlineUpdateMessage {
                offlineUpdateBanner(message)
            }

            footer
        }
        .padding(16)
        .frame(width: panelMode.panelWidth)
        .themedPanel(cornerRadius: 18)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
        .id("\(appTheme)-\(appLanguage)")
        .translationTask(model.appleConfig) { session in
            await model.runAppleSession(session)
        }
        .onChange(of: model.inputText) {
            model.scheduleAutoTranslate()
        }
        .onChange(of: model.sourceCode) {
            model.updateOfflineFooter()
            model.translate()
        }
        .onChange(of: model.targetCode) {
            model.updateOfflineFooter()
            model.translate()
        }
        .onChange(of: offlineOnly) {
            model.updateOfflineFooter()
            model.translate()
        }
        .task {
            await model.refreshAppleStatus()
            model.schedulePeriodicOfflineUpdateCheck()
        }
    }

    // MARK: - Блоки интерфейса

    private var header: some View {
        HStack(spacing: 10) {
            LogoMark(size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.t("app.title"))
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(L10n.t("app.subtitle"))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
            Spacer()
            Label(model.enginePrivacyText, systemImage: model.engineUsed.contains("Google") ? "network" : "lock.shield")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.sage)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(Theme.controlFill))
                .overlay(Capsule().stroke(Theme.controlStroke, lineWidth: 1))
                .help(model.enginePrivacyText)
        }
    }

    private var languageRow: some View {
        HStack(spacing: 8) {
            languageMenu(
                title: sourceTitle,
                options: [(code: "auto", title: L10n.t("auto"))] + AppLanguage.all.map { (code: $0.googleCode, title: L10n.languageName($0.googleCode)) },
                selection: $model.sourceCode
            )

            Button {
                model.swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(IconCircleButtonStyle(size: 24))
            .help(L10n.t("swap.languages"))

            languageMenu(
                title: targetTitle,
                options: AppLanguage.all.map { (code: $0.googleCode, title: L10n.languageName($0.googleCode)) },
                selection: $model.targetCode
            )
        }
    }

    private var sourceTitle: String {
        if model.sourceCode == "auto" {
            return L10n.t("auto")
        }
        return AppLanguage.by(google: model.sourceCode).map { L10n.languageName($0.googleCode) } ?? model.sourceCode
    }

    private var targetTitle: String {
        AppLanguage.by(google: model.targetCode).map { L10n.languageName($0.googleCode) } ?? model.targetCode
    }

    private func languageMenu(
        title: String,
        options: [(code: String, title: String)],
        selection: Binding<String>
    ) -> some View {
        Menu {
            ForEach(options, id: \.code) { option in
                Button {
                    selection.wrappedValue = option.code
                } label: {
                    if selection.wrappedValue == option.code {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.controlFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.controlStroke, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .tint(Theme.sage)
        .environment(\.colorScheme, Theme.isDark ? .dark : .light)
        .frame(maxWidth: .infinity)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 3) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.inputText)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(height: panelMode.textAreaHeight)
                    .padding(6)
                    .themedSurface(cornerRadius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.cardStroke, lineWidth: 1)
                    )
                if model.inputText.isEmpty {
                    Text(L10n.t("input.placeholder"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.4))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            HStack {
                Spacer()
                Text("\(model.inputText.count) / \(TranslatorModel.maxInputChars)")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(
                        model.inputText.count > TranslatorModel.maxInputChars
                            ? Theme.roseInk
                            : Theme.ink.opacity(model.inputText.count > TranslatorModel.maxInputChars * 9 / 10 ? 0.8 : 0.4)
                    )
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(L10n.t("translate")) { model.translate() }
                .buttonStyle(PillButtonStyle())
                .keyboardShortcut(.return, modifiers: .command)
            if model.isTranslating {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.sage)
            }
            Spacer()
            Button {
                model.speakInput()
            } label: {
                Image(systemName: "speaker.wave.2")
            }
            .buttonStyle(IconCircleButtonStyle(fill: Theme.sky, size: 26))
            .disabled(model.inputText.isEmpty)
            .help(L10n.t("speak.source"))
            Button {
                model.inputText = ""
                model.outputText = ""
                model.errorMessage = nil
                model.notice = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(IconCircleButtonStyle(fill: Theme.rose, size: 26))
            .help(L10n.t("clear"))
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                Text(model.outputText.isEmpty ? L10n.t("result.placeholder") : model.outputText)
                    .font(.system(size: 13))
                    .foregroundStyle(model.outputText.isEmpty ? Theme.ink.opacity(0.4) : Theme.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: panelMode.resultHeight)

            HStack(spacing: 8) {
                Spacer()
                Button {
                    model.speakOutput()
                } label: {
                    Image(systemName: "speaker.wave.2")
                }
                .buttonStyle(IconCircleButtonStyle(fill: Theme.sky, size: 28))
                .disabled(model.outputText.isEmpty)
                .help(L10n.t("speak.translation"))
                Button {
                    model.copyResult()
                    withAnimation { justCopied = true }
                    Task {
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        withAnimation { justCopied = false }
                    }
                } label: {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(IconCircleButtonStyle(size: 28))
                .disabled(model.outputText.isEmpty)
                .help(L10n.t("copy.translation"))
            }
        }
        .padding(10)
        .themedSurface(cornerRadius: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(model.offlineReady ? Theme.sage : Theme.rose)
                .frame(width: 7, height: 7)
            Text(model.offlineStatusText)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.55))
                .lineLimit(1)
            Button(L10n.t("offline.languages")) { model.requestLanguageDownload() }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sage)
            Spacer()
            Button {
                model.requestOpenHistory()
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.45))
            }
            .buttonStyle(.plain)
            .help(L10n.t("history"))
            Button {
                model.requestOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.45))
            }
            .buttonStyle(.plain)
            .help(L10n.t("settings"))
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.45))
            }
            .buttonStyle(.plain)
            .help(L10n.t("quit"))
        }
    }

    private func offlineUpdateBanner(_ message: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.sage)
            Text(message)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.68))
                .lineLimit(2)
            Spacer()
            Button(L10n.t("offline.languages")) { model.requestLanguageDownload() }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.sage)
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
