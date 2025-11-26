import Foundation
import ApplicationServices
import Carbon

func debugLog(_ message: String) {
    let logFile = "/tmp/asciikeyboard.log"
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    if let handle = FileHandle(forWritingAtPath: logFile) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logFile, contents: line.data(using: .utf8))
    }
}

class TextInjectionService {
    static let shared = TextInjectionService()

    private init() {}

    /// Check if the app has accessibility permissions
    func hasAccessibilityPermissions() -> Bool {
        let trusted = AXIsProcessTrusted()
        debugLog("AXIsProcessTrusted() = \(trusted), Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        return trusted
    }

    /// Request accessibility permissions (opens System Preferences)
    func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Types text into the currently focused application
    func typeText(_ text: String) {
        debugLog("typeText called, text length: \(text.count)")
        debugLog("hasAccessibilityPermissions = \(hasAccessibilityPermissions())")

        guard hasAccessibilityPermissions() else {
            debugLog("No accessibility permissions, requesting...")
            requestAccessibilityPermissions()
            return
        }

        debugLog("Scheduling paste in 0.3s")
        // Delay to let the previous app regain focus after menu closes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            debugLog("Executing paste now")
            // Use the clipboard method for reliability with multi-line ASCII art
            self.typeViaClipboard(text)
        }
    }

    /// Type text by temporarily using the clipboard
    private func typeViaClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let previousContents = pasteboard.string(forType: .string)

        // Set new content
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        debugLog("Clipboard set success: \(success)")
        debugLog("Clipboard now contains: \(pasteboard.string(forType: .string)?.prefix(50) ?? "nil")...")

        // Check what app is frontmost now
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            debugLog("Frontmost app before paste: \(frontApp.localizedName ?? "unknown")")
        }

        // Simulate Cmd+V
        simulatePaste()

        // Restore clipboard after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pasteboard.clearContents()
            if let previous = previousContents {
                pasteboard.setString(previous, forType: .string)
            }
        }
    }

    /// Simulate Cmd+V keystroke using CGEvent (doesn't require Automation permission)
    private func simulatePaste() {
        debugLog("simulatePaste() called - using CGEvent")

        let source = CGEventSource(stateID: .hidSystemState)

        // Virtual key code for 'V' is 9
        let vKeyCode: CGKeyCode = 9

        // Create key down event with Command modifier
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) else {
            debugLog("Failed to create keyDown event")
            return
        }
        keyDown.flags = .maskCommand

        // Create key up event with Command modifier
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            debugLog("Failed to create keyUp event")
            return
        }
        keyUp.flags = .maskCommand

        // Post the events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        debugLog("CGEvent paste executed")
    }

    /// Alternative: Type character by character using key events (slower but doesn't use clipboard)
    func typeCharacterByCharacter(_ text: String) {
        guard hasAccessibilityPermissions() else {
            requestAccessibilityPermissions()
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)

        for char in text {
            if char == "\n" {
                // Press Enter
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Return), keyDown: true)
                keyDown?.post(tap: .cghidEventTap)
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Return), keyDown: false)
                keyUp?.post(tap: .cghidEventTap)
            } else {
                // Use Unicode input for other characters
                var unicodeChar = Array(String(char).utf16)
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
                keyDown?.keyboardSetUnicodeString(stringLength: unicodeChar.count, unicodeString: &unicodeChar)
                keyDown?.post(tap: .cghidEventTap)

                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
                keyUp?.post(tap: .cghidEventTap)
            }

            // Small delay between keystrokes
            usleep(1000) // 1ms
        }
    }
}

import AppKit
