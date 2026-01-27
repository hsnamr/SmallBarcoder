#!/bin/bash
# Quick test script to verify ZInt encoding
cd "$(dirname "$0")"
. /usr/share/GNUstep/Makefiles/GNUstep.sh

echo "=== Testing ZInt Encoding ==="
echo ""

# Check if app exists
if [ ! -f SmallBarcodeReader.app/SmallBarcodeReader ]; then
    echo "ERROR: App not found. Please build first with 'make'"
    exit 1
fi

echo "✓ App found"
echo ""

# Check if ZInt library is linked
if ldd SmallBarcodeReader.app/SmallBarcodeReader | grep -q zint; then
    echo "✓ ZInt library is linked"
    ZINT_LIB=$(ldd SmallBarcodeReader.app/SmallBarcodeReader | grep zint | awk '{print $3}')
    echo "  Library: $ZINT_LIB"
else
    echo "✗ ZInt library not found in linked libraries"
    exit 1
fi

echo ""
echo "=== Test Instructions ==="
echo "1. Run the app: ./SmallBarcodeReader.app/SmallBarcodeReader"
echo "2. Check the text view - it should show:"
echo "   '✓ ZInt encoder loaded successfully'"
echo "3. Enter 'Hello World' in the encoding field"
echo "4. Select 'QR Code' from the symbology dropdown"
echo "5. Click 'Encode'"
echo "6. A QR code image should appear"
echo ""
echo "If all steps work, ZInt encoding is functioning correctly!"
