#!/bin/bash
# Builds and runs the App Store screenshot harness.
# Output: build/appstore/screenshots/*.png at 2880x1800.
set -euo pipefail
cd "$(dirname "$0")/../.."

mkdir -p build
swiftc -O \
    Sources/Pastry/ColorScheme.swift \
    Sources/Pastry/ClipItem.swift \
    Sources/Pastry/HistoryStore.swift \
    Sources/Pastry/HistoryView.swift \
    tools/screenshots/main.swift \
    -o build/shotter

./build/shotter
