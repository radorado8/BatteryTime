#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="build/BatteryTime.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
architectures=("$(uname -m)")
if [[ "${1:-}" == "--universal" ]]; then
    architectures=(arm64 x86_64)
fi
binaries=()
for architecture in "${architectures[@]}"; do
    binary="build/BatteryTime-$architecture"
    xcrun swiftc -module-cache-path build/ModuleCache -O -swift-version 5 -target "$architecture-apple-macosx13.0" Sources/ScreenTime.swift Sources/Presentation.swift Sources/StatusImage.swift Sources/SettingsForm.swift Sources/main.swift -o "$binary" -framework AppKit -framework IOKit -framework ServiceManagement
    binaries+=("$binary")
done
if [[ ${#binaries[@]} -gt 1 ]]; then
    xcrun lipo -create "${binaries[@]}" -output "$APP/Contents/MacOS/BatteryTime"
else
    cp "${binaries[0]}" "$APP/Contents/MacOS/BatteryTime"
fi
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.BatteryTime</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleName</key><string>BatteryTime</string>
<key>CFBundleExecutable</key><string>BatteryTime</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.5.1</string>
<key>CFBundleVersion</key><string>6</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
printf 'Hotovo: %s/%s\n' "$PWD" "$APP"
