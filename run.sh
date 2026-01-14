#!/bin/bash
# Whisper Fedora UI - Run Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Colors
RED='\033[0;31m'
NC='\033[0m'

# Check if venv exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}❌ Virtual environment not found.${NC}"
    echo "   Please run ./setup.sh first."
    exit 1
fi

# Activate venv and run
source "$VENV_DIR/bin/activate"

# Set environment for better Wayland/X11 compatibility
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Run the application
exec python "$SCRIPT_DIR/main.py" "$@"
