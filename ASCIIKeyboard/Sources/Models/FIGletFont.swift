import Foundation

struct FIGletFont: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let height: Int
    let baseline: Int
    let maxWidth: Int
    let hardblank: Character
    let characters: [Int: [String]]  // ASCII code -> lines

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: FIGletFont, rhs: FIGletFont) -> Bool {
        lhs.name == rhs.name
    }
}

struct FIGletParser {
    enum ParseError: Error {
        case invalidHeader
        case invalidFile
        case missingCharacters
    }

    static func parse(content: String, name: String) throws -> FIGletFont {
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
