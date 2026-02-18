#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${SCHEME:-blockblast}"
CONFIGURATION="${CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/blockblast.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/export}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$ROOT_DIR/build/ExportOptions.plist}"

mkdir -p "$ROOT_DIR/build"

if [[ ! -f "$EXPORT_OPTIONS_PLIST" ]]; then
  cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>uploadSymbols</key>
  <true/>
  <key>compileBitcode</key>
  <false/>
</dict>
</plist>
PLIST
fi

xcodebuild \
  -project blockblast.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  clean archive

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

echo "IPA exported to $EXPORT_PATH"
