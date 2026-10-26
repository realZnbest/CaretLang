#!/bin/bash
# Build CaretLang.app into ./build
#   ./build.sh            build only
#   ./build.sh --install  also copy to ~/Applications and launch
#   ./build.sh --release  also zip it to build/CaretLang-<version>.zip
set -euo pipefail
cd "$(dirname "$0")"

APP=build/CaretLang.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Universal binary: Apple silicon + Intel
for arch in arm64 x86_64; do
    swiftc -O -target "$arch-apple-macos14" -o "build/CaretLang-$arch" Sources/main.swift
done
lipo -create build/CaretLang-arm64 build/CaretLang-x86_64 -output "$APP/Contents/MacOS/CaretLang"
rm build/CaretLang-arm64 build/CaretLang-x86_64

cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cp -R Resources/flags "$APP/Contents/Resources/flags"

# Strip extended attributes so the zip carries no ._ files that break the signature
xattr -cr "$APP"

# Ad-hoc sign with an identifier-only requirement so the Accessibility
# permission survives rebuilds.
codesign --force -s - -r='designated => identifier "com.znbest.CaretLang"' "$APP"
echo "Built $APP"

case "${1:-}" in
--install)
    pkill -x CaretLang || true
    mkdir -p ~/Applications
    rm -rf ~/Applications/CaretLang.app
    cp -R "$APP" ~/Applications/
    open ~/Applications/CaretLang.app
    echo "Installed to ~/Applications/CaretLang.app"
    ;;
--release)
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
    ZIP="build/CaretLang-$VERSION.zip"
    rm -f "$ZIP"
    ditto -c -k --norsrc --noextattr --noqtn --keepParent "$APP" "$ZIP"
    echo "Packed $ZIP"
    ;;
esac
