import SwiftUI

@main
struct ASCIIKeyboardApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isEnabled ? "keyboard.fill" : "keyboard")
        }
        .menuBarExtraStyle(.window)
    }
}
