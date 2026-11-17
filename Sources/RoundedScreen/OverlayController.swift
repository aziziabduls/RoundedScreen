import AppKit
import Combine

/// Manages the four corner windows of every screen.
final class OverlayController {
    private var items: [(window: CornerWindow, screen: NSScreen)] = []
    private var style = CornerStyle(radius: 16)
    private var cancellable: AnyCancellable?

    init(settings: AppSettings) {
        style.radius = CGFloat(settings.radius)

        // Radius changed -> update windows in place instead of recreating them.
        cancellable = settings.$radius.dropFirst().sink { [weak self] value in
            self?.style.radius = CGFloat(value)
            self?.applyAll()
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(rebuild),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        rebuild()
    }

    @objc private func rebuild() {
        items.forEach { $0.window.orderOut(nil) }
        items = NSScreen.screens.flatMap { screen in
            ScreenCorner.allCases.map {
                (CornerWindow(corner: $0, screen: screen, style: style), screen)
            }
        }
        applyAll()
    }

    private func applyAll() {
        items.forEach { $0.window.apply(style: style, screen: $0.screen) }
    }
}
