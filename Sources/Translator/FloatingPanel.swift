import AppKit

/// Безрамочная панель вместо NSPopover: открывается с отступом под строкой
/// меню (а не вплотную к ней), имеет скруглённые углы и закрывается
/// по клику мимо или по Esc. Наследник BubblePanel переиспользует это
/// поведение для облака над выделенным текстом.
class FloatingPanel: NSPanel {
    /// Момент последнего скрытия — чтобы клик по иконке в меню-баре,
    /// который сам закрыл панель через resignKey, не открывал её заново.
    private(set) var lastHideTime: Date?

    init(contentViewController: NSViewController) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.contentViewController = contentViewController
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }

    /// Пока открыто другое окно приложения (например, настройки), панель
    /// не прячется при потере фокуса и опускается на обычный уровень,
    /// чтобы это окно было поверх неё, а панель оставалась видна позади.
    var keepsVisibleBehindOtherWindows = false {
        didSet {
            level = keepsVisibleBehindOtherWindows ? .normal : .floating
        }
    }

    override func resignKey() {
        super.resignKey()
        if !keepsVisibleBehindOtherWindows {
            hide()
        }
    }

    override func cancelOperation(_ sender: Any?) {
        hide()
    }

    func hide() {
        guard isVisible else { return }
        lastHideTime = Date()
        orderOut(nil)
    }

    /// Панель хочет открыться повторно сразу после того, как клик по иконке
    /// уже закрыл её — такой «повторный» показ надо пропустить.
    var justHidByOutsideClick: Bool {
        guard let lastHideTime else { return false }
        return Date().timeIntervalSince(lastHideTime) < 0.25
    }

    func show(under button: NSStatusBarButton) {
        layoutIfNeeded()
        guard let buttonWindow = button.window else { return }
        let buttonFrame = buttonWindow.frame
        let screen = buttonWindow.screen ?? NSScreen.main

        // По центру под иконкой, с отступом 10 pt от строки меню.
        var origin = NSPoint(
            x: buttonFrame.midX - frame.width / 2,
            y: buttonFrame.minY - frame.height - 10
        )
        if let visible = screen?.visibleFrame {
            origin.x = max(visible.minX + 12, min(origin.x, visible.maxX - frame.width - 12))
            origin.y = max(visible.minY + 12, origin.y)
        }
        setFrameOrigin(origin)
        makeKeyAndOrderFront(nil)
    }
}
