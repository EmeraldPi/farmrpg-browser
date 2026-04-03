import AppKit

enum SnapPosition: Equatable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
}

struct WindowSnapper {
    static func snap(window: NSWindow, to position: SnapPosition) {
        guard let screen = window.screen ?? NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let windowSize = window.frame.size

        let origin: NSPoint
        switch position {
        case .topLeft:
            origin = NSPoint(
                x: visibleFrame.minX,
                y: visibleFrame.maxY - windowSize.height
            )
        case .topRight:
            origin = NSPoint(
                x: visibleFrame.maxX - windowSize.width,
                y: visibleFrame.maxY - windowSize.height
            )
        case .bottomLeft:
            origin = NSPoint(
                x: visibleFrame.minX,
                y: visibleFrame.minY
            )
        case .bottomRight:
            origin = NSPoint(
                x: visibleFrame.maxX - windowSize.width,
                y: visibleFrame.minY
            )
        case .center:
            origin = NSPoint(
                x: visibleFrame.midX - windowSize.width / 2,
                y: visibleFrame.midY - windowSize.height / 2
            )
        }

        let newFrame = NSRect(origin: origin, size: windowSize)
        window.setFrame(newFrame, display: true, animate: true)
    }
}
