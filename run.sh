#!/bin/bash
# Build and run PulseRT

# Kill existing instance if running
pkill -x PulseRT 2>/dev/null || true

# Build
echo "Building PulseRT..."
BUILD_OUTPUT=$(xcodebuild -project PulseRT.xcodeproj -scheme PulseRT -configuration Debug build 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    echo "Build succeeded"
else
    echo "$BUILD_OUTPUT" | grep -E "error:" || echo "Build failed"
    exit 1
fi

# Find and run the built app
APP_PATH=$(xcodebuild -project PulseRT.xcodeproj -scheme PulseRT -configuration Debug -showBuildSettings 2>/dev/null | grep -m1 "BUILT_PRODUCTS_DIR" | awk '{print $3}')/PulseRT.app

echo "Launching PulseRT..."
open "$APP_PATH"
