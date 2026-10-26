#!/bin/bash
# Build CaretLang.app into ./build (pass --install to copy it to ~/Applications and launch)
set -euo pipefail
cd "$(dirname "$0")"

APP=build/CaretLang.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -o "$APP/Contents/MacOS/CaretLang" Sources/main.swift
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp -R Resources/flags "$APP/Contents/Resources/flags"

# Ad-hoc sign with an identifier-only requirement so the Accessibility
# permission survives rebuilds.
codesign --force -s - -r='designated => identifier "com.znbest.CaretLang"' "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x CaretLang || true
    mkdir -p ~/Applications
    rm -rf ~/Applications/CaretLang.app
    cp -R "$APP" ~/Applications/
    open ~/Applications/CaretLang.app
    echo "Installed to ~/Applications/CaretLang.app"
fi
