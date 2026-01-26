# Build Notes for Linux (GNUstep)

## Prerequisites

Before building, you need to install the ZBar development headers:

```bash
sudo apt-get install libzbar-dev
```

Or on other distributions:
- Fedora: `sudo dnf install zbar-devel`
- Arch: `sudo pacman -S zbar`

## Building

1. **Build SmallStep first** (if not already built):
   ```bash
   cd ../SmallStep
   . /usr/share/GNUstep/Makefiles/GNUstep.sh
   make
   sudo make install
   ```

2. **Build SmallBarcodeReader**:
   ```bash
   cd SmallBarcodeReader
   . /usr/share/GNUstep/Makefiles/GNUstep.sh
   make
   ```

3. **Run the application**:
   ```bash
   ./SmallBarcodeReader.app/SmallBarcodeReader
   ```

## Troubleshooting

### ZBar headers not found

If you get an error about `zbar.h` not found:
- Install `libzbar-dev` package
- Or manually specify the include path in the GNUmakefile

### SmallStep not found

If you get linker errors about SmallStep:
- Make sure SmallStep is built and installed
- Check that SmallStep.framework is in the expected location
- You may need to adjust library paths in the GNUmakefile
