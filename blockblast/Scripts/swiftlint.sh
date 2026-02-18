#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if command -v swiftlint >/dev/null 2>&1; then
  echo "Running swiftlint..."
  swiftlint --strict
else
  echo "swiftlint not found; running compiler-based lint fallback..."
  if command -v xcpretty >/dev/null 2>&1; then
    xcodebuild \
      -project blockblast.xcodeproj \
      -scheme blockblast \
      -configuration Debug \
      -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
      clean build \
      | xcpretty
  else
    xcodebuild \
      -project blockblast.xcodeproj \
      -scheme blockblast \
      -configuration Debug \
      -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
      clean build
  fi
fi
