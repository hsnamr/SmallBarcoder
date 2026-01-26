# Small Barcoder

A cross-platform barcode application for macOS and GNUstep that can decode and encode barcodes from JPEG and PNG images.

## Features

### ✅ Currently Implemented

- **Image Loading**: Load and display JPEG, PNG, and TIFF images
- **Barcode Decoding**: Decode multiple barcode formats using ZBar library
  - Supports 1D barcodes (EAN-13, UPC-A, Code 128, Code 39, etc.)
  - Supports 2D barcodes (QR Code, etc.)
  - Displays decoded barcode data and type information
  - Shows barcode location points
- **Cross-Platform Support**: Works on macOS and GNUstep/Linux
- **Platform Abstraction**: Uses SmallStep framework for cross-platform compatibility
- **Optional Library Support**: App runs without barcode libraries (shows helpful error messages)
- **Plugin Architecture**: Extensible backend system for multiple barcode libraries
- **Background Processing**: Decoding runs in background thread for responsive UI

### 🚧 Upcoming Features

- **Barcode Encoding**: Generate barcodes using ZInt library (2D and 3D formats)
- **Dynamic Library Loading**: Runtime loading of `.so` (Linux) and `.dylib` (macOS) files
  - Load ZBar and ZInt libraries at runtime without recompiling
  - Support for both static and dynamic linking
- **Image Distortion System**: Apply distortions to test decodability limits
  - Convolution kernels (blur, sharpen, edge detection, motion blur, noise)
  - Geometric transformations (rotation, scaling, skewing, perspective)
  - Platform-independent matrix operations
  - Chain multiple distortions
- **Quality Score Display**: Show ZBar quality/confidence scores for decoded barcodes
- **Input/Output Matching**: Compare original encoded data with decoded output
  - Track original input when encoding barcodes
  - Display match status (matches/doesn't match)
  - Useful for testing distortion effects
- **Decodability Testing**: Automated testing framework for distortion limits
  - Progressive distortion testing
  - Success/failure rate tracking
  - Test reports and analysis

## Supported Barcode Formats

The application supports multiple barcode formats through optional libraries:

### ✅ ZBar (Decoding - Implemented)
Currently supports decoding of:
- **1D Barcodes**: EAN-13, UPC-A, UPC-E, EAN-8, Code 128, Code 39, Interleaved 2 of 5
- **2D Barcodes**: QR Code
- And more formats supported by ZBar library

### 🚧 ZInt (Encoding - Upcoming)
Planned support for encoding:
- **1D Barcodes**: Code 128, Code 39, EAN-13, UPC-A, and more
- **2D Barcodes**: QR Code, Data Matrix, PDF417, Aztec
- **3D Barcodes**: Various 3D barcode formats supported by ZInt

**Note:** The application can build and run without either library. If no barcode libraries are available, the app will display helpful error messages in the text area.

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

### Current Files
```
SmallBarcodeReader/
├── GNUmakefile              # GNUstep build configuration
├── build-macos.sh           # macOS build script
├── main.m                   # Application entry point
├── AppDelegate.h/m          # Application delegate
├── WindowController.h/m     # Main window controller
├── BarcodeDecoder.h/m       # Generic barcode decoder interface
├── BarcodeDecoderBackend.h  # Decoder backend protocol
├── BarcodeDecoderZBar.h/m   # ZBar decoder implementation
├── BarcodeDecoderZInt.h/m   # ZInt decoder (placeholder)
├── README.md                # This file
├── BUILD_NOTES.md           # Build instructions
└── PLAN.md                  # Development plan
```

### Planned Files (Upcoming)
- `BarcodeEncoder.h/m` - Generic barcode encoder interface
- `BarcodeEncoderBackend.h` - Encoder backend protocol
- `BarcodeEncoderZInt.h/m` - ZInt encoder implementation
- `DynamicLibraryLoader.h/m` - Dynamic library loading
- `ImageMatrix.h/m` - Matrix operations for image processing
- `ImageDistorter.h/m` - Image distortion pipeline

## Dependencies

### Required
- **SmallStep**: Cross-platform abstraction layer (../SmallStep) - **Required**
- **AppKit/GNUstep GUI**: GUI framework - **Required**
- **Foundation**: Core Objective-C framework - **Required**

### Optional (for barcode functionality)
- **ZBar**: Open-source barcode decoding library - **Optional** (for decoding functionality)
  - Currently: Static linking at compile time
  - Upcoming: Dynamic linking at runtime (`.so` on Linux, `.dylib` on macOS)
- **ZInt**: Open-source barcode encoding library - **Optional** (for encoding functionality, upcoming)
  - Currently: Included in build system but not used
  - Upcoming: Encoding implementation with static and dynamic linking support

### Architecture

The application uses a plugin architecture that allows it to work with multiple barcode libraries:

- **Backend System**: Protocol-based architecture (`BarcodeDecoderBackend`, `BarcodeEncoderBackend`)
- **Current Support**: ZBar for decoding (static linking)
- **Upcoming Support**: 
  - ZInt for encoding
  - Dynamic library loading for both ZBar and ZInt
  - Runtime backend discovery

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
- **Note**: Currently only static linking is supported. Dynamic library loading will be available in a future version.

## Development Roadmap

See [PLAN.md](PLAN.md) for detailed development plan including:
- **Phase 1**: Barcode Encoding (ZInt Integration)
- **Phase 2**: Dynamic Library Loading
- **Phase 3**: Image Distortion System
- **Phase 4**: Quality Score and Input/Output Matching
- **Phase 5**: Testing and Decodability Limits
