import AppKit
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case calmGlass
    case neonGlass
    case frostGlass

    var id: String { rawValue }

    static func stored(_ rawValue: String?) -> AppTheme {
        switch rawValue {
        case calmGlass.rawValue:
            return .calmGlass
        case neonGlass.rawValue, "liquidGlass":
            return .neonGlass
        case frostGlass.rawValue, "mindora":
            return .frostGlass
        default:
            return .calmGlass
        }
    }

    var nameRu: String {
        switch self {
        case .calmGlass: return "Calm Glass"
        case .neonGlass: return "Neon Glass"
        case .frostGlass: return "Frost Glass"
        }
    }

    var caption: String {
        switch self {
        case .calmGlass: return "мягкое белое стекло с зелёным акцентом"
        case .neonGlass: return "тёмное стекло с неоновым свечением"
        case .frostGlass: return "светлое матовое стекло"
        }
    }
}

/// Палитра приложения в стеклянных UI-вариантах.
enum Theme {
    static var current: AppTheme {
        AppTheme.stored(UserDefaults.standard.string(forKey: "appTheme"))
    }

    static var usesLiquidGlass: Bool {
        true
    }

    static var isDark: Bool {
        current == .neonGlass
    }

    static var systemAccent: Color {
        Color(nsColor: NSColor.controlAccentColor)
    }

    static var usesFixedAccent: Bool {
        current == .calmGlass
    }

    static var sage: Color {
        usesFixedAccent ? Color(hex: 0x28A97A) : systemAccent
    }

    static var sageDeep: Color {
        usesFixedAccent ? Color(hex: 0x1E8D66) : systemAccent
    }

    static var sky: Color {
        if current == .calmGlass {
            return Color(hex: 0x7FA8DD)
        }
        return systemAccent.opacity(isDark ? 0.88 : 0.78)
    }

    static var ink: Color {
        if current == .calmGlass {
            return Color(hex: 0x1E2A32)
        }
        return isDark ? Color(hex: 0xF5FBFF) : Color(hex: 0x111827)
    }

    static var mist: Color {
        if current == .calmGlass {
            return Color(hex: 0xEFF7F4)
        }
        return isDark ? Color(hex: 0x07111E) : Color(hex: 0xEEF3F8)
    }

    static var mistDeep: Color {
        if current == .calmGlass {
            return Color(hex: 0xDDEBE6)
        }
        return isDark ? Color(hex: 0x130A24) : Color(hex: 0xD5DEE8)
    }

    static var rose: Color {
        if current == .calmGlass {
            return Color(hex: 0xE88B8B)
        }
        return isDark ? Color(hex: 0xFF58D2) : Color(hex: 0xFF80B6)
    }

    static var roseInk: Color {
        isDark ? Color(hex: 0xFFB4E8) : Color(hex: 0xB44463)
    }

    static var background: LinearGradient {
        LinearGradient(
            colors: current == .calmGlass
                ? [Color(hex: 0xF8FBFA), Color(hex: 0xEEF7F4), Color(hex: 0xEAF2F8)]
                : (isDark
                    ? [Color(hex: 0x06111D), Color(hex: 0x111A31), Color(hex: 0x210B2E)]
                    : [Color(hex: 0xF7FAFD), Color(hex: 0xE2E9F1), Color(hex: 0xCAD4DF)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardFill: Color {
        if current == .calmGlass {
            return Color.white.opacity(0.68)
        }
        return isDark ? Color.white.opacity(0.10) : Color.white.opacity(0.42)
    }

    static var cardStroke: Color {
        if current == .calmGlass {
            return Color.white.opacity(0.86)
        }
        return isDark ? Color.white.opacity(0.26) : Color.white.opacity(0.74)
    }

    static var glassTint: Color {
        if current == .calmGlass {
            return Color(hex: 0xEAF6F2).opacity(0.34)
        }
        return isDark ? systemAccent.opacity(0.16) : Color.white.opacity(0.24)
    }

    static var glow: Color {
        if current == .calmGlass {
            return Color(hex: 0x9BB9AE).opacity(0.22)
        }
        return isDark ? systemAccent.opacity(0.46) : Color.black.opacity(0.14)
    }

    static var secondaryGlow: Color {
        if current == .calmGlass {
            return Color(hex: 0x8FCAB9).opacity(0.34)
        }
        return isDark ? systemAccent.opacity(0.34) : Color.white.opacity(0.7)
    }

    static var controlFill: Color {
        if current == .calmGlass {
            return Color.white.opacity(0.78)
        }
        return isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.70)
    }

    static var selectedControlFill: Color {
        if current == .calmGlass {
            return Color(hex: 0xDDF2EA)
        }
        return isDark ? systemAccent.opacity(0.24) : systemAccent.opacity(0.14)
    }

    static var controlStroke: Color {
        if current == .calmGlass {
            return Color(hex: 0xDBE8E3).opacity(0.88)
        }
        return isDark ? Color.white.opacity(0.18) : Color.white.opacity(0.82)
    }

    static var secondaryText: Color {
        if current == .calmGlass {
            return Color(hex: 0x7A8790)
        }
        return isDark ? Color.white.opacity(0.64) : Color(hex: 0x5B6472)
    }
}

extension View {
    @ViewBuilder
    func themedPanel(cornerRadius: CGFloat) -> some View {
        if Theme.usesLiquidGlass, #available(macOS 26.0, *) {
            self
                .background(Theme.background)
                .glassEffect(.regular.tint(Theme.glassTint), in: .rect(cornerRadius: cornerRadius))
                .shadow(color: Theme.glow, radius: Theme.isDark ? 22 : 18, x: 0, y: 10)
                .environment(\.colorScheme, Theme.isDark ? .dark : .light)
                .tint(Theme.sage)
        } else {
            self
                .background(Theme.background)
                .shadow(color: Theme.glow, radius: Theme.isDark ? 22 : 18, x: 0, y: 10)
                .environment(\.colorScheme, Theme.isDark ? .dark : .light)
                .tint(Theme.sage)
        }
    }

    @ViewBuilder
    func themedSurface(cornerRadius: CGFloat) -> some View {
        if Theme.usesLiquidGlass, #available(macOS 26.0, *) {
            self.glassEffect(.regular.tint(Theme.glassTint).interactive(), in: .rect(cornerRadius: cornerRadius))
                .shadow(color: Theme.glow, radius: Theme.isDark ? 12 : 8, x: 0, y: 5)
                .environment(\.colorScheme, Theme.isDark ? .dark : .light)
                .tint(Theme.sage)
        } else if Theme.usesLiquidGlass {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: Theme.glow, radius: Theme.isDark ? 12 : 8, x: 0, y: 5)
                .environment(\.colorScheme, Theme.isDark ? .dark : .light)
                .tint(Theme.sage)
        } else {
            self.background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(Theme.cardFill))
        }
    }
}

/// Основная кнопка-«пилюля» (Primary из UI-кита):
/// зелёная, при нажатии — тёмная.
struct PillButtonStyle: ButtonStyle {
    var fill: Color = Theme.sage

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .background(Capsule().fill(configuration.isPressed ? Theme.ink : fill))
            .shadow(color: Theme.secondaryGlow, radius: Theme.isDark ? 10 : 4, x: 0, y: 3)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Круглая иконка-кнопка (Icon Button из UI-кита).
struct IconCircleButtonStyle: ButtonStyle {
    var fill: Color = Theme.sage
    var size: CGFloat = 30

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(configuration.isPressed ? Theme.ink : fill))
            .shadow(color: Theme.secondaryGlow, radius: Theme.isDark ? 8 : 3, x: 0, y: 2)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Фирменный логотип: зелёная плашка с пузырём перевода.
struct LogoMark: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
                .fill(LinearGradient(
                    colors: [Theme.sage, Theme.isDark ? Theme.rose : Theme.sky],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
                .shadow(color: Theme.secondaryGlow, radius: Theme.isDark ? 8 : 3, x: 0, y: 2)
            Image(nsImage: MenuBarIcon.make(color: .white, template: false, side: size * 0.62))
        }
    }
}

/// Чип-«таг» (как секция «Чипы» в UI-ките).
struct ChipToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? Theme.sage : Theme.controlFill)
                )
                .overlay(
                    Capsule().stroke(Theme.cardStroke, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
