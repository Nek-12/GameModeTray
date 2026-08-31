# Game Mode Tray

Game Mode Tray is a macOS menu bar app that forces Game Mode on for the duration of a gaming session. It can also suppress Hot Corners during the session and restores the previous Game Mode policy and Hot Corner configuration when the session stops or the app quits.

The app uses Apple's `gamepolicyctl` command from Xcode. It requires an Xcode installation that provides this command and is tested with Xcode 27 on macOS 27.

## Install

```sh
git clone https://github.com/Nek-12/GameModeTray.git
cd GameModeTray
make install
open "$HOME/Applications/Game Mode Tray.app"
```

The gaming session starts when the app opens. Use the controller icon in the menu bar to stop or restart the session, toggle Hot Corner suppression, or quit.

If the app is force-quit or crashes, open it again and quit normally to restore the settings saved before the gaming session.

The bundled executable also supports session-scoped automation:

```sh
"$HOME/Applications/Game Mode Tray.app/Contents/MacOS/GameModeTray" --start-session my-game
# Run the game.
"$HOME/Applications/Game Mode Tray.app/Contents/MacOS/GameModeTray" --stop-session my-game
```

Each owner keeps the shared gaming session active until that owner stops. Concurrent games and the menu bar app cannot restore each other's settings.

## Ready or Not with Porting Kit

Install the app, then wrap the Ready or Not launcher:

```sh
make install
./Scripts/integrate-ready-or-not.sh
```

The wrapper starts a `ready-or-not` session before Porting Kit launches the game and stops it after the Porting Kit launcher exits. Run the integration command again whenever Porting Kit replaces the launcher.

## Build

```sh
make test
make app
```

The app bundle is written to `dist/Game Mode Tray.app`.

## License

MIT
