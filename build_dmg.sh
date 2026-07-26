#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/stage"
DMG_PATH="$DIST_DIR/Translator.dmg"

cd "$ROOT_DIR"
./build_app.sh

rm -rf "$DIST_DIR"
mkdir -p "$STAGE_DIR"

cp -R "$ROOT_DIR/Translator.app" "$STAGE_DIR/Translator.app"
cp "$ROOT_DIR/README.md" "$STAGE_DIR/README.md"
cp "$ROOT_DIR/LICENSE" "$STAGE_DIR/LICENSE"

hdiutil create \
    -volname "Translator" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGE_DIR"
echo "DMG created: $DMG_PATH"
