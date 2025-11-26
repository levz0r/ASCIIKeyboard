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
        return AXIsProcessTrusted()
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

    /// Simulate Cmd+V keystroke using AppleScript (more reliable across apps)
    private func simulatePaste() {
        debugLog("simulatePaste() called - using AppleScript")

        // Get the frontmost app name
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let appName = frontApp.localizedName else {
            debugLog("No frontmost app found")
            return
        }

        debugLog("Will paste to: \(appName)")

        // Activate the app first, then keystroke
        let script = """
        tell application "\(appName)"
            activate
        end tell
        delay 0.1
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                debugLog("AppleScript error: \(error)")
            } else {
                debugLog("AppleScript paste executed successfully")
            }
        } else {
            debugLog("Failed to create AppleScript")
        }
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
