#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

SCHEME="${SCHEME:-blockblast}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedDataLeaks}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/blockblast.app"
TRACE_PATH="${TRACE_PATH:-$ROOT_DIR/build/memory-leaks.trace}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.4}"
TIME_LIMIT="${TIME_LIMIT:-25s}"

mkdir -p "$ROOT_DIR/build"
LOG_PATH="$ROOT_DIR/build/leak-check.log"
rm -rf "$TRACE_PATH"

xcodebuild \
  -project blockblast.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at $APP_PATH" >&2
  exit 1
fi

# Instruments may fail in restricted CI/simulator environments; treat known
# authorization failure as infra warning and keep pipeline informative.
set +e
xcrun xctrace record \
  --template 'Leaks' \
  --output "$TRACE_PATH" \
  --time-limit "$TIME_LIMIT" \
  --target-stdout - \
  --launch -- "$APP_PATH" \
  2>&1 | tee "$LOG_PATH"
STATUS=${PIPESTATUS[0]}
set -e

if [[ $STATUS -ne 0 ]]; then
  if rg -q "Failed to gain authorization" "$LOG_PATH"; then
    echo "Leak check warning: xctrace authorization is unavailable in this environment."
    echo "Re-run on a local signed simulator/device session for final leak gate."
    exit 0
  fi
  exit $STATUS
fi

echo "Leak trace generated at $TRACE_PATH"
