// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ASCIIKeyboard",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ASCIIKeyboard", targets: ["ASCIIKeyboard"])
    ],
    targets: [
        .executableTarget(
            name: "ASCIIKeyboard",
            path: "ASCIIKeyboard/Sources",
            sources: [
                "App/ASCIIKeyboardApp.swift",
                "Models/AppState.swift",
                "Models/FIGletFont.swift",
                "Services/FIGletService.swift",
                "Services/TextInjectionService.swift",
                "Services/KeyboardMonitor.swift",
                "Services/LaunchAtLogin.swift",
                "Views/ContentView.swift",
                "Views/InputPreviewPanel.swift",
                "Fonts/EmbeddedFonts.swift"
            ]
        )
    ]
)
