import AppKit
import Carbon.HIToolbox

/// Получение выделенного текста из любой программы: имитируем ⌘C,
/// забираем текст из буфера обмена и возвращаем буферу прежнее содержимое.
/// Требует разрешения «Универсальный доступ» (Accessibility).
enum SelectionGrabber {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Показывает системный запрос на выдачу разрешения.
    static func promptForPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @MainActor
    static func grabSelectedText() async -> String? {
        let pasteboard = NSPasteboard.general
        let previousText = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount

        // Ждём, пока пользователь отпустит клавиши сочетания (до 1,5 с):
        // если послать ⌘C при зажатых ⌃⌥, программа-получатель увидит
        // «⌘⌃⌥C» и ничего не скопирует.
        for _ in 0..<30 {
            let held = CGEventSource.flagsState(.combinedSessionState)
            if held.intersection([.maskControl, .maskAlternate, .maskShift]).isEmpty {
                break
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        DebugLog.write("grab: модификаторы отпущены, посылаю ⌘C")

        postCommandC()

        // Ждём, пока целевая программа положит выделенное в буфер (до 1 с).
        var copied = false
        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            if pasteboard.changeCount != previousChangeCount {
                copied = true
                break
            }
        }
        DebugLog.write("grab: буфер изменился = \(copied)")
        guard copied else { return nil }

        let selectedText = pasteboard.string(forType: .string)
        DebugLog.write("grab: длина полученного текста = \(selectedText?.count ?? -1)")

        // Возвращаем прежнее содержимое буфера, чтобы ⌘V пользователя не сломался.
        if let previousText {
            pasteboard.clearContents()
            pasteboard.setString(previousText, forType: .string)
        }
        return selectedText
    }

    private static func postCommandC() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        // Ровно ⌘C — зажатые пользователем модификаторы сочетания не попадут в событие.
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
