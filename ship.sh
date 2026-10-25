#!/bin/bash
# Builds SDA Hymnal and uploads it to TestFlight using the Apple account signed in to Xcode.
# Usage:  ./ship.sh            (or TEAM_ID=ABCDE12345 ./ship.sh)
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p build
LOG=build/ship.log
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

TEAM_ID="${TEAM_ID:-QRMLKZR9B8}"
if [ -z "$TEAM_ID" ]; then
  for a in $(ls -td ~/Library/Developer/Xcode/Archives/*/*.xcarchive 2>/dev/null); do
    TEAM_ID=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:Team" "$a/Info.plist" 2>/dev/null || true)
    [ -n "$TEAM_ID" ] && break
  done
fi
if [ -z "$TEAM_ID" ]; then
  echo "❌ Couldn't find your Team ID. Run:  TEAM_ID=<your 10-char team id> ./ship.sh"; exit 1
fi
echo "▶ Team: $TEAM_ID"

BUILD=$(date +%y%m%d%H%M)
echo "▶ Archiving SDA Hymnal build $BUILD …"
rm -rf build/SDAHymnal.xcarchive build/export
xcodebuild -project SDAHymnal.xcodeproj -scheme SDAHymnal -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/SDAHymnal.xcarchive \
  DEVELOPMENT_TEAM="$TEAM_ID" CURRENT_PROJECT_VERSION="$BUILD" \
  -allowProvisioningUpdates archive > build/archive.log 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Archive failed. Errors:"; grep -E "error:|warning: .*fatal" build/archive.log | head -40; exit 1
fi
echo "✅ Archive OK"

cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST

echo "▶ Uploading to App Store Connect …"
xcodebuild -exportArchive -archivePath build/SDAHymnal.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates > build/upload.log 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Upload failed:"; grep -iE "error|fail" build/upload.log | head -30; exit 1
fi
echo "🚀 Uploaded build $BUILD. It will appear in TestFlight after Apple finishes processing (5–30 min)."
