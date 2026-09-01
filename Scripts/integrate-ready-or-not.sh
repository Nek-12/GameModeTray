#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
READY_OR_NOT_APP="${1:-$HOME/Applications/Ready or Not.app}"
LAUNCHER="$READY_OR_NOT_APP/Contents/MacOS/wineskinlauncher"
PORTING_KIT_LAUNCHER="$READY_OR_NOT_APP/Contents/MacOS/wineskinlauncher.porting-kit"
WRAPPER="$ROOT/Resources/ready-or-not-launcher-wrapper.sh"
MARKER="GAME_MODE_TRAY_READY_OR_NOT_WRAPPER=1"
LEGACY_BACKUP="$READY_OR_NOT_APP/Contents/MacOS/wineskinlauncher.before-game-mode-tray"

is_valid_porting_kit_launcher() {
    [ -s "$1" ] && [ -x "$1" ] && ! grep -q "$MARKER" "$1"
}

if [ ! -f "$LAUNCHER" ]; then
    echo "Ready or Not launcher not found: $LAUNCHER" >&2
    exit 1
fi

if grep -q "$MARKER" "$LAUNCHER"; then
    if ! is_valid_porting_kit_launcher "$PORTING_KIT_LAUNCHER"; then
        if is_valid_porting_kit_launcher "$LEGACY_BACKUP"; then
            /usr/bin/ditto "$LEGACY_BACKUP" "$PORTING_KIT_LAUNCHER"
        else
            echo "The original Porting Kit launcher is missing or invalid: $PORTING_KIT_LAUNCHER" >&2
            echo "Restore the wrapper through Porting Kit, then run this integration again." >&2
            exit 1
        fi
    fi
else
    /usr/bin/ditto "$LAUNCHER" "$PORTING_KIT_LAUNCHER"
fi

if ! is_valid_porting_kit_launcher "$PORTING_KIT_LAUNCHER"; then
    echo "Refusing to install a wrapper without a valid Porting Kit launcher." >&2
    exit 1
fi

/usr/bin/ditto "$WRAPPER" "$LAUNCHER"
chmod +x "$LAUNCHER" "$PORTING_KIT_LAUNCHER"

echo "Integrated Game Mode Tray with $READY_OR_NOT_APP"
