import AppKit
import Combine

/// Settings window, plain AppKit (no SwiftUI) to keep memory low.
final class SettingsViewController: NSViewController {
    private let settings: AppSettings
    private var cancellables = Set<AnyCancellable>()

    private let contentWidth: CGFloat = 340
    private let padding: CGFloat = 28

    private let slider = NSSlider(value: 16,
                                  minValue: AppSettings.radiusRange.lowerBound,
                                  maxValue: AppSettings.radiusRange.upperBound,
                                  target: nil, action: nil)
    private let valueLabel = NSTextField(labelWithString: "")
    private var backgroundCheck: NSButton!
    private var loginCheck: NSButton!
    private var menuBarCheck: NSButton!

    init(settings: AppSettings) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: View

    override func loadView() {
        // Corner radius
        let title = NSTextField(labelWithString: "Corner radius")
        title.font = .boldSystemFont(ofSize: 13)
        valueLabel.textColor = .secondaryLabelColor

        let header = NSStackView(views: [title, valueLabel])
        header.distribution = .equalSpacing
        fixWidth(header)

        slider.target = self
        slider.action = #selector(sliderChanged)
        slider.isContinuous = true
        slider.doubleValue = settings.radius
        fixWidth(slider)

        let presets = NSStackView(views: AppSettings.radiusPresets.map { v -> NSButton in
            let b = NSButton(title: v == 0 ? "Off" : "\(v)", target: self, action: #selector(presetTapped(_:)))
            b.tag = v
            b.bezelStyle = .rounded
            return b
        })
        presets.spacing = 6

        let radiusSection = NSStackView(views: [header, slider, presets])
        radiusSection.orientation = .vertical
        radiusSection.alignment = .leading
        radiusSection.spacing = 10

        // Options
        backgroundCheck = NSButton(checkboxWithTitle: "Run in background",
                                   target: self, action: #selector(backgroundToggled))
        backgroundCheck.state = settings.runInBackground ? .on : .off

        loginCheck = NSButton(checkboxWithTitle: "Run at login",
                              target: self, action: #selector(loginToggled))
        loginCheck.state = settings.launchAtLogin ? .on : .off

        menuBarCheck = NSButton(checkboxWithTitle: "Show in menu bar",
                                target: self, action: #selector(menuBarToggled))
        menuBarCheck.state = settings.showInMenuBar ? .on : .off

        let quit = NSButton(title: "Quit Rounded Screen", target: NSApp,
                            action: #selector(NSApplication.terminate(_:)))
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        quit.setContentHuggingPriority(.required, for: .horizontal)
        let quitRow = NSStackView(views: [spacer, quit])
        fixWidth(quitRow)

        let stack = NSStackView(views: [
            radiusSection,
            rule(),
            option(backgroundCheck,
                   "Keep the corners active from the menu bar after this window is closed. If off, closing the window quits the app."),
            option(loginCheck,
                   "Start automatically when you log in, without opening this window."),
            option(menuBarCheck,
                   "Show the menu bar icon. If hidden, open the app again to bring this window back."),
            rule(),
            quitRow,
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Container with padding around the content.
        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),
        ])
        view = container

        container.layoutSubtreeIfNeeded()
        preferredContentSize = container.fittingSize
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Keep the window in sync when settings change elsewhere (e.g. the menu bar menu).
        settings.$radius
            .sink { [weak self] value in
                self?.slider.doubleValue = value
                self?.updateLabel(value)
            }
            .store(in: &cancellables)

        settings.$showInMenuBar
            .sink { [weak self] value in self?.menuBarCheck.state = value ? .on : .off }
            .store(in: &cancellables)
    }

    // MARK: Actions

    @objc private func sliderChanged() {
        settings.radius = slider.doubleValue.rounded()
    }

    @objc private func presetTapped(_ sender: NSButton) {
        settings.radius = Double(sender.tag)
    }

    @objc private func backgroundToggled() {
        settings.runInBackground = (backgroundCheck.state == .on)
    }

    @objc private func loginToggled() {
        settings.launchAtLogin = (loginCheck.state == .on)
    }

    @objc private func menuBarToggled() {
        settings.showInMenuBar = (menuBarCheck.state == .on)
    }

    // MARK: Helpers

    private func updateLabel(_ radius: Double) {
        valueLabel.stringValue = radius < 1 ? "Off" : "\(Int(radius)) px"
    }

    private func fixWidth(_ v: NSView) {
        v.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
    }

    private func rule() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        fixWidth(box)
        return box
    }

    /// A checkbox with a small description underneath.
    private func option(_ checkbox: NSButton, _ description: String) -> NSStackView {
        let label = NSTextField(wrappingLabelWithString: description)
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        label.preferredMaxLayoutWidth = contentWidth
        fixWidth(label)

        let stack = NSStackView(views: [checkbox, label])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }
}
