#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
./test.sh
./build.sh --universal
APP="build/BatteryTime.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
codesign --verify --strict "$APP"
architectures=" $(xcrun lipo -archs "$APP/Contents/MacOS/BatteryTime") "
[[ "$architectures" == *" arm64 "* && "$architectures" == *" x86_64 "* ]]
mkdir -p build/release
archive="BatteryTime-v${version}-universal.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "build/release/$archive"
(cd build/release && shasum -a 256 "$archive" > SHA256SUMS.txt)
printf 'Release: %s/build/release/%s\n' "$PWD" "$archive"
