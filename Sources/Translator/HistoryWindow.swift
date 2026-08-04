import SwiftUI

/// Окно истории: последние переводы (хранится максимум 10).
struct HistoryView: View {
    @ObservedObject var model: TranslatorModel
    @AppStorage("appTheme") private var appTheme = AppTheme.calmGlass.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                LogoMark(size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.t("history"))
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(L10n.format("history.subtitle", TranslatorModel.historyLimit))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.5))
                }
                Spacer()
                if !model.history.isEmpty {
                    Button(L10n.t("clear")) { model.clearHistory() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.roseInk)
                }
            }

            if model.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.ink.opacity(0.25))
                    Text(L10n.t("history.empty"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.5))
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(model.history) { entry in
                            historyCard(entry)
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
        }
        .padding(18)
        .frame(width: 440)
        .themedPanel(cornerRadius: 0)
        .id(appTheme)
    }

    private func historyCard(_ entry: HistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.date.formatted(date: .numeric, time: .shortened))
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.4))
                Spacer()
                Text("\(entry.pair) · \(entry.engine)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.sage)
            }
            Text(entry.input)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .lineLimit(2)
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                Text(entry.output)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.ink)
                    .textSelection(.enabled)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.output, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(IconCircleButtonStyle(size: 24))
                .help(L10n.t("copy.translation"))
            }
        }
        .padding(12)
        .themedSurface(cornerRadius: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
    }
}
