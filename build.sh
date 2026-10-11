#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

APP=murmur.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" "$APP/Contents/Resources"
cp "$BIN_DIR/murmur" "$APP/Contents/MacOS/murmur"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>murmur</string>
	<key>CFBundleIdentifier</key><string>dev.arjun.murmur</string>
	<key>CFBundleName</key><string>murmur</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>0.1</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>LSUIElement</key><true/>
	<key>NSMicrophoneUsageDescription</key><string>murmur records your voice to transcribe it locally.</string>
</dict>
</plist>
PLIST

# resource bundles (e.g. KeyboardShortcuts_KeyboardShortcuts.bundle)
for b in "$BIN_DIR"/*.bundle; do
  [ -e "$b" ] && cp -R "$b" "$APP/Contents/Resources/"
done

# bundle the speech model so the app is self-contained
if [ -f models/ggml-base.en.bin ]; then
  cp models/ggml-base.en.bin "$APP/Contents/Resources/"
else
  echo "warning: models/ggml-base.en.bin missing, app will not find a model (run scripts/fetch-deps.sh)" >&2
fi

# embed whisper framework
FW_SRC=vendor/xcframework/unpacked/build-apple/whisper.xcframework/macos-arm64_x86_64/whisper.framework
cp -R "$FW_SRC" "$APP/Contents/Frameworks/"
if ! otool -l "$APP/Contents/MacOS/murmur" | grep -q "@executable_path/../Frameworks"; then
  install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/murmur"
fi

# Sign with the "murmur-dev" certificate when present, else ad hoc (Accessibility must then be granted again after each rebuild).
SIGN_ID="${MURMUR_SIGN_ID:-murmur-dev}"
security find-identity -v -p codesigning | grep -q "$SIGN_ID" || SIGN_ID=-
codesign --force --deep -s "$SIGN_ID" "$APP"
echo "$(pwd)/$APP"

# ./build.sh --dist  ->  dist/murmur-<version>-arm64.zip (ready to share)
if [ "${1:-}" = "--dist" ]; then
  mkdir -p dist
  VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
  OUT="dist/murmur-$VERSION-arm64.zip"
  rm -f "$OUT"
  ditto -c -k --norsrc --noextattr --keepParent "$APP" "$OUT"
  echo "$(pwd)/$OUT"
fi
