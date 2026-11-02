#!/bin/sh

# The Libmpv Mac Catalyst slice ships as a flat (iOS-style) framework, but
# macOS requires a versioned bundle. Restructure it after embedding.

[ "$EFFECTIVE_PLATFORM_NAME" = "-maccatalyst" ] || exit 0

FRAMEWORK="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/Libmpv.framework"

[ -f "$FRAMEWORK/Info.plist" ] && [ ! -d "$FRAMEWORK/Versions" ] || exit 0

rm -rf "$FRAMEWORK/_CodeSignature"
mkdir -p "$FRAMEWORK/Versions/A/Resources"
mv "$FRAMEWORK/Libmpv" "$FRAMEWORK/Versions/A/Libmpv"
mv "$FRAMEWORK/Info.plist" "$FRAMEWORK/Versions/A/Resources/Info.plist"
ln -s A "$FRAMEWORK/Versions/Current"
ln -s Versions/Current/Libmpv "$FRAMEWORK/Libmpv"
ln -s Versions/Current/Resources "$FRAMEWORK/Resources"

if [ -n "$EXPANDED_CODE_SIGN_IDENTITY" ]; then
    codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none "$FRAMEWORK"
fi
