#!/bin/sh

set -e

rm -rf archive || true
rm -rf BrewUI.app.zip || true
rm -rf BrewUI.xcarchive.zip || true

xcodebuild -scheme BrewUI \
	-destination "platform=macOS" \
	-archivePath archive/BrewUI \
	-derivedDataPath /tmp/brewuiderived \
	archive 2>&1 | xcbeautify

zip -r -9 BrewUI.xcarchive.zip archive/BrewUI.xcarchive

cp -r archive/BrewUI.xcarchive/Products/Applications/BrewUI.app .

zip -r -9 BrewUI.app.zip BrewUI.app

rm -rf BrewUI.app
