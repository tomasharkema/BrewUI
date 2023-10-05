#!/bin/sh

# for BrewDesign

# swift build -Xswiftc "-sdk" -Xswiftc "$(xcrun --sdk macosx --show-sdk-path)" -Xswiftc "-target" -Xswiftc "arm64-apple-macosx14.0"

set -e

ARCH="arm64"
SDK="macosx"
SDK_VERSION="14.0"
CONFIGURATION="release"

SWIFT_COMBINED="$ARCH-apple-$SDK"

# DERIVED_SOURCES=".build/$SWIFT_COMBINED/$CONFIGURATION/BrewDesign.build/DerivedSources"
DERIVED_SOURCES="./Sources/BrewDesign/DerivedSources"

# /Applications/Xcode.app/Contents/Developer/usr/bin/actool \
# 	--output-format human-readable-text \
# 	--notices --warnings \
# 	--export-dependency-info .build/$SWIFT_COMBINED/$CONFIGURATION/BrewDesign.build/assetcatalog_dependencies \
# 	--output-partial-info-plist .build/$SWIFT_COMBINED/$CONFIGURATION/BrewDesign.build/assetcatalog_generated_info.plist \
# 	--enable-on-demand-resources NO \
# 	--development-region en \
# 	--target-device mac \
# 	--minimum-deployment-target $SDK_VERSION \
# 	--platform $SDK \
# 	--compile Build/Products/Debug \
# 	/Users/tomas/Developer/BrewUI/BrewCore/Sources/BrewDesign/Resources/Colors.xcassets \
# 	/Users/tomas/Developer/BrewUI/BrewCore/Sources/BrewDesign/Resources/Colors.xcassets \
# 	--bundle-identifier BrewDesign \
# 	--generate-swift-asset-symbol-extensions NO \
# 	--generate-swift-asset-symbols $DERIVED_SOURCES/GeneratedAssetSymbols.swift \
# 	--generate-objc-asset-symbols $DERIVED_SOURCES/GeneratedAssetSymbols.h \
# 	--generate-asset-symbol-index $DERIVED_SOURCES/GeneratedAssetSymbols-Index.plist

swift build \
	-Xswiftc "-sdk" -Xswiftc "$(xcrun --sdk $SDK --show-sdk-path)" \
	-Xswiftc "-target" -Xswiftc "arm64-apple-$SDK$SDK_VERSION" \
	--static-swift-stdlib \
	--product BrewUISPM \
	-c $CONFIGURATION
