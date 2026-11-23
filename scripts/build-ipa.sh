#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/build/IPA"
APP_PATH="${PROJECT_DIR}/build/DeviceDerivedData/Build/Products/Release-iphoneos/ReelMind.app"

ICLOUD_ROOT="/Users/wacko87/Library/Mobile Documents/com~apple~CloudDocs"
ICLOUD_DOWNLOADS="${ICLOUD_ROOT}/Downloads"
ICLOUD_OBSIDIAN="/Users/wacko87/Library/Mobile Documents/iCloud~md~obsidian/Documents/Apps Xcode"

echo "==> 1. Compiling ReelMind for iOS Device (Release)..."
xcodebuild -project "${PROJECT_DIR}/ReelMind.xcodeproj" \
    -scheme ReelMind \
    -destination 'generic/platform=iOS' \
    -configuration Release \
    -derivedDataPath "${PROJECT_DIR}/build/DeviceDerivedData" \
    build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO

echo "==> 2. Packaging into IPA archive..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/Payload"
cp -R "${APP_PATH}" "${OUTPUT_DIR}/Payload/"

cd "${OUTPUT_DIR}"
zip -r -q "ReelMind.ipa" Payload/
rm -rf Payload/

echo "==> 3. Distributing ReelMind.ipa to iCloud Drive..."
if [ -d "${ICLOUD_ROOT}" ]; then
    cp "${OUTPUT_DIR}/ReelMind.ipa" "${ICLOUD_ROOT}/ReelMind.ipa"
    echo "  -> Copied to iCloud Root: ${ICLOUD_ROOT}/ReelMind.ipa"
fi

if [ -d "${ICLOUD_DOWNLOADS}" ]; then
    cp "${OUTPUT_DIR}/ReelMind.ipa" "${ICLOUD_DOWNLOADS}/ReelMind.ipa"
    echo "  -> Copied to iCloud Downloads: ${ICLOUD_DOWNLOADS}/ReelMind.ipa"
fi

if [ -d "${ICLOUD_OBSIDIAN}" ]; then
    cp "${OUTPUT_DIR}/ReelMind.ipa" "${ICLOUD_OBSIDIAN}/ReelMind.ipa"
    echo "  -> Copied to Obsidian vault: ${ICLOUD_OBSIDIAN}/ReelMind.ipa"
fi

echo "✅ New App Store Native IPA generated successfully at: ${OUTPUT_DIR}/ReelMind.ipa"
