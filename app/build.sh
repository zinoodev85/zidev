#!/bin/sh
# Builds zidev.app (its own window and Dock icon for zidev) into build/, signed for this Mac only
# (no Apple developer account: macOS runs apps you built yourself without asking).
# ./build.sh icon  redraws zidev.icns from icon.swift first.
set -e
cd "$(dirname "$0")"
if [ "$1" = icon ]; then
  rm -rf build/zidev.iconset && mkdir -p build/zidev.iconset
  swift icon.swift build/icon.png
  for s in 16 32 128 256 512; do
    sips -z $s $s build/icon.png --out build/zidev.iconset/icon_${s}x${s}.png >/dev/null
    sips -z $((s * 2)) $((s * 2)) build/icon.png --out build/zidev.iconset/icon_${s}x${s}@2x.png >/dev/null
  done
  iconutil -c icns build/zidev.iconset -o zidev.icns
fi
swift build -c release --disable-sandbox  # no nested sandbox: brew builds in one
rm -rf build/zidev.app
mkdir -p build/zidev.app/Contents/MacOS build/zidev.app/Contents/Resources
cp .build/release/zidev-app build/zidev.app/Contents/MacOS/zidev
cp zidev.icns build/zidev.app/Contents/Resources/zidev.icns
VERSION=$(sed -n 's/^VERSION = "\(.*\)"/\1/p' ../zidev)
cat > build/zidev.app/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>zidev</string>
  <key>CFBundleDisplayName</key><string>zidev</string>
  <key>CFBundleIdentifier</key><string>io.github.zinoodev85.zidev</string>
  <key>CFBundleExecutable</key><string>zidev</string>
  <key>CFBundleIconFile</key><string>zidev</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - build/zidev.app
echo "built $(pwd)/build/zidev.app"
