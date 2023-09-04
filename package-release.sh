#!/bin/bash
#
# Package release
#
# This will build and archive the app and then compress it in a .zip file at Product/Xcodes.zip
# You must already have all required code signing assets installed on your computer

set -e
set -x

PROJECT_NAME=BrewUI
# PROJECT_DIR=$(pwd)/$PROJECT_NAME/Resources
# SCRIPTS_DIR=$(pwd)/Scripts
INFOPLIST_FILE="Info.plist"

# If needed ensure that the unxip binary is signed with a hardened runtime so we can notarize
# codesign --force --options runtime --sign "Developer ID Application: Robots and Pencils Inc." $PROJECT_DIR/unxip

# Ensure a clean build
rm -rf Archive/*
rm -rf Product/*
xcodebuild clean -project $PROJECT_NAME.xcodeproj -configuration Release -alltargets 2>&1 | xcbeautify

# Archive the app and export for release distribution
xcodebuild archive -project $PROJECT_NAME.xcodeproj -scheme $PROJECT_NAME -archivePath Archive/$PROJECT_NAME.xcarchive 2>&1 | xcbeautify
xcodebuild -archivePath Archive/$PROJECT_NAME.xcarchive -exportArchive -exportPath Product/$PROJECT_NAME -exportOptionsPlist "./export_options.plist" # 2>&1 | xcbeautify
cp -a "Product/$PROJECT_NAME/$PROJECT_NAME.app" "Product/$PROJECT_NAME.app"

# Create a ZIP archive suitable for altool.
/usr/bin/ditto -c -k --keepParent "Product/$PROJECT_NAME.app" "Product/$PROJECT_NAME.zip"
