#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_DISPLAY="Claude FM"
BUNDLE="ClaudeFM.app"
DMG="ClaudeFM.dmg"
BINARY="ClaudeFMWidget"
TEMP_DMG="temp_claudefm.dmg"

# ── 1. Build ──────────────────────────────────────────────────────────────────
echo "▶ Building release binary..."
swift build -c release

# ── 2. App bundle ────────────────────────────────────────────────────────────
echo "▶ Assembling .app bundle..."
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

cp ".build/release/$BINARY" "$BUNDLE/Contents/MacOS/$BINARY"

# Generate icon (requires Pillow: pip3 install pillow)
if python3 -c "import PIL" 2>/dev/null; then
    python3 create_icon.py
    cp AppIcon.icns "$BUNDLE/Contents/Resources/AppIcon.icns"
fi

cat > "$BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>   <string>Claude FM</string>
    <key>CFBundleExecutable</key>    <string>ClaudeFMWidget</string>
    <key>CFBundleIconFile</key>      <string>AppIcon</string>
    <key>CFBundleIdentifier</key>    <string>com.claudefm.widget</string>
    <key>CFBundleName</key>          <string>Claude FM</string>
    <key>CFBundlePackageType</key>   <string>APPL</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundleVersion</key>       <string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key>           <true/>
    <key>NSPrincipalClass</key>      <string>NSApplication</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key><true/>
    </dict>
</dict>
</plist>
PLIST

# ── 3. Sign (ad-hoc) ─────────────────────────────────────────────────────────
echo "▶ Ad-hoc signing..."
codesign --force --deep --sign - "$BUNDLE"

# ── 4. DMG ───────────────────────────────────────────────────────────────────
echo "▶ Building DMG..."
rm -f "$DMG" "$TEMP_DMG"

hdiutil create -size 60m -fs HFS+ -volname "$APP_DISPLAY" "$TEMP_DMG" -quiet
# hdiutil output is tab-delimited; the mount path is the 3rd tab field on the HFS+ line
MOUNT=$(hdiutil attach "$TEMP_DMG" -nobrowse | awk -F'\t' '/Apple_HFS/{print $NF}')

cp -R "$BUNDLE" "$MOUNT/"
ln -s /Applications "$MOUNT/Applications"

# Tidy up any .DS_Store noise before compressing
sync
hdiutil detach "$MOUNT" -quiet
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG" -quiet
rm -f "$TEMP_DMG"

echo ""
echo "✅  $DMG is ready  ($(du -sh "$DMG" | cut -f1))"
echo ""
echo "─────────────────────────────────────────────────"
echo " Sharing notes"
echo "─────────────────────────────────────────────────"
echo " Anyone on macOS 13+ can use it."
echo ""
echo " First-launch: right-click the app → Open"
echo " (Gatekeeper blocks unsigned apps by default.)"
echo ""
echo " Or have recipients run once in Terminal:"
echo "   xattr -rd com.apple.quarantine /Applications/ClaudeFM.app"
echo ""
echo " For fully frictionless distribution (no Gatekeeper"
echo " warning at all) you'd need an Apple Developer ID"
echo " certificate (\$99/yr) and notarization via notarytool."
echo "─────────────────────────────────────────────────"
