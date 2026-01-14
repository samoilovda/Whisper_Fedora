#!/bin/bash
# Whisper Fedora UI - macOS Setup Script
# For Apple Silicon (M1/M2/M3) with Metal acceleration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
MODELS_DIR="$SCRIPT_DIR/models"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Whisper Fedora UI - macOS Setup (Apple Silicon)      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check for Apple Silicon
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
    echo -e "${YELLOW}⚠ This script is optimized for Apple Silicon (M1/M2/M3)${NC}"
    echo "  Detected architecture: $ARCH"
    echo "  Continuing anyway..."
fi

# Check for Homebrew
echo -e "${YELLOW}→ Checking system dependencies...${NC}"
if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew is required but not found.${NC}"
    echo "   Install from: https://brew.sh"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Homebrew installed"

# Check for Python
PYTHON_CMD=""
if command -v python3.11 &> /dev/null; then
    PYTHON_CMD="python3.11"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
else
    echo -e "${YELLOW}→ Installing Python via Homebrew...${NC}"
    brew install python@3.11
    PYTHON_CMD="python3.11"
fi
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
echo -e "  ${GREEN}✓${NC} Python: $PYTHON_CMD ($PYTHON_VERSION)"

# Check for ffmpeg
if command -v ffprobe &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} ffmpeg installed"
else
    echo -e "${YELLOW}→ Installing ffmpeg via Homebrew...${NC}"
    brew install ffmpeg
fi

# Detect Metal support
echo ""
echo -e "${YELLOW}→ Detecting GPU acceleration...${NC}"
GPU_TYPE="cpu"

# Check for Metal support (Apple Silicon always has Metal)
if [ "$ARCH" = "arm64" ]; then
    # Get chip name
    CHIP_NAME=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Apple Silicon")
    echo -e "  ${GREEN}✓${NC} Apple Silicon detected: $CHIP_NAME"
    echo -e "  ${GREEN}✓${NC} Metal GPU acceleration available"
    GPU_TYPE="metal"
else
    echo -e "  ${BLUE}ℹ${NC} Intel Mac - using CPU mode"
fi

# Create virtual environment
echo ""
echo -e "${YELLOW}→ Creating virtual environment...${NC}"
$PYTHON_CMD -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo -e "  ${GREEN}✓${NC} Virtual environment created"

# Upgrade pip
echo ""
echo -e "${YELLOW}→ Upgrading pip...${NC}"
pip install --upgrade pip wheel setuptools > /dev/null
echo -e "  ${GREEN}✓${NC} pip upgraded"

# Install PyQt6
echo ""
echo -e "${YELLOW}→ Installing PyQt6 and theme...${NC}"
pip install 'PyQt6>=6.6.0' 'pyqtdarktheme>=2.1.0' > /dev/null
echo -e "  ${GREEN}✓${NC} PyQt6 installed"

# Install pywhispercpp with Metal support
echo ""
echo -e "${YELLOW}→ Installing pywhispercpp ($GPU_TYPE mode)...${NC}"
echo "   This may take a few minutes (compiling with Metal)..."

if [ "$GPU_TYPE" = "metal" ]; then
    # Metal acceleration for Apple Silicon
    GGML_METAL=1 pip install pywhispercpp 2>&1 | tail -3
else
    pip install pywhispercpp 2>&1 | tail -3
fi
echo -e "  ${GREEN}✓${NC} pywhispercpp installed"

# Create models directory
echo ""
echo -e "${YELLOW}→ Setting up models directory...${NC}"
mkdir -p "$MODELS_DIR"
echo -e "  ${GREEN}✓${NC} Models directory: $MODELS_DIR"

# Download default model
echo ""
echo -e "${YELLOW}→ Downloading default Whisper model (base)...${NC}"
echo "   ~142MB download..."
$PYTHON_CMD -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
from pywhispercpp.model import Model
import os

models_dir = '$MODELS_DIR'
try:
    model = Model('base', models_dir=models_dir)
    print('  ✓ Model downloaded successfully')
except Exception as e:
    print(f'  ⚠ Could not download model: {e}')
    print('    The model will be downloaded on first use.')
"

# Save GPU configuration
echo "$GPU_TYPE" > "$SCRIPT_DIR/.gpu_type"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 Installation Complete!                    ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  GPU Mode:${NC} $GPU_TYPE (Apple Metal)"
echo -e "${GREEN}║  To run:${NC}   ./run-mac.sh"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
