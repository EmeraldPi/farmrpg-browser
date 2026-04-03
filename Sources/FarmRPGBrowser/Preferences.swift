import AppKit

class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let alwaysOnTop = "alwaysOnTop"
        static let opacity = "opacity"
        static let windowX = "windowX"
        static let windowY = "windowY"
        static let windowWidth = "windowWidth"
        static let windowHeight = "windowHeight"
        static let hasStoredFrame = "hasStoredFrame"
    }

    var alwaysOnTop: Bool = false
    var opacity: CGFloat = 1.0
    var windowFrame: NSRect?

    private init() {}

    func load() {
        alwaysOnTop = defaults.bool(forKey: Keys.alwaysOnTop)

        let storedOpacity = defaults.double(forKey: Keys.opacity)
        opacity = storedOpacity > 0 ? CGFloat(storedOpacity) : 1.0

        if defaults.bool(forKey: Keys.hasStoredFrame) {
            let x = defaults.double(forKey: Keys.windowX)
            let y = defaults.double(forKey: Keys.windowY)
            let w = defaults.double(forKey: Keys.windowWidth)
            let h = defaults.double(forKey: Keys.windowHeight)
            if w > 0 && h > 0 {
                windowFrame = NSRect(x: x, y: y, width: w, height: h)
            }
        }
    }

    func save() {
        defaults.set(alwaysOnTop, forKey: Keys.alwaysOnTop)
        defaults.set(Double(opacity), forKey: Keys.opacity)

        if let frame = windowFrame {
            defaults.set(true, forKey: Keys.hasStoredFrame)
            defaults.set(Double(frame.origin.x), forKey: Keys.windowX)
            defaults.set(Double(frame.origin.y), forKey: Keys.windowY)
            defaults.set(Double(frame.size.width), forKey: Keys.windowWidth)
            defaults.set(Double(frame.size.height), forKey: Keys.windowHeight)
        }
    }
}
