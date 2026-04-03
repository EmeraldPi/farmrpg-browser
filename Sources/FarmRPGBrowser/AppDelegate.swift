import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var mainWindow: MainWindow!
    var webViewController: WebViewController!
    var hotkeyManager: HotkeyManager!
    var overlayControls: OverlayControls!
    var controlStrip: ControlStripView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        // Restore preferences
        Preferences.shared.load()

        // Create the web view controller
        webViewController = WebViewController()

        // Create the main window
        let prefs = Preferences.shared
        let frame = prefs.windowFrame ?? NSRect(x: 0, y: 0, width: 480, height: 720)
        mainWindow = MainWindow(contentRect: frame)

        // Apply saved preferences
        mainWindow.setAlwaysOnTop(prefs.alwaysOnTop)
        mainWindow.setOpacity(prefs.opacity)

        // Build content: control strip on top, web view below
        controlStrip = ControlStripView(window: mainWindow, webViewController: webViewController)

        // Add toggle button to the titlebar (next to traffic lights)
        let titlebarAccessory = controlStrip.makeTitlebarAccessory()
        mainWindow.addTitlebarAccessoryViewController(titlebarAccessory)

        // Accessing .view triggers loadView(), so webView exists after this
        let webView = webViewController.view
        webViewController.zoomLevel = prefs.zoomLevel
        webView.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: frame)
        container.addSubview(controlStrip)
        container.addSubview(webView)

        // fullSizeContentView pushes content under titlebar; offset below it
        let titlebarHeight: CGFloat = 28

        let stripHeightConstraint = controlStrip.heightAnchor.constraint(equalToConstant: controlStrip.totalHeight)
        NSLayoutConstraint.activate([
            controlStrip.topAnchor.constraint(equalTo: container.topAnchor, constant: titlebarHeight),
            controlStrip.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            controlStrip.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stripHeightConstraint,

            webView.topAnchor.constraint(equalTo: controlStrip.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        mainWindow.contentView = container

        mainWindow.delegate = self

        // Center window if no saved frame
        if prefs.windowFrame == nil {
            mainWindow.center()
        }

        // Set up menu bar (keeps keyboard shortcuts working)
        overlayControls = OverlayControls(window: mainWindow, webViewController: webViewController)
        NSApp.mainMenu = overlayControls.createMainMenu()

        // Set up global hotkey
        hotkeyManager = HotkeyManager(window: mainWindow)
        hotkeyManager.register()

        // Show and activate
        mainWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save window state
        let prefs = Preferences.shared
        prefs.windowFrame = mainWindow.frame
        prefs.alwaysOnTop = mainWindow.level == .floating
        prefs.save()

        hotkeyManager.unregister()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ application: NSApplication) -> Bool {
        // Return false so the app stays alive when the window is hidden via hotkey
        return false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - NSWindowDelegate

    // Quit when the user clicks the red close button
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}
