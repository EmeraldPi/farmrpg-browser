import AppKit

class ControlStripView: NSView {
    private var targetWindow: MainWindow?
    private weak var webViewController: WebViewController?
    private var opacitySlider: NSSlider!
    private var zoomSlider: NSSlider!
    private var zoomLabel: NSTextField!
    private var alwaysOnTopButton: NSButton!
    private var toggleButton: NSButton!
    private var stripContainer: NSView!
    private var isExpanded = false

    private let stripHeight: CGFloat = 72

    init(window: MainWindow, webViewController: WebViewController) {
        self.targetWindow = window
        self.webViewController = webViewController
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Toggle button — sits in the titlebar area
        toggleButton = NSButton(frame: .zero)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.bezelStyle = .inline
        toggleButton.title = "Controls ▼"
        toggleButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        toggleButton.target = self
        toggleButton.action = #selector(toggleStrip)
        addSubview(toggleButton)

        // Container for the control strip
        stripContainer = NSView(frame: .zero)
        stripContainer.translatesAutoresizingMaskIntoConstraints = false
        stripContainer.wantsLayer = true
        stripContainer.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor
        stripContainer.isHidden = true
        addSubview(stripContainer)

        // --- Controls inside the strip ---

        // Always on top toggle
        alwaysOnTopButton = NSButton(checkboxWithTitle: "Always on Top", target: self, action: #selector(toggleAlwaysOnTop))
        alwaysOnTopButton.translatesAutoresizingMaskIntoConstraints = false
        alwaysOnTopButton.font = NSFont.systemFont(ofSize: 11)
        alwaysOnTopButton.state = targetWindow?.isAlwaysOnTop == true ? .on : .off
        stripContainer.addSubview(alwaysOnTopButton)

        // Opacity label
        let opacityLabel = NSTextField(labelWithString: "Opacity:")
        opacityLabel.translatesAutoresizingMaskIntoConstraints = false
        opacityLabel.font = NSFont.systemFont(ofSize: 11)
        stripContainer.addSubview(opacityLabel)

        // Opacity slider
        opacitySlider = NSSlider(value: Double(targetWindow?.alphaValue ?? 1.0), minValue: 0.3, maxValue: 1.0, target: self, action: #selector(opacityChanged(_:)))
        opacitySlider.translatesAutoresizingMaskIntoConstraints = false
        opacitySlider.isContinuous = true
        stripContainer.addSubview(opacitySlider)

        // Snap buttons
        let snapStack = NSStackView()
        snapStack.translatesAutoresizingMaskIntoConstraints = false
        snapStack.orientation = .horizontal
        snapStack.spacing = 2

        let snapPositions: [(String, SnapPosition)] = [
            ("↖", .topLeft), ("↗", .topRight), ("↙", .bottomLeft), ("↘", .bottomRight), ("◎", .center)
        ]
        for (title, position) in snapPositions {
            let btn = NSButton(frame: .zero)
            btn.bezelStyle = .inline
            btn.title = title
            btn.font = NSFont.systemFont(ofSize: 12)
            btn.target = self
            btn.tag = snapPositions.firstIndex(where: { $0.1 == position })!
            btn.action = #selector(snapAction(_:))
            btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
            snapStack.addArrangedSubview(btn)
        }
        stripContainer.addSubview(snapStack)

        // --- Row 2: Zoom ---
        let zoomTitleLabel = NSTextField(labelWithString: "Zoom:")
        zoomTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomTitleLabel.font = NSFont.systemFont(ofSize: 11)
        stripContainer.addSubview(zoomTitleLabel)

        let initialZoom = Preferences.shared.zoomLevel
        zoomSlider = NSSlider(value: Double(initialZoom), minValue: 0.25, maxValue: 3.0, target: self, action: #selector(zoomChanged(_:)))
        zoomSlider.translatesAutoresizingMaskIntoConstraints = false
        zoomSlider.isContinuous = true
        stripContainer.addSubview(zoomSlider)

        zoomLabel = NSTextField(labelWithString: "\(Int(initialZoom * 100))%")
        zoomLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        zoomLabel.alignment = .right
        stripContainer.addSubview(zoomLabel)

        let zoomResetBtn = NSButton(frame: .zero)
        zoomResetBtn.bezelStyle = .inline
        zoomResetBtn.title = "Reset"
        zoomResetBtn.font = NSFont.systemFont(ofSize: 10)
        zoomResetBtn.translatesAutoresizingMaskIntoConstraints = false
        zoomResetBtn.target = self
        zoomResetBtn.action = #selector(zoomReset)
        stripContainer.addSubview(zoomResetBtn)

        let rowHeight: CGFloat = 36
        // Layout
        NSLayoutConstraint.activate([
            // Toggle button at top, centered
            toggleButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            toggleButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            toggleButton.heightAnchor.constraint(equalToConstant: 18),

            // Strip container below toggle
            stripContainer.topAnchor.constraint(equalTo: toggleButton.bottomAnchor, constant: 2),
            stripContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            stripContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            stripContainer.heightAnchor.constraint(equalToConstant: stripHeight),

            // Row 1: Always on top, opacity, snap (centered in top half)
            alwaysOnTopButton.leadingAnchor.constraint(equalTo: stripContainer.leadingAnchor, constant: 8),
            alwaysOnTopButton.centerYAnchor.constraint(equalTo: stripContainer.topAnchor, constant: rowHeight / 2),

            opacityLabel.leadingAnchor.constraint(equalTo: alwaysOnTopButton.trailingAnchor, constant: 12),
            opacityLabel.centerYAnchor.constraint(equalTo: alwaysOnTopButton.centerYAnchor),

            opacitySlider.leadingAnchor.constraint(equalTo: opacityLabel.trailingAnchor, constant: 4),
            opacitySlider.centerYAnchor.constraint(equalTo: alwaysOnTopButton.centerYAnchor),
            opacitySlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            snapStack.leadingAnchor.constraint(equalTo: opacitySlider.trailingAnchor, constant: 12),
            snapStack.trailingAnchor.constraint(lessThanOrEqualTo: stripContainer.trailingAnchor, constant: -8),
            snapStack.centerYAnchor.constraint(equalTo: alwaysOnTopButton.centerYAnchor),

            // Row 2: Zoom (centered in bottom half)
            zoomTitleLabel.leadingAnchor.constraint(equalTo: stripContainer.leadingAnchor, constant: 8),
            zoomTitleLabel.centerYAnchor.constraint(equalTo: stripContainer.topAnchor, constant: rowHeight + rowHeight / 2),

            zoomSlider.leadingAnchor.constraint(equalTo: zoomTitleLabel.trailingAnchor, constant: 4),
            zoomSlider.centerYAnchor.constraint(equalTo: zoomTitleLabel.centerYAnchor),
            zoomSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),

            zoomLabel.leadingAnchor.constraint(equalTo: zoomSlider.trailingAnchor, constant: 6),
            zoomLabel.centerYAnchor.constraint(equalTo: zoomTitleLabel.centerYAnchor),
            zoomLabel.widthAnchor.constraint(equalToConstant: 40),

            zoomResetBtn.leadingAnchor.constraint(equalTo: zoomLabel.trailingAnchor, constant: 6),
            zoomResetBtn.centerYAnchor.constraint(equalTo: zoomTitleLabel.centerYAnchor),
        ])

        self.translatesAutoresizingMaskIntoConstraints = false
    }

    var totalHeight: CGFloat {
        // Toggle button height + padding
        let base: CGFloat = 24
        return isExpanded ? base + 2 + stripHeight : base
    }

    @objc private func toggleStrip() {
        isExpanded.toggle()
        stripContainer.isHidden = !isExpanded
        toggleButton.title = isExpanded ? "Controls ▲" : "Controls ▼"

        // Update height constraint
        heightConstraint?.constant = totalHeight

        // Animate
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            self.targetWindow?.layoutIfNeeded()
            self.superview?.layoutSubtreeIfNeeded()
        }
    }

    private var heightConstraint: NSLayoutConstraint? {
        return constraints.first(where: { $0.firstAttribute == .height && $0.firstItem === self })
    }

    @objc private func toggleAlwaysOnTop() {
        targetWindow?.toggleAlwaysOnTop()
        alwaysOnTopButton.state = targetWindow?.isAlwaysOnTop == true ? .on : .off
        Preferences.shared.alwaysOnTop = targetWindow?.isAlwaysOnTop ?? false
        Preferences.shared.save()
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        let value = CGFloat(sender.doubleValue)
        targetWindow?.setOpacity(value)
        Preferences.shared.opacity = value
        Preferences.shared.save()
    }

    @objc private func zoomChanged(_ sender: NSSlider) {
        let value = CGFloat(sender.doubleValue)
        webViewController?.zoomLevel = value
        zoomLabel.stringValue = "\(Int(value * 100))%"
        Preferences.shared.zoomLevel = value
        Preferences.shared.save()
    }

    @objc private func zoomReset() {
        webViewController?.resetZoom()
        zoomSlider.doubleValue = 1.0
        zoomLabel.stringValue = "100%"
        Preferences.shared.zoomLevel = 1.0
        Preferences.shared.save()
    }

    @objc private func snapAction(_ sender: NSButton) {
        guard let win = targetWindow else { return }
        let positions: [SnapPosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight, .center]
        WindowSnapper.snap(window: win, to: positions[sender.tag])
    }

    func syncState() {
        alwaysOnTopButton.state = targetWindow?.isAlwaysOnTop == true ? .on : .off
        opacitySlider.doubleValue = Double(targetWindow?.alphaValue ?? 1.0)
        let zoom = webViewController?.zoomLevel ?? 1.0
        zoomSlider.doubleValue = Double(zoom)
        zoomLabel.stringValue = "\(Int(zoom * 100))%"
    }
}
