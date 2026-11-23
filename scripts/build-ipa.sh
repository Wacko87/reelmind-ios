#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/build/IPA"
ICLOUD_DIR="/Users/wacko87/Library/Mobile Documents/iCloud~md~obsidian/Documents/Apps Xcode"
APP_PATH="${PROJECT_DIR}/build/DeviceDerivedData/Build/Products/Release-iphoneos/ReelMind.app"

echo "==> Packaging ReelMind into IPA..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/Payload"
cp -R "${APP_PATH}" "${OUTPUT_DIR}/Payload/"

cd "${OUTPUT_DIR}"
zip -r -q "ReelMind.ipa" Payload/
rm -rf Payload/

echo "==> Deploying ReelMind.ipa to iCloud Drive..."
if [ -d "${ICLOUD_DIR}" ]; then
    cp "${OUTPUT_DIR}/ReelMind.ipa" "${ICLOUD_DIR}/ReelMind.ipa"
    echo "✅ ReelMind.ipa copied to iCloud Drive: ${ICLOUD_DIR}/ReelMind.ipa"
fi

echo "✅ Local IPA generated: ${OUTPUT_DIR}/ReelMind.ipa"
