import AppKit
import SwiftUI
import Translation

// MARK: - Где на экране выделенный текст

/// Координаты выделенного текста — чтобы показать облако прямо над ним.
enum SelectionLocator {
    /// Точный способ: спросить координаты выделения у самой программы
    /// через Универсальный доступ. Работает не везде — тогда возвращает nil.
    @MainActor
    static func selectionRect() -> NSRect? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef
        ) == .success, let focusedRef, CFGetTypeID(focusedRef) == AXUIElementGetTypeID()
        else { return nil }
        let element = focusedRef as! AXUIElement

        var rangeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element, kAXSelectedTextRangeAttribute as CFString, &rangeRef
        ) == .success, let rangeRef, CFGetTypeID(rangeRef) == AXValueGetTypeID()
        else { return nil }

        var boundsRef: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeRef as! AXValue,
            &boundsRef
        ) == .success, let boundsRef, CFGetTypeID(boundsRef) == AXValueGetTypeID()
        else { return nil }

        var rect = CGRect.zero
        guard AXValueGetValue(boundsRef as! AXValue, .cgRect, &rect),
              rect.width > 0, rect.height > 0
        else { return nil }

        // Универсальный доступ считает координаты от левого ВЕРХНЕГО угла
        // главного экрана, AppKit — от левого НИЖНЕГО. Переворачиваем.
        guard let mainScreen = NSScreen.screens.first else { return nil }
        let flippedY = mainScreen.frame.maxY - rect.maxY
        return NSRect(x: rect.minX, y: flippedY, width: rect.width, height: rect.height)
    }

    /// Запасной способ: точка у курсора мыши —
    /// пользователь только что выделял текст именно там.
    @MainActor
    static func mouseRect() -> NSRect {
        let point = NSEvent.mouseLocation
        return NSRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)
    }
}

// MARK: - Панель-облако

/// Маленькое всплывающее облако с переводом над выделенным текстом.
/// Поведение (Esc, клик мимо, перетаскивание) наследуется от FloatingPanel,
/// отличается только позиционирование.
final class BubblePanel: FloatingPanel {
    /// Показывает облако над прямоугольником выделения;
    /// если сверху не хватает места — под ним.
    func show(near anchor: NSRect) {
        layoutIfNeeded()
        let screen = NSScreen.screens.first { $0.frame.intersects(anchor) } ?? NSScreen.main

        var origin = NSPoint(
            x: anchor.midX - frame.width / 2,
            y: anchor.maxY + 10
        )
        if let visible = screen?.visibleFrame {
            if origin.y + frame.height > visible.maxY {
                origin.y = anchor.minY - frame.height - 10 // сверху не влезло — показываем снизу
            }
            origin.x = max(visible.minX + 12, min(origin.x, visible.maxX - frame.width - 12))
            origin.y = max(visible.minY + 12, origin.y)
        }
        setFrameOrigin(origin)
        makeKeyAndOrderFront(nil)
    }
}

// MARK: - Содержимое облака

struct BubbleView: View {
    @ObservedObject var model: TranslatorModel
    var onReplace: () -> Void
    var onExpand: () -> Void
    @AppStorage("appTheme") private var appTheme = AppTheme.frostGlass.rawValue
    @State private var justCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
            footer
        }
        .padding(14)
        .frame(width: 330)
        .themedPanel(cornerRadius: 16)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
        .id(appTheme)
        // Своя точка входа для офлайн-движка Apple: большая панель может быть
        // скрыта, а .translationTask работает только на видимом view.
        .translationTask(model.appleConfig) { session in
            await model.runAppleSession(session)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error = model.errorMessage {
            Text(error)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(Theme.roseInk)
                .fixedSize(horizontal: false, vertical: true)
        } else if model.outputText.isEmpty {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.sage)
                Text("Перевожу…")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
        } else {
            Text(model.outputText)
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink)
                .textSelection(.enabled)
                .lineLimit(12)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button("Заменить") { onReplace() }
                .buttonStyle(PillButtonStyle())
                .disabled(model.outputText.isEmpty)
                .help("Вставить перевод вместо выделенного текста (сработает только там, где текст можно редактировать)")
            Button {
                model.speakOutput()
            } label: {
                Image(systemName: "speaker.wave.2")
            }
            .buttonStyle(IconCircleButtonStyle(fill: Theme.sky, size: 24))
            .disabled(model.outputText.isEmpty)
            .help("Озвучить перевод")
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
            .buttonStyle(IconCircleButtonStyle(size: 24))
            .disabled(model.outputText.isEmpty)
            .help("Копировать перевод")
            Spacer()
            if !model.engineUsed.isEmpty, model.errorMessage == nil, !model.outputText.isEmpty {
                Text(model.engineUsed)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.sage)
            }
            Button {
                onExpand()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.45))
            }
            .buttonStyle(.plain)
            .help("Открыть в большой панели")
        }
    }
}
