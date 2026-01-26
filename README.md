# Small Barcode Reader

A cross-platform barcode application for macOS and GNUstep that can decode and encode barcodes from JPEG and PNG images.

## Features

- Load and display JPEG and PNG images
- Decode multiple barcode formats using ZBar or ZInt libraries
- Display decoded barcode data and type information
- Cross-platform support (macOS and GNUstep/Linux)
- Uses SmallStep framework for platform abstraction
- Optional library support - app runs without barcode libraries (shows helpful error messages)
- **Encoding**: Upcoming feature (not yet implemented)
- **Image distortion testing**: Upcoming feature to generate distorted images for testing decoding limits

## Supported Barcode Formats

The application uses ZBar library which supports:
- EAN-13/UPC-A
- UPC-E
- EAN-8
- Code 128
- Code 39
- Interleaved 2 of 5
- QR Code
- And more...

## Requirements

### macOS

- macOS 10.12 or later
- Xcode with Command Line Tools
- **Optional:** ZBar library for decoding (install via Homebrew: `brew install zbar`)
- **Optional:** ZInt library for encoding (install via Homebrew: `brew install zint`)

### GNUstep/Linux

- GNUstep Base and GUI libraries
- GCC or Clang compiler
- **Optional:** ZBar development libraries for decoding
- **Optional:** ZInt development libraries for encoding

**Note:** The application can build and run without barcode libraries. However, to use barcode decoding functionality, you need at least one library installed.

**Installing barcode libraries (optional):**
```bash
# Ubuntu/Debian
sudo apt-get install libzbar-dev    # For decoding
sudo apt-get install libzint-dev    # For encoding (upcoming)

# Fedora
sudo dnf install zbar-devel
sudo dnf install zint-devel

# Arch Linux
sudo pacman -S zbar
sudo pacman -S zint

# Or build from source
```

## Building

### macOS

1. **Optional:** Install barcode libraries:
   ```bash
   brew install zbar    # For decoding
   brew install zint    # For encoding (upcoming)
   ```

2. Build SmallStep first (if not already built):
   ```bash
   cd ../SmallStep
   # Build using Xcode or create framework
   ```

3. Build SmallBarcodeReader:
   ```bash
   cd SmallBarcodeReader
   # Create Xcode project or use command line:
   clang -framework AppKit -framework Foundation \
     -I../SmallStep/SmallStep/Core \
     *.m -o SmallBarcodeReader
   # Note: Add -lzbar and/or -lzint if libraries are installed
   ```

### GNUstep/Linux

1. Build and install SmallStep:
   ```bash
   cd ../SmallStep
   make
   sudo make install
   ```

2. Build SmallBarcodeReader:
   ```bash
   cd SmallBarcodeReader
   make
   ```

3. Run:
   ```bash
   ./SmallBarcodeReader.app/SmallBarcodeReader
   ```

## Usage

1. Launch the application
2. Click "Open Image..." button
3. Select a JPEG or PNG image containing barcodes
4. Click "Decode" button
5. View the decoded barcode information in the text area

## Project Structure

```
SmallBarcodeReader/
├── GNUmakefile          # GNUstep build configuration
├── main.m               # Application entry point
├── AppDelegate.h/m      # Application delegate
├── WindowController.h/m # Main window controller
├── BarcodeDecoder.h/m   # ZBar wrapper for barcode decoding
└── README.md            # This file
```

## Dependencies

- **SmallStep**: Cross-platform abstraction layer (../SmallStep) - **Required**
- **ZBar**: Open-source barcode decoding library - **Optional** (for decoding functionality)
- **ZInt**: Open-source barcode encoding library - **Optional** (for encoding functionality, upcoming)
- **AppKit/GNUstep GUI**: GUI framework - **Required**
- **Foundation**: Core Objective-C framework - **Required**

The application uses a plugin architecture that allows it to work with multiple barcode libraries. Currently supported:
- **ZBar**: Primary library for barcode decoding
- **ZInt**: Library for barcode encoding (decoding support may be added in the future)

Both libraries are optional - the app will build and run without them, displaying helpful error messages when barcode operations are attempted.

## License

See LICENSE file for details.

## Troubleshooting

### No barcode decoder available

If you see an error message about no barcode decoder being available:
- The app can run without barcode libraries, but decoding won't work
- Install at least one barcode library (ZBar for decoding, or ZInt for encoding)
- See the Requirements section for installation instructions
- The error message in the text area will provide specific instructions

### Image loading fails

- Ensure the image file is a valid JPEG or PNG
- Check file permissions
- Error messages are displayed in the text area (no popups)

### No barcodes detected

- Ensure the image is clear and in focus
- Try a higher resolution image
- Check that the barcode is not damaged or obscured
- Some barcode formats may require specific image quality
- Verify that a barcode library (ZBar) is installed and available

### Library linking issues

- The app automatically detects available libraries during build
- If a library is installed but not detected, check that development headers are installed
- For ZBar: ensure `libzbar-dev` (Linux) or `zbar` (macOS via Homebrew) is installed
- For ZInt: ensure `libzint-dev` (Linux) or `zint` (macOS via Homebrew) is installed
