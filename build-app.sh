#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Murchi"
APP_DIR="$DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building $APP_NAME.app..."

# Clean
rm -rf "$APP_DIR"

# Create bundle structure
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Compile
echo "Compiling..."
swiftc "$DIR/Murchi.swift" \
    -framework AppKit \
    -framework Foundation \
    -framework AVFoundation \
    -framework Carbon \
    -framework UserNotifications \
    -o "$MACOS/$APP_NAME" \
    -swift-version 5 \
    -O \
    2>&1

# Create Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Murchi</string>
    <key>CFBundleDisplayName</key>
    <string>Murchi</string>
    <key>CFBundleIdentifier</key>
    <string>com.murchi.tamagotchi</string>
    <key>CFBundleVersion</key>
    <string>2.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleExecutable</key>
    <string>Murchi</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
PLIST

# Generate icon if needed
if [ ! -f "$DIR/AppIcon.icns" ]; then
    echo "Generating icon..."
    swiftc "$DIR/generate-icon.swift" -framework AppKit -framework Foundation -o "$DIR/gen-icon" -swift-version 5 2>/dev/null
    cd "$DIR" && ./gen-icon && rm -f gen-icon
fi

# Copy icon
cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns" 2>/dev/null || true

echo "Created $APP_NAME.app"
echo ""
echo "To run: open $APP_DIR"
echo ""

# Build DMG
DMG_NAME="$APP_NAME.dmg"
DMG_PATH="$DIR/$DMG_NAME"
STAGING="$DIR/.dmg-staging"

echo "Building DMG..."

rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"

# Create Applications symlink
ln -s /Applications "$STAGING/Applications"

# Build DMG
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" 2>/dev/null

rm -rf "$STAGING"

echo "Created $DMG_NAME"
echo ""
echo "Done! Your Murchi is ready!"
echo "  App:  $APP_DIR"
echo "  DMG:  $DMG_PATH"
