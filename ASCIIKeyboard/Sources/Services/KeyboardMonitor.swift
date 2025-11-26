import Foundation
import Cocoa
import Carbon

class KeyboardMonitor {
    static let shared = KeyboardMonitor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = false
    private(set) var hasInputMonitoringPermission = false

    var onKeyPress: ((Character) -> Bool)?  // Returns true to block the key, false to pass through

    private init() {}

    /// Test if we can create an event tap (requires Input Monitoring permission)
    func checkInputMonitoringPermission() -> Bool {
        // If we already have an event tap, we have permission
        if eventTap != nil {
            hasInputMonitoringPermission = true
            return true
        }

        // Try to create a minimal event tap to test permission
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,  // Use listenOnly for the test
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        if testTap != nil {
            // Clean up the test tap immediately
            CFMachPortInvalidate(testTap!)
            hasInputMonitoringPermission = true
            debugLog("Input Monitoring permission: granted")
            return true
        } else {
            hasInputMonitoringPermission = false
            debugLog("Input Monitoring permission: NOT granted")
            return false
        }
    }

    func start() {
        guard eventTap == nil else { return }

        // Create event tap to monitor keyboard events
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                return KeyboardMonitor.shared.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: nil
        )

        guard let eventTap = eventTap else {
            debugLog("Failed to create event tap - check accessibility permissions")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isEnabled = true
        debugLog("Keyboard monitor started")
    }

    func stop() {
        guard let eventTap = eventTap else { return }

        CGEvent.tapEnable(tap: eventTap, enable: false)
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        self.eventTap = nil
        self.runLoopSource = nil
        isEnabled = false
        debugLog("Keyboard monitor stopped")
    }

    var isMonitoring: Bool {
        return isEnabled
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // If disabled or not a keydown, pass through
        guard isEnabled, type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        // Check if command/control/option is held - if so, pass through (allow shortcuts)
        let flags = event.flags
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            return Unmanaged.passRetained(event)
        }

        // Get the character
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Convert keycode to character
        guard let char = keyCodeToCharacter(Int(keyCode), shift: flags.contains(.maskShift)) else {
            return Unmanaged.passRetained(event)
        }

        debugLog("Intercepted key: \(char)")

        // Call the handler to get block decision
        var shouldBlock = true
        if Thread.isMainThread {
            shouldBlock = self.onKeyPress?(char) ?? true
        } else {
            DispatchQueue.main.sync {
                shouldBlock = self.onKeyPress?(char) ?? true
            }
        }

        if shouldBlock {
            // Block the original event (return nil to suppress it)
            return nil
        } else {
            // Pass through the event
            return Unmanaged.passRetained(event)
        }
    }

    private func keyCodeToCharacter(_ keyCode: Int, shift: Bool) -> Character? {
        // Map key codes to characters
        let keyMap: [Int: (normal: Character, shifted: Character)] = [
            // Letters
            0: ("a", "A"), 1: ("s", "S"), 2: ("d", "D"), 3: ("f", "F"),
            4: ("h", "H"), 5: ("g", "G"), 6: ("z", "Z"), 7: ("x", "X"),
            8: ("c", "C"), 9: ("v", "V"), 11: ("b", "B"), 12: ("q", "Q"),
            13: ("w", "W"), 14: ("e", "E"), 15: ("r", "R"), 16: ("y", "Y"),
            17: ("t", "T"), 31: ("o", "O"), 32: ("u", "U"), 34: ("i", "I"),
            35: ("p", "P"), 37: ("l", "L"), 38: ("j", "J"), 40: ("k", "K"),
            45: ("n", "N"), 46: ("m", "M"),

            // Numbers
            18: ("1", "!"), 19: ("2", "@"), 20: ("3", "#"), 21: ("4", "$"),
            22: ("6", "^"), 23: ("5", "%"), 25: ("9", "("), 26: ("7", "&"),
            28: ("8", "*"), 29: ("0", ")"),

            // Punctuation
            24: ("=", "+"),   // Equal/Plus
            27: ("-", "_"),   // Minus/Underscore
            30: ("]", "}"),   // Right bracket
            33: ("[", "{"),   // Left bracket
            39: ("'", "\""),  // Quote
            41: (";", ":"),   // Semicolon
            42: ("\\", "|"),  // Backslash
            43: (",", "<"),   // Comma
            44: ("/", "?"),   // Slash/Question mark
            47: (".", ">"),   // Period
            50: ("`", "~"),   // Backtick

            // Space, Return, and special keys
            49: (" ", " "),  // Space
            36: ("\n", "\n"), // Return
            51: ("\u{08}", "\u{08}"),  // Delete/Backspace
            53: ("\u{1B}", "\u{1B}"),  // Escape
        ]

        guard let mapping = keyMap[keyCode] else {
            return nil
        }

        return shift ? mapping.shifted : mapping.normal
    }
}
