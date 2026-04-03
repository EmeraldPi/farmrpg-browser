import AppKit

class MainWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.title = "FarmRPG"
        self.minSize = NSSize(width: 320, height: 480)
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
    }

    // MARK: - Always on Top

    func setAlwaysOnTop(_ enabled: Bool) {
        self.level = enabled ? .floating : .normal
    }

    var isAlwaysOnTop: Bool {
        return self.level == .floating
    }

    func toggleAlwaysOnTop() {
        setAlwaysOnTop(!isAlwaysOnTop)
    }

    // MARK: - Opacity

    func setOpacity(_ value: CGFloat) {
        // Clamp between 0.3 and 1.0 to prevent invisible window
        self.alphaValue = max(0.3, min(1.0, value))
    }
}
