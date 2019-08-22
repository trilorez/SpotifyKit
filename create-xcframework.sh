#!/bin/sh

IOS_ARCHIVE=build/ios/SpotifyKit.xcarchive
IOS_SIMULATOR_ARCHIVE=build/ios-simulator/SpotifyKit.xcarchive
xcodebuild archive -scheme SpotifyKit -destination="iOS" -sdk iphoneos SKIP_INSTALL=NO -archivePath $IOS_ARCHIVE
xcodebuild archive -scheme SpotifyKit -destination="iOS Simulator" -sdk iphonesimulator SKIP_INSTALL=NO -archivePath $IOS_SIMULATOR_ARCHIVE
xcodebuild -create-xcframework -framework $IOS_ARCHIVE/Products/Library/Frameworks/SpotifyKit.framework -framework $IOS_SIMULATOR_ARCHIVE/Products/Library/Frameworks/SpotifyKit.framework -output build/SpotifyKit.xcframework
