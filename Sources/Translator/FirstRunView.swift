import AppKit
import SwiftUI

struct FirstRunView: View {
    @ObservedObject var settings: SettingsStore
    @State private var axTrusted = SelectionGrabber.isTrusted

    let onOpenOfflineLanguages: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                LogoMark(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("first.title"))
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(L10n.t("first.subtitle"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }

            setupCard {
                statusRow(
                    icon: axTrusted ? "checkmark.shield.fill" : "shield.slash",
                    title: L10n.t("selected.text"),
                    caption: axTrusted ? L10n.t("access.granted") : L10n.t("access.needed"),
                    color: axTrusted ? Theme.sage : Theme.rose
                )
                if !axTrusted {
                    Button(L10n.t("grant.access")) {
                        SelectionGrabber.promptForPermission()
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        )
                    }
                    .buttonStyle(PillButtonStyle())
                }
                Divider()
                statusRow(
                    icon: "keyboard",
                    title: L10n.t("section.hotkeys"),
                    caption: "⌃⌥T — выделенный текст, ⌃⌥C — буфер обмена, ⇧⌘E — служба macOS",
                    color: Theme.sage
                )
                Divider()
                HStack(spacing: 12) {
                    statusRow(
                        icon: "arrow.down.circle.fill",
                        title: L10n.t("offline.languages"),
                        caption: L10n.t("offline.download.caption"),
                        color: Theme.sage
                    )
                    Button(L10n.t("open")) { onOpenOfflineLanguages() }
                        .buttonStyle(PillButtonStyle())
                }
            }

            setupCard {
                Text(L10n.t("section.theme"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            settings.appTheme = theme
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: settings.appTheme == theme ? "checkmark.circle.fill" : "circle")
                                Text(theme.nameRu)
                                    .lineLimit(1)
                            }
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(settings.appTheme == theme ? Theme.sage : Theme.ink)
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule().fill(settings.appTheme == theme ? Theme.selectedControlFill : Theme.controlFill)
                            )
                            .overlay(
                                Capsule().stroke(settings.appTheme == theme ? Theme.sage : Theme.controlStroke, lineWidth: settings.appTheme == theme ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Spacer()
                Button(L10n.t("done")) {
                    settings.completeFirstRun()
                    onDone()
                }
                .buttonStyle(PillButtonStyle())
            }
        }
        .padding(20)
        .frame(width: 460)
        .themedPanel(cornerRadius: 0)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            axTrusted = SelectionGrabber.isTrusted
        }
    }

    private func setupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .themedSurface(cornerRadius: 12)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.cardStroke, lineWidth: 1))
    }

    private func statusRow(icon: String, title: String, caption: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(caption)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
