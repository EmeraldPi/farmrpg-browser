import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: MainWindow!
    var webViewController: WebViewController!
    var hotkeyManager: HotkeyManager!
    var overlayControls: OverlayControls!

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
        mainWindow.contentViewController = webViewController

        // Apply saved preferences
        mainWindow.setAlwaysOnTop(prefs.alwaysOnTop)
        mainWindow.setOpacity(prefs.opacity)

        // Center window if no saved frame
        if prefs.windowFrame == nil {
            mainWindow.center()
        }

        // Set up menu bar
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
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
