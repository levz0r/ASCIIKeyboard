#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="ASCII Keyboard"
BUNDLE_ID="com.yourcompany.ASCIIKeyboard"
VERSION="1.0.0"

echo "=== Building ASCII Keyboard for Distribution ==="

# Build release binary
echo "Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

# Create app bundle structure
APP_BUNDLE="$PROJECT_DIR/dist/$APP_NAME.app"
rm -rf "$PROJECT_DIR/dist"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/Fonts"

# Copy executable
cp "$PROJECT_DIR/.build/release/ASCIIKeyboard" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "$PROJECT_DIR/ASCIIKeyboard/Info.plist" "$APP_BUNDLE/Contents/"

# Copy fonts
cp "$PROJECT_DIR/ASCIIKeyboard/Resources/Fonts/"*.flf "$APP_BUNDLE/Contents/Resources/Fonts/"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo ""
echo "=== App bundle created at: $APP_BUNDLE ==="
echo ""

# Check for code signing identity
SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F'"' '{print $2}')

if [ -n "$SIGNING_IDENTITY" ]; then
    echo "Found signing identity: $SIGNING_IDENTITY"
    echo "Code signing..."
    codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
    echo "Code signing complete!"
    
    echo ""
    echo "To notarize the app, run:"
    echo "  xcrun notarytool submit \"$APP_BUNDLE\" --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --password YOUR_APP_PASSWORD --wait"
    echo ""
    echo "After notarization, staple the ticket:"
    echo "  xcrun stapler staple \"$APP_BUNDLE\""
else
    echo "WARNING: No Developer ID signing identity found."
    echo "The app will not be notarized and users will see security warnings."
    echo ""
    echo "To sign the app, you need:"
    echo "1. Apple Developer Program membership (\$99/year)"
    echo "2. Developer ID Application certificate"
    echo ""
fi

# Create DMG
echo "Creating DMG..."
DMG_PATH="$PROJECT_DIR/dist/$APP_NAME-$VERSION.dmg"
rm -f "$DMG_PATH"

# Create temp folder for DMG contents
DMG_TEMP="$PROJECT_DIR/dist/dmg_temp"
mkdir -p "$DMG_TEMP"
cp -R "$APP_BUNDLE" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DMG_PATH"
rm -rf "$DMG_TEMP"

echo ""
echo "=== Build Complete ==="
echo "App Bundle: $APP_BUNDLE"
echo "DMG: $DMG_PATH"
echo ""
echo "To test the app:"
echo "  open \"$APP_BUNDLE\""
