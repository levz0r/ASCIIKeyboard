import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject var appState: AppState
    let onKeyPress: (Character) -> Void

    private let keyboardRows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]

    var body: some View {
        VStack(spacing: 6) {
            // Number row
            HStack(spacing: 4) {
                ForEach(keyboardRows[0], id: \.self) { key in
                    KeyButton(key: key, onPress: onKeyPress)
                }
            }

            // QWERTY row
            HStack(spacing: 4) {
                ForEach(keyboardRows[1], id: \.self) { key in
                    KeyButton(key: key, onPress: onKeyPress)
                }
            }

            // ASDF row
            HStack(spacing: 4) {
                ForEach(keyboardRows[2], id: \.self) { key in
                    KeyButton(key: key, onPress: onKeyPress)
                }
            }

            // ZXCV row
            HStack(spacing: 4) {
                ForEach(keyboardRows[3], id: \.self) { key in
                    KeyButton(key: key, onPress: onKeyPress)
                }
            }

            // Space and special keys
            HStack(spacing: 4) {
                SpecialKeyButton(label: "Space", systemImage: "space") {
                    appState.typeSpace()
                }
                .frame(maxWidth: .infinity)

                SpecialKeyButton(label: "Return", systemImage: "return") {
                    appState.typeNewline()
                }
            }
        }
        .padding(8)
    }
}

struct KeyButton: View {
    let key: String
    let onPress: (Character) -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            if let char = key.first {
                onPress(char)
            }
        }) {
            Text(key)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .frame(width: 28, height: 28)
                .background(isPressed ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isPressed ? .white : .primary)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isPressed = hovering
        }
    }
}

struct SpecialKeyButton: View {
    let label: String
    let systemImage: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .background(isPressed ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .foregroundColor(isPressed ? .white : .primary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isPressed = hovering
        }
    }
}

#Preview {
    KeyboardView { char in
        print("Pressed: \(char)")
    }
    .environmentObject(AppState())
    .frame(width: 350)
}
