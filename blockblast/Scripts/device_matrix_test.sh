#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_ID="$(date +%Y%m%d-%H%M%S)"

DESTINATIONS=(
  "platform=iOS Simulator,name=iPhone 16e,OS=18.4"
  "platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.4"
  "platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=18.4"
)

for DEST in "${DESTINATIONS[@]}"; do
  echo "Running tests on: $DEST"
  RESULT_BUNDLE="build/TestResult-${RUN_ID}-$(echo "$DEST" | tr ' ,()=' '-----').xcresult"
  rm -rf "$RESULT_BUNDLE"

  xcodebuild \
    -project blockblast.xcodeproj \
    -scheme blockblast \
    -destination "$DEST" \
    -resultBundlePath "$RESULT_BUNDLE" \
    test

done

echo "Device matrix test run complete."
