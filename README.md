# Small Barcode Reader

A cross-platform barcode reader application for macOS and GNUstep that can decode barcodes from JPEG and PNG images.

## Features

- Load and display JPEG and PNG images
- Decode multiple barcode formats using ZBar library
- Display decoded barcode data and type information
- Cross-platform support (macOS and GNUstep/Linux)
- Uses SmallStep framework for platform abstraction

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
- ZBar library (install via Homebrew: `brew install zbar`)

### GNUstep/Linux

- GNUstep Base and GUI libraries
- ZBar development libraries (required)
- GCC or Clang compiler

**Important:** You must install ZBar development headers before building:
```bash
# Ubuntu/Debian
sudo apt-get install libzbar-dev

# Fedora
sudo dnf install zbar-devel

# Arch Linux
sudo pacman -S zbar

# Or build from source
```

## Building

### macOS

1. Install ZBar:
   ```bash
   brew install zbar
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
   clang -framework AppKit -framework Foundation -lzbar \
     -I../SmallStep/SmallStep/Core \
     *.m -o SmallBarcodeReader
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

- **SmallStep**: Cross-platform abstraction layer (../SmallStep)
- **ZBar**: Open-source barcode reading library
- **AppKit/GNUstep GUI**: GUI framework
- **Foundation**: Core Objective-C framework

## License

See LICENSE file for details.

## Troubleshooting

### ZBar not found

If you get linker errors about ZBar:
- macOS: Ensure ZBar is installed via Homebrew and in your library path
- Linux: Install libzbar-dev package

### Image loading fails

- Ensure the image file is a valid JPEG or PNG
- Check file permissions

### No barcodes detected

- Ensure the image is clear and in focus
- Try a higher resolution image
- Check that the barcode is not damaged or obscured
- Some barcode formats may require specific image quality
