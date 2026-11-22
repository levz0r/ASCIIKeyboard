import Foundation
import FIGletKit

// ascii-keyboard: render text as FIGlet ASCII art in the terminal.
// Shares its renderer and fonts with the macOS menu bar app.

let usage = """
Usage: ascii-keyboard [options] [text ...]

Renders text as ASCII art. With no text, reads lines from standard input.

Options:
  -f, --font <name>      Font to use (default: standard). Case-insensitive.
  -d, --font-dir <path>  Extra directory of .flf fonts (repeatable).
  -l, --list             List available fonts.
  -a, --all              Render the text in every available font.
  -h, --help             Show this help.

All 20 fonts that ship with the macOS app are built in. Extra fonts are
loaded from --font-dir, then $ASCIIKEYBOARD_FONTS (colon-separated),
then /usr/share/figlet. A built-in font wins over a file with the same name.
"""

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("ascii-keyboard: \(message)\n".utf8))
    exit(2)
}

var fontName = "standard"
var extraDirs: [String] = []
var listFonts = false
var renderAll = false
var words: [String] = []

var args = CommandLine.arguments.dropFirst()
while let arg = args.popFirst() {
    switch arg {
    case "-f", "--font":
        guard let value = args.popFirst() else { fail("\(arg) needs a font name") }
        fontName = value
    case "-d", "--font-dir":
        guard let value = args.popFirst() else { fail("\(arg) needs a directory") }
        extraDirs.append(value)
    case "-l", "--list": listFonts = true
    case "-a", "--all": renderAll = true
    case "-h", "--help": print(usage); exit(0)
    case "--": words.append(contentsOf: args); args.removeAll()
    default:
        if arg.hasPrefix("-") && arg.count > 1 { fail("unknown option \(arg) (see --help)") }
        words.append(arg)
    }
}

// Collect fonts. Earlier sources win on name clashes (compared case-insensitively).
let service = FIGletService()
var fonts: [FIGletFont] = service.loadEmbeddedFonts()

var searchDirs = extraDirs
if let env = ProcessInfo.processInfo.environment["ASCIIKEYBOARD_FONTS"] {
    searchDirs.append(contentsOf: env.split(separator: ":").map(String.init))
}
searchDirs.append("/usr/share/figlet")

var seen = Set(fonts.map { $0.name.lowercased() })
for dir in searchDirs {
    for font in service.loadFontsFromDirectory(URL(fileURLWithPath: dir)).sorted(by: { $0.name < $1.name })
    where !seen.contains(font.name.lowercased()) {
        seen.insert(font.name.lowercased())
        fonts.append(font)
    }
}
fonts.sort { $0.name.lowercased() < $1.name.lowercased() }

if listFonts {
    fonts.forEach { print($0.name) }
    exit(0)
}

var lines: [String]
if words.isEmpty {
    lines = []
    while let line = readLine() { lines.append(line) }
} else {
    lines = [words.joined(separator: " ")]
}

func renderLines(_ font: FIGletFont) -> String {
    lines.map { $0.isEmpty ? String(repeating: "\n", count: font.height) : service.render($0, font: font) }
        .joined()
}

if renderAll {
    for font in fonts {
        print("== \(font.name)")
        print(renderLines(font))
    }
    exit(0)
}

guard let font = fonts.first(where: { $0.name.caseInsensitiveCompare(fontName) == .orderedSame }) else {
    fail("no font named '\(fontName)'. Try --list.")
}
print(renderLines(font), terminator: "")
