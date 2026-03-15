#!/bin/bash
set -euo pipefail

SCHEME="Broom"
CONFIGURATION="Release"
ARCHIVE_PATH="build/Broom.xcarchive"
EXPORT_PATH="build"
DMG_NAME="Broom.dmg"

echo "==> Generating Xcode project..."
xcodegen generate

echo "==> Building archive..."
xcodebuild \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    archive

echo "==> Exporting app..."
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ExportOptions.plist

echo "==> Creating DMG..."
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "Broom" \
        --window-size 600 400 \
        --icon "Broom.app" 150 190 \
        --app-drop-link 450 190 \
        "$DMG_NAME" \
        "$EXPORT_PATH/Broom.app"
    echo "==> DMG created: $DMG_NAME"
else
    echo "==> create-dmg not found. Install with: brew install create-dmg"
    echo "==> App is available at: $EXPORT_PATH/Broom.app"
fi
