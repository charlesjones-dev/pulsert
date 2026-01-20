#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

APP_NAME="PulseRT"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

echo -e "${GREEN}Building $APP_NAME...${NC}"

# Generate app icon if script exists
if [[ -f "generate-icon.py" ]]; then
  echo -e "${YELLOW}Generating app icon...${NC}"
  python3 generate-icon.py
fi

# Clean previous build
rm -rf "$BUILD_DIR"

# Build release
xcodebuild -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CONFIGURATION_BUILD_DIR="$(pwd)/$BUILD_DIR" \
  -quiet

if [[ ! -d "$APP_PATH" ]]; then
  echo -e "${RED}Build failed: $APP_PATH not found${NC}"
  exit 1
fi

echo -e "${GREEN}Build successful: $APP_PATH${NC}"

# Check for --install flag
if [[ "$1" == "--install" ]]; then
  echo -e "${YELLOW}Installing to /Applications...${NC}"

  # Kill running instance if any
  pkill -x "$APP_NAME" 2>/dev/null || true

  # Remove old version
  rm -rf "$INSTALL_PATH"

  # Copy new version
  cp -R "$APP_PATH" "$INSTALL_PATH"

  # Remove quarantine attribute
  xattr -d com.apple.quarantine "$INSTALL_PATH" 2>/dev/null || true

  echo -e "${GREEN}Installed to $INSTALL_PATH${NC}"
  echo -e "${YELLOW}You can now run $APP_NAME from Applications or Spotlight.${NC}"
else
  echo ""
  echo "To install to Applications, run:"
  echo -e "  ${YELLOW}./build.sh --install${NC}"
  echo ""
  echo "Or manually copy:"
  echo -e "  ${YELLOW}cp -R $APP_PATH /Applications/${NC}"
fi
