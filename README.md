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
"$HOME/Applications/Game Mode Tray.app/Contents/MacOS/GameModeTray" --start-session
# Run the game.
"$HOME/Applications/Game Mode Tray.app/Contents/MacOS/GameModeTray" --stop-session
```

## Build

```sh
make test
make app
```

The app bundle is written to `dist/Game Mode Tray.app`.

## License

MIT
