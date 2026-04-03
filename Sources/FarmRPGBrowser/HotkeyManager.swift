import AppKit
import Carbon

// Global reference for the Carbon callback
private var hotkeyManagerInstance: HotkeyManager?

class HotkeyManager {
    weak var window: MainWindow?
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(window: MainWindow) {
        self.window = window
        hotkeyManagerInstance = self
    }

    /// Register Cmd+Shift+F as global hotkey
    func register() {
        // Define the hotkey: Cmd+Shift+F
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 3  // 'F' key

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x46524D52) // "FRMR"
        hotKeyID.id = 1

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            hotkeyManagerInstance?.toggleWindowVisibility()
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        // Register the hotkey
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }

    func unregister() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    func toggleWindowVisibility() {
        guard let window = window else { return }

        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    deinit {
        unregister()
        if hotkeyManagerInstance === self {
            hotkeyManagerInstance = nil
        }
    }
}
