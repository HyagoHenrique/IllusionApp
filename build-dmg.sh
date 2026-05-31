#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/IllusionApp.xcodeproj"
SCHEME="IllusionApp"
DERIVED_DATA="$PROJECT_DIR/build/DerivedData"
RELEASE_APP="$DERIVED_DATA/Build/Products/Release/IllusionApp.app"
DMG_STAGING="/tmp/IllusionApp-dmg-staging"
DMG_OUTPUT="$PROJECT_DIR/build/IllusionApp.dmg"

echo "▸ Building Release..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)"

echo "▸ Packaging DMG..."
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -r "$RELEASE_APP" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

mkdir -p "$PROJECT_DIR/build"
rm -f "$DMG_OUTPUT"
hdiutil create \
  -volname "IllusionApp" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  -fs HFS+ \
  "$DMG_OUTPUT" \
  | grep -v "^/dev/"

rm -rf "$DMG_STAGING"

echo ""
echo "✓ Done! DMG at: $DMG_OUTPUT"
echo "▸ Opening Finder..."
open -R "$DMG_OUTPUT"
