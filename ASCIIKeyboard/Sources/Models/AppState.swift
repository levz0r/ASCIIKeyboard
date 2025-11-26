import SwiftUI
import Combine
import AppKit

class AppState: ObservableObject {
    @Published var selectedFont: FIGletFont? {
        didSet {
            // Only save if initialization is complete
            if isInitialized, let font = selectedFont {
                UserDefaults.standard.set(font.name, forKey: "selectedFontName")
            }
        }
    }
    @Published var availableFonts: [FIGletFont] = []
    @Published var currentOutput: String = ""
    @Published var isEnabled: Bool = false
    @Published var currentWord: String = ""  // Buffer for current word

    private let figletService = FIGletService()
    private var previousApp: NSRunningApplication?
    private var isInitialized = false

    init() {
        loadFonts()
        restoreSelectedFont()
        isInitialized = true
        setupKeyboardMonitor()
    }

    private func restoreSelectedFont() {
        let savedName = UserDefaults.standard.string(forKey: "selectedFontName")
        debugLog("Restoring font: \(savedName ?? "none saved")")

        if let savedName = savedName,
           let font = availableFonts.first(where: { $0.name == savedName }) {
            selectedFont = font
            debugLog("Restored font: \(font.name)")
        } else if let first = availableFonts.first {
            selectedFont = first
            debugLog("Using first font: \(first.name)")
        }
    }

    private func setupKeyboardMonitor() {
        KeyboardMonitor.shared.onKeyPress = { [weak self] char in
            return self?.handlePhysicalKeyPress(char) ?? false
        }
    }

    func toggleEnabled() {
        isEnabled.toggle()
        if isEnabled {
            KeyboardMonitor.shared.start()
            debugLog("ASCII mode enabled")
        } else {
            KeyboardMonitor.shared.stop()
            InputPreviewPanel.shared.hide()
            currentWord = ""
            debugLog("ASCII mode disabled")
        }
    }

    private func handlePhysicalKeyPress(_ char: Character) -> Bool {
        guard isEnabled else { return false }

        debugLog("Physical key pressed: \(char)")

        if char == "\n" {
            // ENTER outputs the buffered line
            flushLine()
        } else if char == "\u{1B}" {
            // ESC cancels current input
            cancelInput()
        } else if char == "\u{08}" {
            // Backspace removes last character, or pass through if buffer empty
            if !currentWord.isEmpty {
                currentWord.removeLast()
            } else {
                // Let backspace pass through to target app
                return false
            }
        } else {
            // Buffer all characters (including spaces)
            currentWord.append(char)
            debugLog("Current buffer: \(currentWord)")
        }

        // Update floating preview panel
        DispatchQueue.main.async {
            InputPreviewPanel.shared.updateContent(text: self.currentWord, isEnabled: self.isEnabled)
        }
        return true
    }

    private func cancelInput() {
        debugLog("Input cancelled")
        currentWord = ""
        InputPreviewPanel.shared.hide()
    }

    private func flushLine() {
        guard !currentWord.isEmpty else {
            // Empty buffer, just output newline
            TextInjectionService.shared.typeText("\n")
            return
        }

        debugLog("Flushing line: \(currentWord)")

        // Render the entire line as one ASCII art block
        guard let font = selectedFont else {
            currentWord = ""
            InputPreviewPanel.shared.hide()
            return
        }

        let asciiArt = figletService.render(currentWord, font: font)
        currentOutput += asciiArt
        TextInjectionService.shared.typeText(asciiArt)

        currentWord = ""
        InputPreviewPanel.shared.hide()
    }

    /// Call this when the popover opens to remember the previous app
    func rememberPreviousApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    /// Reactivate the previous app
    func activatePreviousApp() {
        previousApp?.activate(options: [])
    }

    func loadFonts() {
        availableFonts = figletService.loadBundledFonts()
    }

    func renderCharacter(_ char: Character) -> String {
        guard let font = selectedFont else { return String(char) }
        return figletService.render(String(char), font: font)
    }

    func typeCharacter(_ char: Character) {
        debugLog("typeCharacter called with '\(char)'")
        let asciiArt = renderCharacter(char)
        debugLog("ASCII art generated, length: \(asciiArt.count)")
        currentOutput += asciiArt
        // Activate previous app, then type
        debugLog("Previous app: \(previousApp?.localizedName ?? "none")")
        activatePreviousApp()
        TextInjectionService.shared.typeText(asciiArt)
    }

    func typeSpace() {
        guard let font = selectedFont else { return }
        let spaceWidth = font.maxWidth
        let space = String(repeating: " ", count: spaceWidth) + "\n"
        let multilineSpace = (0..<font.height).map { _ in space }.joined()
        activatePreviousApp()
        TextInjectionService.shared.typeText(multilineSpace)
    }

    func typeNewline() {
        activatePreviousApp()
        TextInjectionService.shared.typeText("\n")
    }

    func clearOutput() {
        currentOutput = ""
    }
}
