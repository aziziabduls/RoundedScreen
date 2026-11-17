import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let settings = AppSettings.shared
    private var overlay: OverlayController!
    private var statusItem: NSStatusItem!
    private var window: NSWindow?          // created on demand, released when hidden
    private var cancellables = Set<AnyCancellable>()

    /// Set by the login item (`--background`).
    private var startHidden: Bool { CommandLine.arguments.contains("--background") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay = OverlayController(settings: settings)

        // Refresh the login item path in case the app was moved.
        if settings.launchAtLogin { LoginItem.apply(enabled: true) }

        setupStatusItem()

        if startHidden {
            NSApp.setActivationPolicy(.accessory)
        } else {
            showSettings()
        }
    }

    // MARK: Settings window

    private func makeWindow() -> NSWindow {
        let w = NSWindow(contentViewController: SettingsViewController(settings: settings))
        w.styleMask = [.titled, .closable, .miniaturizable]
        w.title = "Rounded Screen"
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.center()
        return w
    }

    @objc func showSettings() {
        NSApp.setActivationPolicy(.regular)        // show in the Dock while the window is open
        if window == nil { window = makeWindow() }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if settings.runInBackground {
            sender.orderOut(nil)
            NSApp.setActivationPolicy(.accessory)  // leave the Dock, stay in the menu bar
            sender.delegate = nil
            DispatchQueue.main.async { [weak self] in self?.window = nil }  // free the window's memory
            return false
        }
        NSApp.terminate(nil)
        return true
    }

    // Opening the app again (Finder, Spotlight, Dock) while it runs in the background.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: Menu bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.roundedtop",
                                           accessibilityDescription: "Rounded Screen")
        let menu = NSMenu()
        menu.delegate = self            // rebuilt every time it opens, so checkmarks are current
        statusItem.menu = menu

        settings.$showInMenuBar
            .sink { [weak self] show in self?.statusItem.isVisible = show }
            .store(in: &cancellables)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let open = NSMenuItem(title: "Open Settings…", action: #selector(showSettings), keyEquivalent: ",")
        open.target = self
        menu.addItem(open)

        // Corner radius submenu
        let radiusItem = NSMenuItem(title: "Corner Radius", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let current = Int(settings.radius.rounded())
        var matchesPreset = false
        for v in AppSettings.radiusPresets {
            let item = NSMenuItem(title: v == 0 ? "Off" : "\(v) px",
                                  action: #selector(pickRadius(_:)), keyEquivalent: "")
            item.target = self
            item.tag = v
            if v == current {
                item.state = .on
                matchesPreset = true
            }
            sub.addItem(item)
        }
        if !matchesPreset {
            sub.addItem(.separator())
            let custom = NSMenuItem(title: "Custom (\(current) px)", action: nil, keyEquivalent: "")
            custom.state = .on
            custom.isEnabled = false
            sub.addItem(custom)
        }
        radiusItem.submenu = sub
        menu.addItem(radiusItem)

        menu.addItem(.separator())

        let showIcon = NSMenuItem(title: "Show in Menu Bar", action: #selector(toggleMenuBarIcon), keyEquivalent: "")
        showIcon.target = self
        showIcon.state = settings.showInMenuBar ? .on : .off
        menu.addItem(showIcon)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Rounded Screen",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func pickRadius(_ sender: NSMenuItem) {
        settings.radius = Double(sender.tag)
    }

    @objc private func toggleMenuBarIcon() {
        settings.showInMenuBar.toggle()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
