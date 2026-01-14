#!/bin/bash
# Whisper Fedora - macOS App Bundle Creation Script
# Creates a .app bundle for distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Whisper Fedora"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Whisper Fedora - macOS App Bundle Builder           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Clean previous build
echo -e "${YELLOW}→ Cleaning previous build...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Check for venv
if [ ! -d "$PROJECT_DIR/.venv" ]; then
    echo -e "${RED}❌ Virtual environment not found.${NC}"
    echo "   Please run ./setup-mac.sh first."
    exit 1
fi

# Copy Python source files
echo -e "${YELLOW}→ Copying application files...${NC}"
cp "$PROJECT_DIR/main.py" "$RESOURCES/"
cp "$PROJECT_DIR/transcriber.py" "$RESOURCES/"
cp "$PROJECT_DIR/exporters.py" "$RESOURCES/"
cp "$PROJECT_DIR/utils.py" "$RESOURCES/"
cp -r "$PROJECT_DIR/ui" "$RESOURCES/"

# Create models directory
mkdir -p "$RESOURCES/models"
if [ -d "$PROJECT_DIR/models" ]; then
    cp -r "$PROJECT_DIR/models/"* "$RESOURCES/models/" 2>/dev/null || true
fi

# Copy icon if exists
if [ -f "$SCRIPT_DIR/whisper-fedora.icns" ]; then
    cp "$SCRIPT_DIR/whisper-fedora.icns" "$RESOURCES/AppIcon.icns"
elif [ -f "$SCRIPT_DIR/whisper-fedora.png" ]; then
    # Convert PNG to ICNS if sips is available
    echo -e "${YELLOW}→ Converting icon...${NC}"
    ICONSET="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET"
    sips -z 16 16 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_16x16.png" 2>/dev/null || true
    sips -z 32 32 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_16x16@2x.png" 2>/dev/null || true
    sips -z 32 32 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_32x32.png" 2>/dev/null || true
    sips -z 64 64 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_32x32@2x.png" 2>/dev/null || true
    sips -z 128 128 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_128x128.png" 2>/dev/null || true
    sips -z 256 256 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_128x128@2x.png" 2>/dev/null || true
    sips -z 256 256 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_256x256.png" 2>/dev/null || true
    sips -z 512 512 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_256x256@2x.png" 2>/dev/null || true
    sips -z 512 512 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_512x512.png" 2>/dev/null || true
    sips -z 1024 1024 "$SCRIPT_DIR/whisper-fedora.png" --out "$ICONSET/icon_512x512@2x.png" 2>/dev/null || true
    iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns" 2>/dev/null || true
    rm -rf "$ICONSET"
fi

# Create Info.plist
echo -e "${YELLOW}→ Creating Info.plist...${NC}"
cat > "$CONTENTS/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Whisper Fedora</string>
    <key>CFBundleDisplayName</key>
    <string>Whisper Fedora</string>
    <key>CFBundleIdentifier</key>
    <string>io.github.whisper-fedora</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>whisper-fedora</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Audio File</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.audio</string>
                <string>public.movie</string>
            </array>
        </dict>
    </array>
    <key>NSMicrophoneUsageDescription</key>
    <string>Whisper Fedora may need microphone access for future live transcription features.</string>
</dict>
</plist>
EOF

# Create launcher script
echo -e "${YELLOW}→ Creating launcher...${NC}"
cat > "$MACOS/whisper-fedora" << 'EOF'
#!/bin/bash
# Whisper Fedora macOS Launcher

SCRIPT_DIR="$(dirname "$0")"
RESOURCES="$SCRIPT_DIR/../Resources"

# Find Python - prefer system Python 3.11+
PYTHON=""
if command -v python3.11 &> /dev/null; then
    PYTHON="python3.11"
elif command -v python3 &> /dev/null; then
    PYTHON="python3"
else
    osascript -e 'display dialog "Python 3 is required but not found. Please install Python 3.11+." buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check for required packages, install if needed
$PYTHON -c "import PyQt6" 2>/dev/null || {
    osascript -e 'display dialog "Installing required packages. This may take a moment..." buttons {"OK"} default button "OK"'
    $PYTHON -m pip install --user PyQt6 pyqtdarktheme pywhispercpp 2>&1
}

# Set environment
export QT_MAC_WANTS_LAYER=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export PYTHONPATH="$RESOURCES:$PYTHONPATH"

# Run the app
exec $PYTHON "$RESOURCES/main.py"
EOF
chmod +x "$MACOS/whisper-fedora"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Build Complete!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "App bundle created at:"
echo "  $APP_BUNDLE"
echo ""
echo "To install, drag to /Applications or run:"
echo "  cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "To create a DMG for distribution:"
echo "  hdiutil create -volname \"Whisper Fedora\" -srcfolder \"$APP_BUNDLE\" -ov -format UDZO \"$BUILD_DIR/Whisper-Fedora.dmg\""
