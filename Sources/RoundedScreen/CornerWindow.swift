import AppKit

/// Draws one dark corner: a square minus a quarter circle.
final class CornerView: NSView {
    let corner: ScreenCorner
    var style: CornerStyle { didSet { needsDisplay = true } }

    init(corner: ScreenCorner, style: CornerStyle) {
        self.corner = corner
        self.style = style
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }

    // Never capture clicks or hovers.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        let r = style.radius
        let c = corner.arcCenter(radius: r)

        let path = NSBezierPath(rect: bounds)
        path.append(NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)))
        path.windingRule = .evenOdd

        style.color.setFill()
        path.fill()
    }
}

/// A small borderless window per corner. The key is `ignoresMouseEvents = true`:
/// the pointer, clicks, hovers and hot corners all pass through it.
final class CornerWindow: NSWindow {
    let corner: ScreenCorner

    init(corner: ScreenCorner, screen: NSScreen, style: CornerStyle) {
        self.corner = corner
        let size = max(style.radius, 1)
        let frame = corner.frame(in: screen.frame, size: size)
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false

        ignoresMouseEvents = true          // the mouse is never blocked
        level = .screenSaver               // above the menu bar and Dock
        collectionBehavior = [
            .canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary
        ]

        contentView = CornerView(corner: corner, style: style)
    }

    /// Applies a new style in place (used while the slider moves).
    func apply(style: CornerStyle, screen: NSScreen) {
        guard style.radius >= 1 else {
            orderOut(nil)
            return
        }
        (contentView as? CornerView)?.style = style
        setFrame(corner.frame(in: screen.frame, size: style.radius), display: true)
        orderFrontRegardless()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
