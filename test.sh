#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
xcrun swiftc -module-cache-path build/ModuleCache Sources/ScreenTime.swift Sources/Presentation.swift Tests/main.swift -o build/ScreenTimeTests
build/ScreenTimeTests
