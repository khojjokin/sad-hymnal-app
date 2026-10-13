#!/bin/bash
# Builds the iPhone app with Xcode and uploads it to TestFlight, signed automatically with the App Store
# Connect API key (Xcode makes or reuses the distribution certificate and profile itself).
# Needs: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, BUILD_NUMBER. Logs go to $LOG_DIR.
set -u
LOG_DIR="${LOG_DIR:-$RUNNER_TEMP/logs}"
mkdir -p "$LOG_DIR"
S="$LOG_DIR/status.txt"
TEAM=QRMLKZR9B8
ARCHIVE="$RUNNER_TEMP/SDAHymnal.xcarchive"
say() { echo "$*" | tee -a "$S"; }
finish() { say "RESULT: $1"; say "finished $(date -u +%FT%TZ)"; exit "$2"; }
keep() { # every error line, then the last 250 lines
  { echo "=== errors"; grep -n -E "error:|Error:|\*\* .* FAILED|ERROR ITMS|Provisioning|signing|Signing" "$1" | tail -120; echo "=== tail"; tail -250 "$1"; } > "$2" 2>/dev/null
}

say "testflight started $(date -u +%FT%TZ) at $(git rev-parse --short HEAD), build $BUILD_NUMBER"
xcodebuild -version >> "$S" 2>&1

# 1. The bundle ID and the app in App Store Connect, before spending half an hour building.
python3 scripts/asc.py prepare > "$LOG_DIR/asc.log" 2>&1
code=$?; cat "$LOG_DIR/asc.log" >> "$S"
[ $code -eq 2 ] && finish "STOPPED (create the app in App Store Connect first: see above)" 2
[ $code -ne 0 ] && finish "FAILED (App Store Connect: see above)" $code

# 2. Packages and the Xcode project.
npm install --no-audit --no-fund > "$LOG_DIR/npm-install.log" 2>&1
code=$?; say "npm install: $code"
[ $code -ne 0 ] && finish "FAILED (packages did not install: see npm-install.log)" $code

CI=1 npx expo prebuild --platform ios --clean > "$LOG_DIR/prebuild.log" 2>&1
code=$?; say "expo prebuild: $code"
[ $code -ne 0 ] && finish "FAILED (the Xcode project was not made: see prebuild.log)" $code
WS=$(ls -d ios/*.xcworkspace 2>/dev/null | head -1)
[ -n "$WS" ] || finish "FAILED (CocoaPods did not install: see the end of prebuild.log)" 1
SCHEME=$(basename "$WS" .xcworkspace)
say "workspace $WS, scheme $SCHEME"

AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")

# 3. Archive, signed automatically.
xcodebuild -workspace "$WS" -scheme "$SCHEME" -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" archive "${AUTH[@]}" \
  DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic CURRENT_PROJECT_VERSION="$BUILD_NUMBER" COMPILER_INDEX_STORE_ENABLE=NO \
  > "$RUNNER_TEMP/archive.full.log" 2>&1
code=$?; keep "$RUNNER_TEMP/archive.full.log" "$LOG_DIR/archive.log"; say "archive: $code"
if [ $code -ne 0 ]; then
  # A missing iOS platform on a fresh Xcode is the one failure worth a second try.
  if grep -q "iOS .* is not installed\|platform .* not installed" "$RUNNER_TEMP/archive.full.log"; then
    xcodebuild -downloadPlatform iOS > "$LOG_DIR/download-platform.log" 2>&1
    xcodebuild -workspace "$WS" -scheme "$SCHEME" -configuration Release -destination 'generic/platform=iOS' \
      -archivePath "$ARCHIVE" archive "${AUTH[@]}" \
      DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic CURRENT_PROJECT_VERSION="$BUILD_NUMBER" COMPILER_INDEX_STORE_ENABLE=NO \
      > "$RUNNER_TEMP/archive2.full.log" 2>&1
    code=$?; keep "$RUNNER_TEMP/archive2.full.log" "$LOG_DIR/archive-2.log"; say "archive (after downloading iOS): $code"
  fi
  [ $code -ne 0 ] && finish "FAILED (the app did not build or sign: see archive.log)" $code
fi

# 4. Export and upload to App Store Connect in one step.
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist scripts/ExportOptions.plist \
  -exportPath "$RUNNER_TEMP/export" "${AUTH[@]}" > "$RUNNER_TEMP/upload.full.log" 2>&1
code=$?; keep "$RUNNER_TEMP/upload.full.log" "$LOG_DIR/upload.log"; say "upload: $code"
[ $code -ne 0 ] && finish "FAILED (built, but the upload was refused: see upload.log)" $code
finish "uploaded build $BUILD_NUMBER to App Store Connect. It shows in TestFlight once Apple has processed it (usually 5 to 30 minutes)." 0
