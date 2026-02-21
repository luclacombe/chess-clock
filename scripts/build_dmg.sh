#!/usr/bin/env bash
# build_dmg.sh — Build ChessClock.app and package as a distributable DMG
# Usage: bash scripts/build_dmg.sh
# Output: dist/ChessClock-{version}.dmg

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$REPO_ROOT/ChessClock/ChessClock.xcodeproj"
SCHEME="ChessClock"
VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.2.0")
BUILD_DIR="$REPO_ROOT/dist"
ARCHIVE_PATH="$BUILD_DIR/ChessClock.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_NAME="ChessClock"
DMG_NAME="ChessClock-$VERSION"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
STAGING_DIR="$BUILD_DIR/dmg_staging"

echo "==> Cleaning previous build artifacts..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$BUILD_DIR"

echo "==> Archiving $SCHEME..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=macOS" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tail -5

echo "==> Exporting .app..."
cat > /tmp/exportOptions.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>destination</key>
  <string>export</string>
</dict>
</plist>
PLIST

# Try developer-id export; fall back to direct .app copy if unsigned
if xcodebuild -exportArchive \
     -archivePath "$ARCHIVE_PATH" \
     -exportOptionsPlist /tmp/exportOptions.plist \
     -exportPath "$EXPORT_PATH" \
     2>&1 | tail -5; then
  APP_PATH="$EXPORT_PATH/$APP_NAME.app"
else
  echo "  (developer-id export failed — copying .app directly from archive)"
  APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
fi

echo "==> Staging DMG contents..."
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating DMG..."
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo ""
echo "✓ DMG created: $DMG_PATH"
echo "  $(du -sh "$DMG_PATH" | cut -f1)"
