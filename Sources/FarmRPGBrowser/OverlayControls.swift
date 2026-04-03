import AppKit

class OverlayControls: NSObject {
    weak var window: MainWindow?
    weak var webViewController: WebViewController?
    private var opacitySlider: NSSlider!
    private var alwaysOnTopItem: NSMenuItem!

    init(window: MainWindow, webViewController: WebViewController) {
        self.window = window
        self.webViewController = webViewController
        super.init()
    }

    func createMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "About FarmRPG Browser", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit FarmRPG Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        // Navigate menu
        let navMenuItem = NSMenuItem()
        mainMenu.addItem(navMenuItem)
        let navMenu = NSMenu(title: "Navigate")
        navMenuItem.submenu = navMenu

        let backItem = NSMenuItem(title: "Back", action: #selector(goBack), keyEquivalent: "[")
        backItem.keyEquivalentModifierMask = .command
        backItem.target = self
        navMenu.addItem(backItem)

        let forwardItem = NSMenuItem(title: "Forward", action: #selector(goForward), keyEquivalent: "]")
        forwardItem.keyEquivalentModifierMask = .command
        forwardItem.target = self
        navMenu.addItem(forwardItem)

        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        reloadItem.target = self
        navMenu.addItem(reloadItem)

        navMenu.addItem(.separator())

        let homeItem = NSMenuItem(title: "Go to Farm", action: #selector(goHome), keyEquivalent: "h")
        homeItem.keyEquivalentModifierMask = .command
        homeItem.target = self
        navMenu.addItem(homeItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu

        // Always on top toggle
        alwaysOnTopItem = NSMenuItem(title: "Always on Top", action: #selector(toggleAlwaysOnTop), keyEquivalent: "t")
        alwaysOnTopItem.keyEquivalentModifierMask = .command
        alwaysOnTopItem.target = self
        alwaysOnTopItem.state = window?.isAlwaysOnTop == true ? .on : .off
        viewMenu.addItem(alwaysOnTopItem)

        viewMenu.addItem(.separator())

        // Opacity label
        let opacityLabel = NSMenuItem(title: "Opacity:", action: nil, keyEquivalent: "")
        opacityLabel.isEnabled = false
        viewMenu.addItem(opacityLabel)

        // Opacity slider as a menu item
        opacitySlider = NSSlider(value: Double(window?.alphaValue ?? 1.0), minValue: 0.3, maxValue: 1.0, target: self, action: #selector(opacityChanged(_:)))
        opacitySlider.frame = NSRect(x: 20, y: 0, width: 180, height: 24)
        opacitySlider.isContinuous = true

        let sliderView = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 30))
        sliderView.addSubview(opacitySlider)
        opacitySlider.frame = NSRect(x: 20, y: 3, width: 180, height: 24)

        let sliderItem = NSMenuItem()
        sliderItem.view = sliderView
        viewMenu.addItem(sliderItem)

        viewMenu.addItem(.separator())

        // Snap to corners submenu
        let snapMenu = NSMenu(title: "Snap to Corner")

        let snapTL = NSMenuItem(title: "Top Left", action: #selector(snapTopLeft), keyEquivalent: "1")
        snapTL.keyEquivalentModifierMask = .command
        snapTL.target = self
        snapMenu.addItem(snapTL)

        let snapTR = NSMenuItem(title: "Top Right", action: #selector(snapTopRight), keyEquivalent: "2")
        snapTR.keyEquivalentModifierMask = .command
        snapTR.target = self
        snapMenu.addItem(snapTR)

        let snapBL = NSMenuItem(title: "Bottom Left", action: #selector(snapBottomLeft), keyEquivalent: "3")
        snapBL.keyEquivalentModifierMask = .command
        snapBL.target = self
        snapMenu.addItem(snapBL)

        let snapBR = NSMenuItem(title: "Bottom Right", action: #selector(snapBottomRight), keyEquivalent: "4")
        snapBR.keyEquivalentModifierMask = .command
        snapBR.target = self
        snapMenu.addItem(snapBR)

        let snapCenter = NSMenuItem(title: "Center", action: #selector(snapCenterScreen), keyEquivalent: "5")
        snapCenter.keyEquivalentModifierMask = .command
        snapCenter.target = self
        snapMenu.addItem(snapCenter)

        let snapItem = NSMenuItem(title: "Snap to Corner", action: nil, keyEquivalent: "")
        snapItem.submenu = snapMenu
        viewMenu.addItem(snapItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")

        return mainMenu
    }

    // MARK: - Actions

    @objc func toggleAlwaysOnTop() {
        window?.toggleAlwaysOnTop()
        alwaysOnTopItem.state = window?.isAlwaysOnTop == true ? .on : .off
        Preferences.shared.alwaysOnTop = window?.isAlwaysOnTop ?? false
        Preferences.shared.save()
    }

    @objc func opacityChanged(_ sender: NSSlider) {
        let value = CGFloat(sender.doubleValue)
        window?.setOpacity(value)
        Preferences.shared.opacity = value
        Preferences.shared.save()
    }

    @objc func reloadPage() {
        webViewController?.reload()
    }

    @objc func goBack() {
        webViewController?.goBack()
    }

    @objc func goForward() {
        webViewController?.goForward()
    }

    @objc func goHome() {
        webViewController?.loadFarmRPG()
    }

    // MARK: - Snap Actions

    @objc func snapTopLeft() {
        guard let window = window else { return }
        WindowSnapper.snap(window: window, to: .topLeft)
    }

    @objc func snapTopRight() {
        guard let window = window else { return }
        WindowSnapper.snap(window: window, to: .topRight)
    }

    @objc func snapBottomLeft() {
        guard let window = window else { return }
        WindowSnapper.snap(window: window, to: .bottomLeft)
    }

    @objc func snapBottomRight() {
        guard let window = window else { return }
        WindowSnapper.snap(window: window, to: .bottomRight)
    }

    @objc func snapCenterScreen() {
        guard let window = window else { return }
        WindowSnapper.snap(window: window, to: .center)
    }
}
