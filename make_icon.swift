// Генератор иконки приложения: рисует её кодом и собирает AppIcon.icns.
// Запуск: swift make_icon.swift
import AppKit

// MARK: - Палитра (Mindora)

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

let sageLight = rgb(0x74A092)
let sageDeep = rgb(0x46705F)
let mist = rgb(0xF1F5F4)
let rose = rgb(0xE8AEB7)
let ink = rgb(0x2F3E46)

func roundedFont(size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .bold)
    if let descriptor = base.fontDescriptor.withDesign(.rounded),
       let font = NSFont(descriptor: descriptor, size: size) {
        return font
    }
    return base
}

func drawText(_ text: String, center: NSPoint, font: NSFont, color: NSColor) {
    let attributed = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    let size = attributed.size()
    attributed.draw(at: NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2))
}

// MARK: - Рисунок (координаты в сетке 1024×1024, ось Y вверх)

func drawIcon(canvas: CGFloat) {
    let s = canvas / 1024.0

    // Фон — скруглённый квадрат с вертикальным градиентом
    let margin = 100 * s
    let bgRect = NSRect(x: margin, y: margin, width: canvas - 2 * margin, height: canvas - 2 * margin)
    let bg = NSBezierPath(roundedRect: bgRect, xRadius: 186 * s, yRadius: 186 * s)
    NSGradient(colors: [sageLight, sageDeep])?.draw(in: bg, angle: -90)

    // Большой белый пузырь с «А»
    let bigBubble = NSBezierPath(
        roundedRect: NSRect(x: 225 * s, y: 460 * s, width: 400 * s, height: 270 * s),
        xRadius: 90 * s, yRadius: 90 * s
    )
    mist.setFill()
    bigBubble.fill()
    let bigTail = NSBezierPath()
    bigTail.move(to: NSPoint(x: 305 * s, y: 470 * s))
    bigTail.line(to: NSPoint(x: 258 * s, y: 352 * s))
    bigTail.line(to: NSPoint(x: 405 * s, y: 462 * s))
    bigTail.close()
    bigTail.fill()
    drawText("А", center: NSPoint(x: 425 * s, y: 600 * s), font: roundedFont(size: 185 * s), color: sageDeep)

    // Малый розовый пузырь с «a» (ответная реплика)
    let smallBubble = NSBezierPath(
        roundedRect: NSRect(x: 565 * s, y: 295 * s, width: 250 * s, height: 190 * s),
        xRadius: 64 * s, yRadius: 64 * s
    )
    rose.setFill()
    smallBubble.fill()
    let smallTail = NSBezierPath()
    smallTail.move(to: NSPoint(x: 700 * s, y: 476 * s))
    smallTail.line(to: NSPoint(x: 742 * s, y: 540 * s))
    smallTail.line(to: NSPoint(x: 628 * s, y: 480 * s))
    smallTail.close()
    smallTail.fill()
    drawText("a", center: NSPoint(x: 690 * s, y: 390 * s), font: roundedFont(size: 140 * s), color: ink)
}

// MARK: - Рендер PNG и сборка .icns

func renderPNG(pixels: Int, to url: URL) throws {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Не удалось создать контекст \(pixels)px")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    drawIcon(canvas: CGFloat(pixels))
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Не удалось получить PNG \(pixels)px")
    }
    try data.write(to: url)
}

let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = projectDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for variant in variants {
    try renderPNG(pixels: variant.pixels, to: iconset.appendingPathComponent(variant.name))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", projectDir.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "✓ AppIcon.icns готов" : "✗ iconutil завершился с ошибкой \(iconutil.terminationStatus)")
