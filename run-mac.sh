#!/bin/bash
# Whisper Fedora UI - macOS Run Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Colors
RED='\033[0;31m'
NC='\033[0m'

# Check if venv exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}❌ Virtual environment not found.${NC}"
    echo "   Please run ./setup-mac.sh first."
    exit 1
fi

# Activate venv and run
source "$VENV_DIR/bin/activate"

# Set environment for macOS Qt
export QT_MAC_WANTS_LAYER=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Run the application
exec python "$SCRIPT_DIR/main.py" "$@"
