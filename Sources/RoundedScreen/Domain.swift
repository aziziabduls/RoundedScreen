import AppKit
import Combine

// MARK: - Domain

/// The four corners of a screen.
enum ScreenCorner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight

    /// Frame of the small (size x size) window that covers this corner.
    func frame(in screenFrame: NSRect, size: CGFloat) -> NSRect {
        switch self {
        case .bottomLeft:
            return NSRect(x: screenFrame.minX, y: screenFrame.minY, width: size, height: size)
        case .bottomRight:
            return NSRect(x: screenFrame.maxX - size, y: screenFrame.minY, width: size, height: size)
        case .topLeft:
            return NSRect(x: screenFrame.minX, y: screenFrame.maxY - size, width: size, height: size)
        case .topRight:
            return NSRect(x: screenFrame.maxX - size, y: screenFrame.maxY - size, width: size, height: size)
        }
    }

    /// Center of the circle (in the view's local coordinates) that forms the curve.
    func arcCenter(radius r: CGFloat) -> NSPoint {
        switch self {
        case .topLeft:     return NSPoint(x: r, y: 0)
        case .topRight:    return NSPoint(x: 0, y: 0)
        case .bottomLeft:  return NSPoint(x: r, y: r)
        case .bottomRight: return NSPoint(x: 0, y: r)
        }
    }
}

/// How the corners look: how round, and the mask color.
struct CornerStyle: Equatable {
    var radius: CGFloat
    var color: NSColor = .black
}

/// App settings, persisted in UserDefaults.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    static let radiusRange: ClosedRange<Double> = 0...64
    static let radiusPresets: [Int] = [0, 8, 12, 16, 24, 32, 48]

    private let defaults = UserDefaults.standard

    /// Corner radius in points. 0 turns the overlay off.
    @Published var radius: Double {
        didSet { defaults.set(radius, forKey: "radius") }
    }

    /// When true, closing the settings window keeps the app (and the corners) running.
    @Published var runInBackground: Bool {
        didSet { defaults.set(runInBackground, forKey: "runInBackground") }
    }

    /// When true, the app starts hidden at login.
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            LoginItem.apply(enabled: launchAtLogin)
        }
    }

    /// When true, the menu bar icon is visible.
    @Published var showInMenuBar: Bool {
        didSet { defaults.set(showInMenuBar, forKey: "showInMenuBar") }
    }

    private init() {
        radius = defaults.object(forKey: "radius") as? Double ?? 16
        runInBackground = defaults.object(forKey: "runInBackground") as? Bool ?? true
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        showInMenuBar = defaults.object(forKey: "showInMenuBar") as? Bool ?? true
    }
}

/// Login item implemented as a LaunchAgent, so it can pass `--background`
/// (start hidden, without opening the settings window).
enum LoginItem {
    private static let label = "com.example.roundedscreen"

    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static func apply(enabled: Bool) {
        let url = plistURL
        guard enabled else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        guard let exe = Bundle.main.executablePath else { return }

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [exe, "--background"],
            "RunAtLoad": true,
            "ProcessType": "Interactive",
        ]
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(
                fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
        } catch {
            NSSound.beep()
        }
    }
}
