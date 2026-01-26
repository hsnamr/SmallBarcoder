#!/bin/bash
# Build script for macOS

set -e

# Check if ZBar is installed
if ! pkg-config --exists zbar 2>/dev/null && ! brew list zbar &>/dev/null; then
    echo "Error: ZBar library not found."
    echo "Install it with: brew install zbar"
    exit 1
fi

# Find ZBar installation
ZBAR_INCLUDE=""
ZBAR_LIB=""

if brew list zbar &>/dev/null; then
    ZBAR_PREFIX=$(brew --prefix zbar)
    ZBAR_INCLUDE="-I${ZBAR_PREFIX}/include"
    ZBAR_LIB="-L${ZBAR_PREFIX}/lib -lzbar"
else
    # Try pkg-config
    if pkg-config --exists zbar; then
        ZBAR_INCLUDE=$(pkg-config --cflags zbar)
        ZBAR_LIB=$(pkg-config --libs zbar)
    else
        # Try common locations
        if [ -d "/usr/local/include/zbar.h" ] || [ -f "/usr/local/include/zbar.h" ]; then
            ZBAR_INCLUDE="-I/usr/local/include"
            ZBAR_LIB="-L/usr/local/lib -lzbar"
        elif [ -f "/opt/homebrew/include/zbar.h" ]; then
            ZBAR_INCLUDE="-I/opt/homebrew/include"
            ZBAR_LIB="-L/opt/homebrew/lib -lzbar"
        else
            echo "Error: Could not find ZBar installation"
            exit 1
        fi
    fi
fi

# SmallStep path
SMALLSTEP_DIR="../SmallStep"
SMALLSTEP_INCLUDE="-I${SMALLSTEP_DIR}/SmallStep/Core"

# Source files
SOURCES="main.m AppDelegate.m BarcodeDecoder.m WindowController.m"

# Build
echo "Building SmallBarcodeReader for macOS..."
clang -framework AppKit -framework Foundation \
    ${ZBAR_INCLUDE} ${SMALLSTEP_INCLUDE} \
    ${ZBAR_LIB} \
    ${SOURCES} \
    -o SmallBarcodeReader \
    -std=c11 -fobjc-arc

echo "Build complete! Run with: ./SmallBarcodeReader"
