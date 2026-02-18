#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v agvtool >/dev/null 2>&1; then
  echo "agvtool is required but not found." >&2
  exit 1
fi

LATEST_BUILD="$(xcrun agvtool what-version -terse 2>/dev/null | tail -n 1 | tr -d '[:space:]')"
if [[ -z "${LATEST_BUILD}" ]]; then
  LATEST_BUILD=0
fi

NEXT_BUILD=$((LATEST_BUILD + 1))

echo "Incrementing build number: ${LATEST_BUILD} -> ${NEXT_BUILD}"
xcrun agvtool new-version -all "${NEXT_BUILD}"

echo "Build number updated to ${NEXT_BUILD}".
