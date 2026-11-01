#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if ! xcrun --find clang >/dev/null 2>&1; then
  echo 'Need Xcode Command Line Tools: xcode-select --install' >&2
  exit 1
fi
APP="$PWD/build/WeTypeTouchBarBridge.app"
mkdir -p "$APP/Contents/MacOS"
# Stop old process before replacing app to avoid stale code and UI registration.
pkill -x WeTypeTouchBarBridge 2>/dev/null || true
xcrun clang -fobjc-arc -fmodules -mmacosx-version-min=11.0 -O2 -Wall -Wextra \
  -framework Cocoa -framework ApplicationServices -framework Carbon \
  main.m -o "$APP/Contents/MacOS/WeTypeTouchBarBridge"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built: $APP"
echo 'Open System Settings > Privacy & Security > Accessibility and enable this app.'
open "$APP"