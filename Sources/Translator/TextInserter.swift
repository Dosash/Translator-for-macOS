import AppKit
import Carbon.HIToolbox

/// Замена выделенного текста переводом: кладём перевод в буфер обмена,
/// имитируем ⌘V и возвращаем буферу прежнее содержимое.
/// Зеркальный близнец SelectionGrabber — требует того же разрешения
/// «Универсальный доступ».
enum TextInserter {
    @MainActor
    static func paste(_ text: String) async {
        let pasteboard = NSPasteboard.general
        let previousText = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Небольшая пауза: облако только что закрылось, фокус клавиатуры
        // должен вернуться в целевую программу.
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Ждём отпускания модификаторов (до 1,5 с): если послать ⌘V при
        // зажатых клавишах, целевая программа увидит другое сочетание.
        for _ in 0..<30 {
            let held = CGEventSource.flagsState(.combinedSessionState)
            if held.intersection([.maskControl, .maskAlternate, .maskShift, .maskCommand]).isEmpty {
                break
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        DebugLog.write("paste: посылаю ⌘V, длина текста = \(text.count)")

        postCommandV()

        // Даём целевой программе время забрать текст из буфера,
        // затем возвращаем прежнее содержимое, чтобы ⌘V пользователя не сломался.
        try? await Task.sleep(nanoseconds: 400_000_000)
        pasteboard.clearContents()
        if let previousText {
            pasteboard.setString(previousText, forType: .string)
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        // Ровно ⌘V — без модификаторов, случайно зажатых пользователем.
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
