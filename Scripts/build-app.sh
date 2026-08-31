#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
APP="$ROOT/dist/Game Mode Tray.app"

cd "$ROOT"
swift build -c release

mkdir -p "$APP/Contents/MacOS"
/usr/bin/ditto "$ROOT/.build/release/GameModeTray" "$APP/Contents/MacOS/GameModeTray"
/usr/bin/ditto "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
/usr/bin/codesign --force --deep --sign - "$APP"

echo "$APP"
