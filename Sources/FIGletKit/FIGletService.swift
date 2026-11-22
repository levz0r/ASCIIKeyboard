import Foundation

public final class FIGletService {
    private var fonts: [String: FIGletFont] = [:]

    public init() {}

    public func loadBundledFonts() -> [FIGletFont] {
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

        // Fallback: fonts compiled into the binary (e.g. running via `swift run` outside an .app bundle)
        if loadedFonts.isEmpty {
            debugLog("No font files found; using embedded fonts")
            loadedFonts.append(contentsOf: loadEmbeddedFonts())
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

    public func loadFontsFromDirectory(_ url: URL) -> [FIGletFont] {
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

    public func loadFont(from url: URL) -> FIGletFont? {
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
            debugLog("Failed to load font from \(url.path): \(error)")
            return nil
        }
    }

    /// Every font compiled into the binary (see EmbeddedFonts), sorted by name.
    public func loadEmbeddedFonts() -> [FIGletFont] {
        EmbeddedFonts.all.compactMap { entry in
            do {
                return try FIGletParser.parse(content: entry.content, name: entry.name)
            } catch {
                debugLog("Failed to parse embedded font \(entry.name): \(error)")
                return nil
            }
        }
    }

    public func render(_ text: String, font: FIGletFont) -> String {
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

/// Library-local debug logging. Set ASCIIKEYBOARD_DEBUG=1 to print to stderr.
func debugLog(_ message: String) {
    guard ProcessInfo.processInfo.environment["ASCIIKEYBOARD_DEBUG"] != nil else { return }
    FileHandle.standardError.write(Data(("[FIGletKit] " + message + "\n").utf8))
}
