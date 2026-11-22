// swift-tools-version: 5.9
import PackageDescription

// FIGletKit (renderer + fonts) and the `ascii-keyboard` CLI build on macOS and Linux.
// The menu bar app uses AppKit/Carbon/SwiftUI, so it is only defined on macOS.

var products: [Product] = [
    .library(name: "FIGletKit", targets: ["FIGletKit"]),
    .executable(name: "ascii-keyboard", targets: ["ascii-keyboard"])
]

var targets: [Target] = [
    .target(name: "FIGletKit", path: "Sources/FIGletKit"),
    .executableTarget(name: "ascii-keyboard", dependencies: ["FIGletKit"], path: "Sources/ascii-keyboard"),
    .testTarget(name: "FIGletKitTests", dependencies: ["FIGletKit"], path: "Tests/FIGletKitTests")
]

#if os(macOS)
products.append(.executable(name: "ASCIIKeyboard", targets: ["ASCIIKeyboard"]))
targets.append(
    .executableTarget(
        name: "ASCIIKeyboard",
        dependencies: ["FIGletKit"],
        path: "ASCIIKeyboard/Sources",
        sources: [
            "App/ASCIIKeyboardApp.swift",
            "Models/AppState.swift",
            "Services/TextInjectionService.swift",
            "Services/KeyboardMonitor.swift",
            "Services/LaunchAtLogin.swift",
            "Views/ContentView.swift",
            "Views/InputPreviewPanel.swift"
        ]
    )
)
#endif

let package = Package(
    name: "ASCIIKeyboard",
    platforms: [
        .macOS(.v13)
    ],
    products: products,
    targets: targets
)
