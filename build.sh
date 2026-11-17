#!/usr/bin/env bash
# Build RoundedScreen.app
#   ./build.sh                      -> native architecture
#   UNIVERSAL=1 ./build.sh          -> arm64 + x86_64
#   VERSION=1.2.0 ./build.sh        -> stamp the app version
set -euo pipefail
cd "$(dirname "$0")"

APP="RoundedScreen.app"
FLAGS=(-c release -Xswiftc -Osize)
if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  FLAGS+=(--arch arm64 --arch x86_64)
fi

swift build "${FLAGS[@]}"
BIN="$(swift build "${FLAGS[@]}" --show-bin-path)/RoundedScreen"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/RoundedScreen"
strip -x "$APP/Contents/MacOS/RoundedScreen"
cp Info.plist "$APP/Contents/Info.plist"

if [[ -n "${VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
fi

# Ad-hoc signature (no Developer ID)
codesign --force --sign - "$APP"

echo "Done: $(pwd)/$APP"
echo "Move it to /Applications and open it. Configure 'Run at login' in the settings window."
