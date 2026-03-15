#!/bin/bash
set -euo pipefail

# Usage: ./scripts/notarize.sh Broom.dmg
# Requires: APPLE_ID, TEAM_ID, and APP_PASSWORD environment variables

DMG_PATH="${1:?Usage: notarize.sh <path-to-dmg>}"

if [[ -z "${APPLE_ID:-}" || -z "${TEAM_ID:-}" || -z "${APP_PASSWORD:-}" ]]; then
    echo "Error: Set APPLE_ID, TEAM_ID, and APP_PASSWORD environment variables"
    exit 1
fi

echo "==> Submitting for notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "==> Done. DMG is notarized and stapled."
