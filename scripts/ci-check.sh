#!/bin/bash
# Installs packages, type-checks and bundles the app for iPhone and Android. Logs go to $LOG_DIR.
set -u
LOG_DIR="${LOG_DIR:-$RUNNER_TEMP/logs}"
mkdir -p "$LOG_DIR"
S="$LOG_DIR/status.txt"
echo "check started $(date -u +%FT%TZ) at $(git rev-parse --short HEAD)" > "$S"
node -v >> "$S"; npm -v >> "$S"

npm install --no-audit --no-fund > "$LOG_DIR/npm-install.log" 2>&1
code=$?; echo "npm install: $code" >> "$S"
[ $code -ne 0 ] && { echo "RESULT: FAILED (packages did not install: see npm-install.log)" >> "$S"; exit $code; }
cp package-lock.json "$LOG_DIR/package-lock.json" 2>/dev/null || true

npx expo install --check > "$LOG_DIR/expo-check.log" 2>&1
echo "expo install --check: $? (versions Expo expects; not fatal)" >> "$S"

npx tsc --noEmit > "$LOG_DIR/tsc.log" 2>&1
tsc_code=$?; echo "tsc: $tsc_code" >> "$S"

npx expo export --platform ios --platform android --output-dir .export-check > "$LOG_DIR/export.log" 2>&1
code=$?; echo "expo export: $code" >> "$S"

# The bundler strips types without checking them, so a type error still bundles: stop on it anyway.
[ $code -eq 0 ] && [ $tsc_code -ne 0 ] && code=$tsc_code
if [ $code -eq 0 ]; then echo "RESULT: OK" >> "$S"; else echo "RESULT: FAILED (see tsc.log and export.log)" >> "$S"; fi
exit $code
