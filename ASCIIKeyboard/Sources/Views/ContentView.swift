import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPreview = false
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(spacing: 16) {
            // Header with enable toggle
            HStack {
                Text("ASCII Keyboard")
                    .font(.headline)
                Spacer()

                // Big toggle button
                Button(action: {
                    appState.toggleEnabled()
                }) {
                    HStack {
                        Image(systemName: appState.isEnabled ? "keyboard.fill" : "keyboard")
                        Text(appState.isEnabled ? "ON" : "OFF")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(appState.isEnabled ? Color.green : Color.gray.opacity(0.3))
                    .foregroundColor(appState.isEnabled ? .white : .primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            if !TextInjectionService.shared.hasAccessibilityPermissions() {
                Button(action: {
                    TextInjectionService.shared.requestAccessibilityPermissions()
                }) {
                    Label("Grant Accessibility Access", systemImage: "lock.shield")
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            // Font selector
            HStack {
                Text("Font:")
                    .font(.subheadline)
                Picker("", selection: $appState.selectedFont) {
                    ForEach(appState.availableFonts) { font in
                        Text(font.name).tag(font as FIGletFont?)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            // Status
            if appState.isEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Type text, press ENTER to output")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Show current word being typed
                    if !appState.currentWord.isEmpty {
                        HStack {
                            Text("Typing:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appState.currentWord)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Click ON to start typing ASCII art")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Preview toggle
            HStack {
                Toggle("Show Preview", isOn: $showingPreview)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                Spacer()
                Button("Clear") {
                    appState.clearOutput()
                }
                .controlSize(.small)
                .disabled(appState.currentOutput.isEmpty)
            }

            // Preview area (collapsible)
            if showingPreview {
                PreviewArea()
            }

            Divider()

            // Settings
            HStack {
                Toggle("Start at Login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLogin.isEnabled = newValue
                    }
                Spacer()
            }

            Divider()

            // Footer
            HStack {
                Text("⌘+Shortcuts still work normally")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: 320)
    }
}

struct PreviewArea: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(appState.currentOutput.isEmpty ? samplePreview : appState.currentOutput)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(appState.currentOutput.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 100)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var samplePreview: String {
        guard let font = appState.selectedFont else {
            return "Select a font to see preview"
        }
        let service = FIGletService()
        return service.render("Hi", font: font)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
