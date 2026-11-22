import XCTest
@testable import FIGletKit

final class FIGletKitTests: XCTestCase {
    func testEmbeddedFontsParse() {
        let fonts = FIGletService().loadEmbeddedFonts()
        XCTAssertEqual(fonts.count, 20)
        XCTAssertEqual(fonts.count, EmbeddedFonts.all.count, "every embedded font parses")
        XCTAssertTrue(fonts.contains { $0.name == "standard" })
    }

    func testStandardRenderHi() throws {
        let font = try FIGletParser.parse(content: EmbeddedFonts.standard, name: "standard")
        XCTAssertEqual(font.height, 6)
        let expected = [
            "  _   _   _ ",
            " | | | | (_)",
            " | |_| | | |",
            " |  _  | | |",
            " |_| |_| |_|",
            "            ",
        ].joined(separator: "\n") + "\n"
        XCTAssertEqual(FIGletService().render("Hi", font: font), expected)
    }

    func testEveryLineHasFontHeight() throws {
        for font in FIGletService().loadEmbeddedFonts() {
            let out = FIGletService().render("Abc 123!", font: font)
            XCTAssertEqual(out.split(separator: "\n", omittingEmptySubsequences: false).count, font.height + 1, font.name)
        }
    }

    func testBundledFlfFontsLoad() {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ASCIIKeyboard/Resources/Fonts")
        XCTAssertEqual(FIGletService().loadFontsFromDirectory(dir).count, 20)
    }

    func testEmbeddedFontsMatchFiles() {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("ASCIIKeyboard/Resources/Fonts")
        let service = FIGletService()
        let fromFiles = Dictionary(uniqueKeysWithValues: service.loadFontsFromDirectory(dir).map { ($0.name, $0.characters) })
        for font in service.loadEmbeddedFonts() {
            XCTAssertEqual(font.characters, fromFiles[font.name], "\(font.name): run scripts/generate-embedded-fonts.py")
        }
    }

    func testEmptyTextRendersNothing() throws {
        let font = try FIGletParser.parse(content: EmbeddedFonts.standard, name: "standard")
        XCTAssertEqual(FIGletService().render("", font: font), "")
    }
}
