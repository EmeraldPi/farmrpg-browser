import AppKit

class ControlStripView: NSView, NSTextFieldDelegate {
    private var targetWindow: MainWindow?
    private weak var webViewController: WebViewController?
    private var opacitySlider: NSSlider!
    private var zoomSlider: NSSlider!
    private var zoomLabel: NSTextField!
    private var alwaysOnTopButton: NSButton!
    private var toggleButton: NSButton!
    private var stripContainer: NSView!
    private var flowLayout: FlowLayoutView!
    private var stripHeightConstraint: NSLayoutConstraint!
    private(set) var isExpanded = false

    init(window: MainWindow, webViewController: WebViewController) {
        self.targetWindow = window
        self.webViewController = webViewController
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Create the titlebar accessory with the toggle button
    func makeTitlebarAccessory() -> NSTitlebarAccessoryViewController {
        toggleButton = NSButton(frame: .zero)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.bezelStyle = .inline
        toggleButton.title = "▼ Controls"
        toggleButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        toggleButton.target = self
        toggleButton.action = #selector(toggleStrip)

        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 28))
        accessoryView.addSubview(toggleButton)
        NSLayoutConstraint.activate([
            toggleButton.centerYAnchor.constraint(equalTo: accessoryView.centerYAnchor),
            toggleButton.leadingAnchor.constraint(equalTo: accessoryView.leadingAnchor, constant: 4),
        ])

        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = accessoryView
        accessory.layoutAttribute = .trailing
        return accessory
    }

    private func setupViews() {
        // Container for the control strip (hidden by default)
        stripContainer = NSView(frame: .zero)
        stripContainer.translatesAutoresizingMaskIntoConstraints = false
        stripContainer.wantsLayer = true
        stripContainer.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor
        stripContainer.isHidden = true
        addSubview(stripContainer)

        // --- Build control groups as compact views ---

        // Always on top toggle
        alwaysOnTopButton = NSButton(checkboxWithTitle: "Always on Top", target: self, action: #selector(toggleAlwaysOnTop))
        alwaysOnTopButton.font = NSFont.systemFont(ofSize: 11)
        alwaysOnTopButton.state = targetWindow?.isAlwaysOnTop == true ? .on : .off

        // Opacity group
        let opacityLabel = NSTextField(labelWithString: "Opacity:")
        opacityLabel.font = NSFont.systemFont(ofSize: 11)
        opacitySlider = NSSlider(value: Double(targetWindow?.alphaValue ?? 1.0), minValue: 0.3, maxValue: 1.0, target: self, action: #selector(opacityChanged(_:)))
        opacitySlider.isContinuous = true
        opacitySlider.widthAnchor.constraint(equalToConstant: 80).isActive = true
        let opacityGroup = makeGroup([opacityLabel, opacitySlider])

        // Snap buttons
        let snapPositions: [(String, SnapPosition)] = [
            ("↖", .topLeft), ("↗", .topRight), ("↙", .bottomLeft), ("↘", .bottomRight), ("◎", .center)
        ]
        var snapButtons: [NSView] = []
        let snapLabel = NSTextField(labelWithString: "Snap:")
        snapLabel.font = NSFont.systemFont(ofSize: 11)
        snapButtons.append(snapLabel)
        for (title, position) in snapPositions {
            let btn = NSButton(frame: .zero)
            btn.bezelStyle = .inline
            btn.title = title
            btn.font = NSFont.systemFont(ofSize: 12)
            btn.target = self
            btn.tag = snapPositions.firstIndex(where: { $0.1 == position })!
            btn.action = #selector(snapAction(_:))
            btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
            snapButtons.append(btn)
        }
        let snapGroup = makeGroup(snapButtons)

        // Zoom group
        let zoomTitleLabel = NSTextField(labelWithString: "Zoom:")
        zoomTitleLabel.font = NSFont.systemFont(ofSize: 11)
        let initialZoom = Preferences.shared.zoomLevel
        zoomSlider = NSSlider(value: Double(initialZoom), minValue: 0.25, maxValue: 1.25, target: self, action: #selector(zoomChanged(_:)))
        zoomSlider.isContinuous = true
        zoomSlider.widthAnchor.constraint(equalToConstant: 80).isActive = true
        zoomLabel = NSTextField(string: "\(Int(initialZoom * 100))%")
        zoomLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        zoomLabel.alignment = .center
        zoomLabel.isEditable = true
        zoomLabel.isSelectable = true
        zoomLabel.isBordered = false
        zoomLabel.drawsBackground = false
        zoomLabel.focusRingType = .none
        zoomLabel.delegate = self
        zoomLabel.widthAnchor.constraint(equalToConstant: 48).isActive = true
        let zoomResetBtn = NSButton(frame: .zero)
        zoomResetBtn.bezelStyle = .inline
        zoomResetBtn.title = "Reset"
        zoomResetBtn.font = NSFont.systemFont(ofSize: 10)
        zoomResetBtn.target = self
        zoomResetBtn.action = #selector(zoomReset)
        let zoomGroup = makeGroup([zoomTitleLabel, zoomSlider, zoomLabel, zoomResetBtn])

        // Flow layout that wraps groups
        flowLayout = FlowLayoutView(items: [alwaysOnTopButton, opacityGroup, snapGroup, zoomGroup])
        flowLayout.translatesAutoresizingMaskIntoConstraints = false
        stripContainer.addSubview(flowLayout)

        NSLayoutConstraint.activate([
            stripContainer.topAnchor.constraint(equalTo: topAnchor),
            stripContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            stripContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            stripContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            flowLayout.topAnchor.constraint(equalTo: stripContainer.topAnchor, constant: 4),
            flowLayout.leadingAnchor.constraint(equalTo: stripContainer.leadingAnchor, constant: 8),
            flowLayout.trailingAnchor.constraint(equalTo: stripContainer.trailingAnchor, constant: -8),
            flowLayout.bottomAnchor.constraint(equalTo: stripContainer.bottomAnchor, constant: -4),
        ])

        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func makeGroup(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.alignment = .centerY
        return stack
    }

    var totalHeight: CGFloat {
        if !isExpanded { return 0 }
        // Ask the flow layout for its needed height
        let width = stripContainer.bounds.width > 0 ? stripContainer.bounds.width - 16 : 320
        return flowLayout.heightForWidth(width) + 8
    }

    @objc private func toggleStrip() {
        isExpanded.toggle()
        stripContainer.isHidden = !isExpanded
        toggleButton.title = isExpanded ? "▲ Controls" : "▼ Controls"

        updateHeight()
    }

    func updateHeight() {
        // Find the height constraint set by AppDelegate
        if let hc = constraints.first(where: { $0.firstAttribute == .height && $0.firstItem === self }) {
            hc.constant = totalHeight
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            self.targetWindow?.layoutIfNeeded()
            self.superview?.layoutSubtreeIfNeeded()
        }
    }

    override func layout() {
        super.layout()
        // Recalculate height when width changes (e.g. window resize)
        if isExpanded {
            if let hc = constraints.first(where: { $0.firstAttribute == .height && $0.firstItem === self }) {
                let newHeight = totalHeight
                if abs(hc.constant - newHeight) > 1 {
                    hc.constant = newHeight
                }
            }
        }
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

    // NSTextFieldDelegate — user typed a zoom percentage
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let text = fieldEditor.string.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "%", with: "")
        if let percent = Double(text) {
            let value = CGFloat(max(25, min(125, percent))) / 100.0
            webViewController?.zoomLevel = value
            zoomSlider.doubleValue = Double(value)
            zoomLabel.stringValue = "\(Int(value * 100))%"
            Preferences.shared.zoomLevel = value
            Preferences.shared.save()
        }
        return true
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

// MARK: - FlowLayoutView

/// A view that lays out its items horizontally, wrapping to new rows when needed.
/// Each row is centered horizontally.
class FlowLayoutView: NSView {
    private let items: [NSView]
    private let itemSpacing: CGFloat = 12
    private let rowSpacing: CGFloat = 6

    init(items: [NSView]) {
        self.items = items
        super.init(frame: .zero)
        for item in items {
            item.translatesAutoresizingMaskIntoConstraints = false
            addSubview(item)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func heightForWidth(_ width: CGFloat) -> CGFloat {
        let rows = computeRows(forWidth: width)
        var totalHeight: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.fittingSize.height }.max() ?? 0
            totalHeight += rowHeight
        }
        totalHeight += CGFloat(max(0, rows.count - 1)) * rowSpacing
        return max(totalHeight, 24)
    }

    private func computeRows(forWidth width: CGFloat) -> [[NSView]] {
        var rows: [[NSView]] = [[]]
        var currentRowWidth: CGFloat = 0

        for item in items {
            let itemWidth = item.fittingSize.width
            if !rows[rows.count - 1].isEmpty && currentRowWidth + itemSpacing + itemWidth > width {
                rows.append([])
                currentRowWidth = 0
            }
            if currentRowWidth > 0 {
                currentRowWidth += itemSpacing
            }
            rows[rows.count - 1].append(item)
            currentRowWidth += itemWidth
        }
        return rows
    }

    override func layout() {
        super.layout()
        let availableWidth = bounds.width
        let rows = computeRows(forWidth: availableWidth)

        var y: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.fittingSize.height }.max() ?? 0
            // Calculate total row width for centering
            var totalRowWidth: CGFloat = 0
            for (i, item) in row.enumerated() {
                totalRowWidth += item.fittingSize.width
                if i > 0 { totalRowWidth += itemSpacing }
            }
            var x = max(0, (availableWidth - totalRowWidth) / 2)

            for item in row {
                let size = item.fittingSize
                item.frame = NSRect(
                    x: x,
                    y: y + (rowHeight - size.height) / 2,
                    width: size.width,
                    height: size.height
                )
                x += size.width + itemSpacing
            }
            y += rowHeight + rowSpacing
        }
    }

    override var intrinsicContentSize: NSSize {
        let w = bounds.width > 0 ? bounds.width : 320
        return NSSize(width: NSView.noIntrinsicMetric, height: heightForWidth(w))
    }
}
