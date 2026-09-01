#!/bin/sh
# GAME_MODE_TRAY_READY_OR_NOT_WRAPPER=1
set -u

LAUNCHER_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PORTING_KIT_LAUNCHER="$LAUNCHER_DIR/wineskinlauncher.porting-kit"
GAME_MODE_TRAY="$HOME/Applications/Game Mode Tray.app/Contents/MacOS/GameModeTray"
SESSION_OWNER="ready-or-not-$$"
MANAGES_GAMING_SESSION=0

restore_gaming_session() {
    if [ "$MANAGES_GAMING_SESSION" -eq 1 ]; then
        "$GAME_MODE_TRAY" --stop-session "$SESSION_OWNER" ||
            echo "Warning: Game Mode Tray could not restore the Ready or Not session." >&2
    fi
}

trap restore_gaming_session EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [ -x "$GAME_MODE_TRAY" ]; then
    if "$GAME_MODE_TRAY" --start-session "$SESSION_OWNER" --process-id "$$"; then
        MANAGES_GAMING_SESSION=1
    else
        echo "Warning: Game Mode Tray could not start; launching Ready or Not without managed gaming settings." >&2
    fi
else
    echo "Warning: Game Mode Tray is not installed; launching Ready or Not without managed gaming settings." >&2
fi

"$PORTING_KIT_LAUNCHER" "$@"
exit $?
