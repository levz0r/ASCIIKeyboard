# ASCII Keyboard

A macOS menu bar app that transforms your typing into ASCII art.

## Installation

1. Download the DMG from [Releases](https://github.com/levz0r/ASCIIKeyboard/releases)
2. Open the DMG and drag ASCII Keyboard to Applications
3. If you see "app is damaged" error, run in Terminal:
   ```bash
   xattr -cr /Applications/ASCII\ Keyboard.app
   ```
4. Open ASCII Keyboard and grant Accessibility permissions when prompted

## Features

- **Menu Bar App**: Lives in your menu bar, always accessible
- **Multiple Fonts**: Includes Standard, Banner, Big, and Slant FIGlet fonts
- **Direct Typing**: ASCII art is typed directly into the focused application
- **Preview Mode**: See your ASCII art before typing it

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (required for typing into other apps)

## Building

### Option 1: Using Swift Package Manager

```bash
cd ASCIIKeyboard
swift build -c release
```

The executable will be at `.build/release/ASCIIKeyboard`

### Option 2: Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select "App" under macOS
4. Name it "ASCIIKeyboard"
5. Delete the default ContentView.swift
6. Drag all files from `ASCIIKeyboard/Sources/` into the project
7. Set these build settings:
   - Deployment Target: macOS 13.0
   - Info.plist: Set `LSUIElement` to `YES` (makes it a menu bar app)
   - Disable App Sandbox (required for accessibility)

## Usage

1. Launch the app - it will appear in your menu bar as a keyboard icon
2. Click the icon to open the keyboard
3. Grant Accessibility permissions when prompted
4. Select a font from the dropdown
5. Click on a key to type the ASCII art version into your currently focused app

## Permissions

This app requires **Accessibility permissions** to type into other applications.

When you first use the keyboard:
1. A dialog will appear asking for Accessibility access
2. Click "Open System Preferences"
3. Enable ASCIIKeyboard in Privacy & Security → Accessibility

## How It Works

The app uses:
- **FIGlet fonts**: Industry-standard ASCII art fonts
- **CGEvent API**: To simulate keyboard input (via clipboard paste)
- **SwiftUI MenuBarExtra**: Native macOS menu bar integration

## Adding More Fonts

You can add more FIGlet fonts (.flf files):
1. Download fonts from [figlet.org](http://www.figlet.org/fontdb.cgi)
2. Add them to the app's Fonts directory
3. Or embed them in `EmbeddedFonts.swift`

## License

MIT
