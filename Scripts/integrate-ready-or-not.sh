#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
READY_OR_NOT_APP="${1:-$HOME/Applications/Ready or Not.app}"
LAUNCHER="$READY_OR_NOT_APP/Contents/MacOS/wineskinlauncher"
PORTING_KIT_LAUNCHER="$READY_OR_NOT_APP/Contents/MacOS/wineskinlauncher.porting-kit"
WRAPPER="$ROOT/Resources/ready-or-not-launcher-wrapper.sh"
MARKER="GAME_MODE_TRAY_READY_OR_NOT_WRAPPER=1"

if [ ! -f "$LAUNCHER" ]; then
    echo "Ready or Not launcher not found: $LAUNCHER" >&2
    exit 1
fi

if ! grep -q "$MARKER" "$LAUNCHER"; then
    /usr/bin/ditto "$LAUNCHER" "$PORTING_KIT_LAUNCHER"
fi

/usr/bin/ditto "$WRAPPER" "$LAUNCHER"
chmod +x "$LAUNCHER" "$PORTING_KIT_LAUNCHER"

echo "Integrated Game Mode Tray with $READY_OR_NOT_APP"
