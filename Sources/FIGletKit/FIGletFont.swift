import Foundation

public struct FIGletFont: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let height: Int
    public let baseline: Int
    public let maxWidth: Int
    public let hardblank: Character
    public let characters: [Int: [String]]  // ASCII code -> lines

    public init(name: String, height: Int, baseline: Int, maxWidth: Int, hardblank: Character, characters: [Int: [String]]) {
        self.name = name
        self.height = height
        self.baseline = baseline
        self.maxWidth = maxWidth
        self.hardblank = hardblank
        self.characters = characters
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public static func == (lhs: FIGletFont, rhs: FIGletFont) -> Bool {
        lhs.name == rhs.name
    }
}

public struct FIGletParser {
    public enum ParseError: Error {
        case invalidHeader
        case invalidFile
        case missingCharacters
    }

    public static func parse(content: String, name: String) throws -> FIGletFont {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw ParseError.invalidFile }

        // Parse header line
        // Format: flf2a$ height baseline maxLength oldLayout commentLines [printDirection] [fullLayout] [codetagCount]
        // The hardblank character is the 6th character (after "flf2a")
        let header = lines[0]
        guard header.hasPrefix("flf2a") else { throw ParseError.invalidHeader }

        // Extract hardblank (the character right after "flf2a")
        let hardblankIndex = header.index(header.startIndex, offsetBy: 5)
        let hardblank = header[hardblankIndex]

        // Get the rest of the header after the hardblank
        let afterHardblank = String(header[header.index(after: hardblankIndex)...])
        let headerParts = afterHardblank.split(separator: " ", omittingEmptySubsequences: true)
        guard headerParts.count >= 5 else { throw ParseError.invalidHeader }

        guard let height = Int(headerParts[0]),
              let baseline = Int(headerParts[1]),
              let maxWidth = Int(headerParts[2]),
              let commentLines = Int(headerParts[4]) else {
            throw ParseError.invalidHeader
        }

        // Skip header and comment lines
        let dataStartIndex = 1 + commentLines

        // Parse characters (ASCII 32-126 are required)
        var characters: [Int: [String]] = [:]
        var currentLine = dataStartIndex

        for asciiCode in 32...126 {
            guard currentLine + height <= lines.count else { break }

            var charLines: [String] = []
            for i in 0..<height {
                var line = lines[currentLine + i]
                // Remove end markers (@ or @@)
                while line.hasSuffix("@") {
                    line = String(line.dropLast())
                }
                // Replace hardblank with space
                line = line.replacingOccurrences(of: String(hardblank), with: " ")
                charLines.append(line)
            }
            characters[asciiCode] = charLines
            currentLine += height
        }

        guard !characters.isEmpty else { throw ParseError.missingCharacters }

        return FIGletFont(
            name: name,
            height: height,
            baseline: baseline,
            maxWidth: maxWidth,
            hardblank: hardblank,
            characters: characters
        )
    }
}
