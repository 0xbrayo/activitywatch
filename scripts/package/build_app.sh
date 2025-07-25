#!/bin/bash
set -e

# Configuration
APP_NAME="ActivityWatch"
BUNDLE_ID="net.activitywatch.ActivityWatch"
# Get version with a more robust fallback mechanism
if git describe --tags --abbrev=0 2>/dev/null; then
    VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')
else
    # Try getting version from pyproject.toml
    if grep -q 'version' pyproject.toml 2>/dev/null; then
        VERSION=$(grep 'version' pyproject.toml | head -1 | sed 's/.*version = "\(.*\)".*/\1/')
    else
        # Fallback to a default version
        VERSION="0.1.0"
    fi
fi
ICON_PATH="aw-tauri/src-tauri/icons/icon.icns"
ENTITLEMENTS_PATH="scripts/package/entitlements.plist"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is designed to run on macOS only."
    exit 1
fi

# Clean previous build
echo "Cleaning previous builds..."
rm -rf "dist/${APP_NAME}.app"
mkdir -p "dist"


# Note: Include aw-sync but not aw-server

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "dist/${APP_NAME}.app/Contents/"{MacOS,Resources}

# Copy aw-tauri binary to MacOS folder
echo "Copying aw-tauri binary..."
cp "aw-tauri/src-tauri/target/release/aw-tauri" "dist/${APP_NAME}.app/Contents/MacOS/"

# Copy aw-sync binary but not aw-server
echo "Looking for aw-sync binary..."
AW_SYNC_BINARY=""
if [ -f "aw-server-rust/target/release/aw-sync" ]; then
    AW_SYNC_BINARY="aw-server-rust/target/release/aw-sync"
elif [ -f "dist-backup/activitywatch/aw-sync" ]; then
    AW_SYNC_BINARY="dist-backup/activitywatch/aw-sync"
fi

if [ -n "$AW_SYNC_BINARY" ]; then
    echo "Found aw-sync at: $AW_SYNC_BINARY"
    mkdir -p "dist/${APP_NAME}.app/Contents/Resources/aw_sync"
    cp "$AW_SYNC_BINARY" "dist/${APP_NAME}.app/Contents/Resources/aw_sync/"
else
    echo "aw-sync binary not found. Creating placeholder directory."
    mkdir -p "dist/${APP_NAME}.app/Contents/Resources/aw_sync"
fi

# Print detected version
echo "Using version: ${VERSION}"

# Find and copy watcher binaries
# Check different possible locations for aw-watcher-window
echo "Looking for aw-watcher-window binary..."
AW_WINDOW_BINARY=""
AW_WINDOW_JXA=""
if [ -f "aw-watcher-window/aw_watcher_window/aw-watcher-window" ]; then
    AW_WINDOW_BINARY="aw-watcher-window/aw_watcher_window/aw-watcher-window"
    AW_WINDOW_JXA="aw-watcher-window/aw_watcher_window/printAppStatus.jxa"
elif [ -f "dist-backup/activitywatch/aw-watcher-window/aw-watcher-window" ]; then
    AW_WINDOW_BINARY="dist-backup/activitywatch/aw-watcher-window/aw-watcher-window"
    if [ -f "aw-watcher-window/aw_watcher_window/printAppStatus.jxa" ]; then
        AW_WINDOW_JXA="aw-watcher-window/aw_watcher_window/printAppStatus.jxa"
    fi
fi

if [ -n "$AW_WINDOW_BINARY" ]; then
    echo "Found aw-watcher-window at: $AW_WINDOW_BINARY"
    mkdir -p "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_window"
    cp "$AW_WINDOW_BINARY" "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_window/"
    if [ -n "$AW_WINDOW_JXA" ]; then
        cp "$AW_WINDOW_JXA" "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_window/"
    fi
else
    echo "aw-watcher-window binary not found. Creating placeholder directory."
    mkdir -p "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_window"
fi

# Check different possible locations for aw-watcher-afk
echo "Looking for aw-watcher-afk binary..."
AW_AFK_BINARY=""
if [ -f "aw-watcher-afk/aw_watcher_afk/aw-watcher-afk" ]; then
    AW_AFK_BINARY="aw-watcher-afk/aw_watcher_afk/aw-watcher-afk"
elif [ -f "dist-backup/activitywatch/aw-watcher-afk/aw-watcher-afk" ]; then
    AW_AFK_BINARY="dist-backup/activitywatch/aw-watcher-afk/aw-watcher-afk"
fi

if [ -n "$AW_AFK_BINARY" ]; then
    echo "Found aw-watcher-afk at: $AW_AFK_BINARY"
    mkdir -p "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_afk"
    cp "$AW_AFK_BINARY" "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_afk/"
else
    echo "aw-watcher-afk binary not found. Creating placeholder directory."
    mkdir -p "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_afk"
fi

# Copy icons
echo "Copying app icon..."
mkdir -p "dist/${APP_NAME}.app/Contents/Resources"
cp "${ICON_PATH}" "dist/${APP_NAME}.app/Contents/Resources/icon.icns"

# Create Info.plist
echo "Creating Info.plist..."
cat > "dist/${APP_NAME}.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleExecutable</key>
    <string>aw-tauri</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Please grant access to use Apple Events</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Create an empty PkgInfo file
echo "Creating PkgInfo..."
echo "APPL????" > "dist/${APP_NAME}.app/Contents/PkgInfo"

# Set permissions
echo "Setting permissions..."
chmod +x "dist/${APP_NAME}.app/Contents/MacOS/aw-tauri"
# Make watcher and sync binaries executable if they exist
[ -f "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_window/aw-watcher-window" ] && \
    chmod +x "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_window/aw-watcher-window"
[ -f "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_afk/aw-watcher-afk" ] && \
    chmod +x "dist/${APP_NAME}.app/Contents/Resources/aw_watcher_afk/aw-watcher-afk"
[ -f "dist/${APP_NAME}.app/Contents/Resources/aw_sync/aw-sync" ] && \
    chmod +x "dist/${APP_NAME}.app/Contents/Resources/aw_sync/aw-sync"

# Code signing (if APPLE_PERSONALID is set)
if [ -n "$APPLE_PERSONALID" ]; then
    echo "Signing app with identity: $APPLE_PERSONALID"
    if [ -f "$ENTITLEMENTS_PATH" ]; then
        codesign --deep --force --sign "$APPLE_PERSONALID" --entitlements "$ENTITLEMENTS_PATH" \
            "dist/${APP_NAME}.app"
    else
        codesign --deep --force --sign "$APPLE_PERSONALID" \
            "dist/${APP_NAME}.app"
    fi
    echo "App signing complete."
else
    echo "APPLE_PERSONALID environment variable not set. Skipping app signing."
fi

echo "App bundle created at dist/${APP_NAME}.app"
