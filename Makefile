.PHONY: build test app install

build:
	swift build

test:
	swift test

app:
	./Scripts/build-app.sh

install: app
	mkdir -p "$(HOME)/Applications"
	/usr/bin/ditto "dist/Game Mode Tray.app" "$(HOME)/Applications/Game Mode Tray.app"
