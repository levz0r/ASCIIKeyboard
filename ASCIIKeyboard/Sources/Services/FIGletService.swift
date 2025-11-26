import Foundation

class FIGletService {
    private var fonts: [String: FIGletFont] = [:]

    func loadBundledFonts() -> [FIGletFont] {
        var loadedFonts: [FIGletFont] = []

        // Try app bundle first (for distributed app)
        if let bundleURL = Bundle.main.resourceURL {
            let bundleFontsDir = bundleURL.appendingPathComponent("Fonts")
            debugLog("Looking for fonts in bundle: \(bundleFontsDir.path)")
            let bundleFonts = loadFontsFromDirectory(bundleFontsDir)
            debugLog("Loaded \(bundleFonts.count) fonts from bundle")
            loadedFonts.append(contentsOf: bundleFonts)
        }

        // Try relative to executable (for .app bundle)
        let executableURL = Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0])
        let appBundleFonts = executableURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Fonts")
        loadedFonts.append(contentsOf: loadFontsFromDirectory(appBundleFonts))

        // Development fallback path
        let fallbackPath = URL(fileURLWithPath: "/Users/lev/Dev/ASCIIKeyboard/ASCIIKeyboard/Resources/Fonts")
        if loadedFonts.isEmpty {
            debugLog("Loading fonts from fallback: \(fallbackPath.path)")
            loadedFonts.append(contentsOf: loadFontsFromDirectory(fallbackPath))
        }

        // Deduplicate by name
        var seen = Set<String>()
        loadedFonts = loadedFonts.filter { font in
            if seen.contains(font.name) {
                return false
            }
            seen.insert(font.name)
            return true
        }

        debugLog("Total fonts after dedup: \(loadedFonts.count)")
        for font in loadedFonts {
            debugLog("  - \(font.name)")
        }

        return loadedFonts.sorted { $0.name < $1.name }
    }

    private func loadFontsFromDirectory(_ url: URL) -> [FIGletFont] {
        var fonts: [FIGletFont] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) else {
            return fonts
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "flf" {
                if let font = loadFont(from: fileURL) {
                    fonts.append(font)
                }
            }
        }

        return fonts
    }

    private func loadFont(from url: URL) -> FIGletFont? {
        do {
            let name = url.deletingPathExtension().lastPathComponent
            // Try UTF-8 first, then Latin-1 for fonts with extended characters
            let content: String
            if let utf8Content = try? String(contentsOf: url, encoding: .utf8) {
                content = utf8Content
            } else if let latin1Content = try? String(contentsOf: url, encoding: .isoLatin1) {
                content = latin1Content
            } else {
                throw NSError(domain: "FIGletService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to read font file"])
            }
            return try FIGletParser.parse(content: content, name: name)
        } catch {
            print("Failed to load font from \(url): \(error)")
            return nil
        }
    }

    private func loadEmbeddedFonts() -> [FIGletFont] {
        var fonts: [FIGletFont] = []

        // Standard font (embedded)
        if let standardFont = try? FIGletParser.parse(content: EmbeddedFonts.standard, name: "Standard") {
            fonts.append(standardFont)
        }

        if let bannerFont = try? FIGletParser.parse(content: EmbeddedFonts.banner, name: "Banner") {
            fonts.append(bannerFont)
        }

        if let bigFont = try? FIGletParser.parse(content: EmbeddedFonts.big, name: "Big") {
            fonts.append(bigFont)
        }

        if let slantFont = try? FIGletParser.parse(content: EmbeddedFonts.slant, name: "Slant") {
            fonts.append(slantFont)
        }

        return fonts
    }

    func render(_ text: String, font: FIGletFont) -> String {
        guard !text.isEmpty else { return "" }

        var resultLines = Array(repeating: "", count: font.height)

        for char in text {
            let asciiCode = Int(char.asciiValue ?? 32)
            guard let charLines = font.characters[asciiCode] ?? font.characters[32] else {
                continue
            }

            for (index, line) in charLines.enumerated() where index < font.height {
                resultLines[index] += line
            }
        }

        return resultLines.joined(separator: "\n") + "\n"
    }
}
