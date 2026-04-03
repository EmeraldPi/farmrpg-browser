#!/bin/bash
set -e

APP_NAME="FarmRPG Browser"
BUNDLE_ID="com.farmrpg.browser"
EXECUTABLE="FarmRPGBrowser"
APP_DIR="${APP_NAME}.app"

echo "Building release binary..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp ".build/release/${EXECUTABLE}" "${APP_DIR}/Contents/MacOS/${EXECUTABLE}"

cat > "${APP_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>FarmRPG Browser</string>
    <key>CFBundleDisplayName</key>
    <string>FarmRPG Browser</string>
    <key>CFBundleIdentifier</key>
    <string>com.farmrpg.browser</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>FarmRPGBrowser</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
PLIST

echo "Done! Created ${APP_DIR}"
echo ""
echo "To install: cp -r \"${APP_DIR}\" /Applications/"
echo "To open:    open \"${APP_DIR}\""
