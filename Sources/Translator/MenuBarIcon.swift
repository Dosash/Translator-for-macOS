import AppKit

/// Собственный значок: пузырь диалога с двумя стрелками перевода.
/// Рисуется кодом — никаких чужих символов и картинок.
enum MenuBarIcon {
    /// - Parameters:
    ///   - color: цвет заливки (для меню-бара — чёрный шаблон, для логотипа — белый).
    ///   - template: режим «шаблона» — меню-бар сам перекрашивает под светлую/тёмную тему.
    static func make(color: NSColor = .black, template: Bool = true, side: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in
            let s = side / 18.0 // все координаты в сетке 18×18

            color.setFill()

            // Пузырь диалога
            let bubble = NSBezierPath(
                roundedRect: NSRect(x: 1 * s, y: 4 * s, width: 16 * s, height: 12 * s),
                xRadius: 3.6 * s,
                yRadius: 3.6 * s
            )
            bubble.fill()

            // Хвостик пузыря
            let tail = NSBezierPath()
            tail.move(to: NSPoint(x: 4.2 * s, y: 5.5 * s))
            tail.line(to: NSPoint(x: 2.6 * s, y: 1.2 * s))
            tail.line(to: NSPoint(x: 7.8 * s, y: 4.4 * s))
            tail.close()
            tail.fill()

            // Стрелки «⇄» вырезаем из заливки
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            let arrows = NSBezierPath()

            // верхняя стрелка →
            arrows.appendRect(NSRect(x: 4.2 * s, y: 10.9 * s, width: 6.4 * s, height: 1.5 * s))
            arrows.move(to: NSPoint(x: 10.4 * s, y: 9.7 * s))
            arrows.line(to: NSPoint(x: 13.9 * s, y: 11.65 * s))
            arrows.line(to: NSPoint(x: 10.4 * s, y: 13.6 * s))
            arrows.close()

            // нижняя стрелка ←
            arrows.appendRect(NSRect(x: 7.4 * s, y: 6.6 * s, width: 6.4 * s, height: 1.5 * s))
            arrows.move(to: NSPoint(x: 7.6 * s, y: 5.05 * s))
            arrows.line(to: NSPoint(x: 4.1 * s, y: 7.35 * s))
            arrows.line(to: NSPoint(x: 7.6 * s, y: 9.3 * s))
            arrows.close()

            arrows.fill()
            return true
        }
        image.isTemplate = template
        return image
    }
}
