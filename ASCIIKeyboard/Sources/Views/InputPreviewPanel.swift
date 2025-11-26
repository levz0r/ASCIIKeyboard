import SwiftUI
import AppKit

class InputPreviewPanel: NSPanel {
    static let shared = InputPreviewPanel()

    private var hostingView: NSHostingView<InputPreviewContent>?

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 60),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Position at bottom center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 200
            let y = screenFrame.minY + 100
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func updateContent(text: String, isEnabled: Bool) {
        if hostingView == nil {
            let view = InputPreviewContent(text: text)
            hostingView = NSHostingView(rootView: view)
            self.contentView = hostingView
        } else {
            hostingView?.rootView = InputPreviewContent(text: text)
        }

        if isEnabled && !text.isEmpty {
            orderFront(nil)
        } else {
            orderOut(nil)
        }
    }

    func hide() {
        orderOut(nil)
    }
}

struct InputPreviewContent: View {
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "keyboard")
                    .foregroundColor(.secondary)
                Text("ASCII Keyboard")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Press ENTER to output")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(text)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
        )
        .frame(width: 400)
    }
}
