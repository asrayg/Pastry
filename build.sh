#!/bin/bash
# Builds Pastry.app into ./build
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

# Regenerate the app icon if missing.
if [ ! -f Resources/AppIcon.icns ]; then
    swift scripts/makeicon.swift build/AppIcon.iconset
    mkdir -p Resources
    iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
    # Keep the 1024px master around for App Store Connect.
    cp build/AppIcon.iconset/icon_512x512@2x.png Resources/AppIcon-1024.png
    rm -rf build/AppIcon.iconset
fi

APP=build/Pastry.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Pastry "$APP/Contents/MacOS/Pastry"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign so the Accessibility permission grant persists across rebuilds.
codesign --force --sign - "$APP"

echo "Built $APP"
