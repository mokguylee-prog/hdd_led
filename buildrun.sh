#!/bin/zsh
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT="$SCRIPT_DIR/Noti HDD.xcodeproj"
SCHEME="Noti HDD"
CONFIG="Release"

echo "▶ Building $SCHEME ($CONFIG)..."
if command -v xcpretty >/dev/null 2>&1; then
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        build \
        | xcpretty
else
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        build
fi

BUILD_SETTINGS=$(xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -showBuildSettings 2>/dev/null)

APP_PATH=$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/BUILT_PRODUCTS_DIR/ {print $2; exit}')
APP_NAME=$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/FULL_PRODUCT_NAME/ {print $2; exit}')
EXECUTABLE_NAME=$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/EXECUTABLE_NAME/ {print $2; exit}')

if [[ -z "$APP_PATH" || -z "$APP_NAME" ]]; then
    echo "✗ Failed to resolve the built app path from Xcode build settings."
    exit 1
fi

APP="$APP_PATH/$APP_NAME"
COPIED_APP="$SCRIPT_DIR/$APP_NAME"

if [[ ! -d "$APP" ]]; then
    echo "✗ Build failed or app not found at: $APP"
    exit 1
fi

echo "▶ Copying app to $COPIED_APP..."
rm -rf "$COPIED_APP"
ditto "$APP" "$COPIED_APP"

echo "✓ Build succeeded"
echo "▶ Launching $COPIED_APP..."

# Kill existing instance if running
pkill -x "${EXECUTABLE_NAME:-${APP_NAME%.app}}" 2>/dev/null && sleep 0.5 || true

open "$COPIED_APP"
echo "✓ Launched"
