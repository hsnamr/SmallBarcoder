# Development Plan for SmallBarcoder

## Current Implementation Status

### ✅ Implemented
- **Barcode Decoding**: Fully functional using ZBar library
  - Supports multiple barcode formats (EAN-13, UPC-A, Code 128, QR Code, etc.)
  - Plugin-based backend architecture (`BarcodeDecoderBackend` protocol)
  - Cross-platform support (macOS/GNUstep)
  - Graceful error handling when libraries are unavailable
  - Image loading and display (JPEG, PNG, TIFF)
  - Background decoding with UI updates

### ❌ Not Implemented
- **Barcode Encoding**: ZInt library is included in build but encoding functionality is not implemented
- **Dynamic Library Loading**: Only static linking at compile time is supported
- **Image Distortion**: No distortion/transformation capabilities
- **Quality Score Display**: ZBar quality scores are not extracted or displayed
- **Input/Output Matching**: No tracking of original input when testing distorted barcodes

---

## Implementation Plan

### Phase 1: Barcode Encoding (ZInt Integration)

#### 1.1 Create Barcode Encoder Architecture
- [ ] Create `BarcodeEncoder.h/m` - Generic encoder interface (similar to `BarcodeDecoder`)
- [ ] Create `BarcodeEncoderBackend.h` - Protocol for encoder backends
- [ ] Create `BarcodeEncoderZInt.h/m` - ZInt-based encoder implementation
- [ ] Add encoder backend detection and initialization logic
- [ ] Support multiple barcode symbologies through ZInt

#### 1.2 Implement ZInt Encoding Backend
- [ ] Research ZInt API for encoding different barcode types
- [ ] Implement `BarcodeEncoderZInt` class conforming to `BarcodeEncoderBackend`
- [ ] Support common 2D and 3D barcode formats:
  - QR Code
  - Data Matrix
  - PDF417
  - Aztec
  - Code 128, Code 39, EAN-13, UPC-A, etc.
- [ ] Convert ZInt output to `NSImage` for display
- [ ] Handle encoding errors gracefully

#### 1.3 Update UI for Encoding
- [ ] Add "Encode" button to `WindowController`
- [ ] Add text input field for barcode data
- [ ] Add barcode type selector (dropdown/popup)
- [ ] Add encoding options panel (size, error correction, etc.)
- [ ] Display encoded barcode image in image view
- [ ] Save encoded barcode to file option

---

### Phase 2: Dynamic Library Loading

#### 2.1 Create Dynamic Library Loader
- [ ] Create `DynamicLibraryLoader.h/m` - Platform-agnostic dynamic library loader
- [ ] Use SmallStep framework for platform abstraction
- [ ] Implement `dlopen()` wrapper for Linux (`.so` files)
- [ ] Implement `NSBundle` or `dlopen()` for macOS (`.dylib` files)
- [ ] Handle library path resolution (system paths, user paths, relative paths)
- [ ] Implement symbol resolution (`dlsym()` equivalent)

#### 2.2 Update Backend System for Dynamic Loading
- [ ] Modify `BarcodeDecoderZBar` to support dynamic loading
- [ ] Modify `BarcodeEncoderZInt` to support dynamic loading
- [ ] Create factory methods that can load backends from dynamic libraries
- [ ] Add runtime backend discovery (scan for `.so`/`.dylib` files)
- [ ] Maintain backward compatibility with static linking

#### 2.3 Update Build System
- [ ] Modify `GNUmakefile` to support building with or without static libraries
- [ ] Add build option for dynamic-only linking (no static libraries)
- [ ] Update `build-macos.sh` for dynamic library support
- [ ] Ensure app can run without any libraries linked at compile time
- [ ] Add runtime library path configuration

#### 2.4 Library Discovery and Loading UI
- [ ] Add "Load Library" menu item or button
- [ ] File dialog for selecting `.so`/`.dylib` files
- [ ] Display loaded libraries in status area
- [ ] Show available backends after library loading
- [ ] Error handling for incompatible or missing libraries

---

### Phase 3: Image Distortion System

#### 3.1 Create Matrix/Image Processing Framework
- [ ] Create `ImageMatrix.h/m` - Matrix operations for image processing
- [ ] Implement 2D convolution operations
- [ ] Support common convolution kernels:
  - Blur (Gaussian, box)
  - Sharpen
  - Edge detection (Sobel, Laplacian)
  - Motion blur
  - Noise addition
- [ ] Implement geometric transformations:
  - Rotation
  - Scaling
  - Skewing
  - Perspective transformation
- [ ] Platform-independent implementation (pure matrix math)

#### 3.2 Create Distortion Pipeline
- [ ] Create `ImageDistorter.h/m` - Main distortion interface
- [ ] Support chaining multiple distortions
- [ ] Apply distortions to `NSImage` objects
- [ ] Preserve image format and color space
- [ ] Handle edge cases (boundary pixels, out-of-bounds)

#### 3.3 Distortion UI Controls
- [ ] Add "Apply Distortion" section to UI
- [ ] Add distortion type selector (blur, sharpen, rotate, etc.)
- [ ] Add intensity/strength sliders for each distortion type
- [ ] Preview distorted image before encoding/decoding
- [ ] Support multiple distortion layers
- [ ] Reset/clear distortions button

#### 3.4 Integration with Encoding/Decoding
- [ ] Apply distortions to encoded barcode images
- [ ] Apply distortions to loaded images before decoding
- [ ] Track original input data when encoding with distortion
- [ ] Store distortion parameters for reproducibility

---

### Phase 4: Quality Score and Input/Output Matching

#### 4.1 Extract ZBar Quality Scores
- [ ] Research ZBar API for quality/confidence scores
- [ ] Modify `BarcodeDecoderZBar` to extract quality metrics
- [ ] Add quality score to `BarcodeResult` class
- [ ] Display quality score in decoding results UI
- [ ] Format quality score appropriately (percentage, rating, etc.)

#### 4.2 Input/Output Tracking System
- [ ] Extend `BarcodeResult` to include original input data (when available)
- [ ] Store original input when encoding barcodes
- [ ] Compare decoded output with original input
- [ ] Calculate match accuracy (exact match, partial match, mismatch)
- [ ] Display comparison results in UI

#### 4.3 Enhanced Results Display
- [ ] Update `WindowController.updateResults:` to show:
  - Quality score (if available)
  - Original input data (if encoding was performed)
  - Match status (matches/doesn't match original)
  - Distortion parameters used (if applicable)
- [ ] Color-code results (green for match, red for mismatch, yellow for partial)
- [ ] Add detailed comparison view

---

### Phase 5: Testing and Decodability Limits

#### 5.1 Automated Distortion Testing
- [ ] Create test framework for systematic distortion application
- [ ] Test various distortion levels (low to high intensity)
- [ ] Test different distortion types on different barcode formats
- [ ] Record success/failure rates for each combination
- [ ] Generate test reports

#### 5.2 Decodability Analysis
- [ ] Track minimum distortion levels that cause decode failures
- [ ] Identify which barcode types are most/least resilient
- [ ] Analyze correlation between quality scores and decode success
- [ ] Create visualization of decodability limits

#### 5.3 UI Enhancements for Testing
- [ ] Add "Test Decodability" mode
- [ ] Progressive distortion slider (gradually increase distortion)
- [ ] Real-time decode status as distortion changes
- [ ] Save test results to file
- [ ] Export test data (CSV, JSON)

---

## Technical Considerations

### Platform-Specific Implementation

#### Linux (GNUstep)
- Dynamic library loading: Use `dlopen()`, `dlsym()`, `dlclose()`
- Library paths: `/usr/lib`, `/usr/local/lib`, `LD_LIBRARY_PATH`
- Library naming: `libzbar.so`, `libzint.so` (with version numbers)

#### macOS
- Dynamic library loading: Use `dlopen()` or `NSBundle` for frameworks
- Library paths: `/usr/local/lib`, `~/lib`, framework search paths
- Library naming: `libzbar.dylib`, `libzint.dylib`

### Matrix Operations
- Use pure C/Objective-C for portability
- Consider using Accelerate framework on macOS (optional optimization)
- Implement basic matrix operations from scratch if needed:
  - Matrix multiplication
  - Convolution (2D)
  - Affine transformations

### Memory Management
- Careful handling of dynamically loaded library symbols
- Proper cleanup of distortion buffers
- NSImage to raw pixel data conversion (already implemented)
- Raw pixel data to NSImage conversion (needed for encoding)

### Error Handling
- Graceful degradation when libraries are unavailable
- Clear error messages for users
- Logging for debugging (optional)

---

## File Structure (New Files to Create)

```
SmallBarcoder/
├── BarcodeEncoder.h/m              # Generic encoder interface
├── BarcodeEncoderBackend.h         # Encoder backend protocol
├── BarcodeEncoderZInt.h/m          # ZInt encoder implementation
├── DynamicLibraryLoader.h/m        # Dynamic library loading
├── ImageMatrix.h/m                 # Matrix operations for images
├── ImageDistorter.h/m              # Image distortion pipeline
└── (Updated existing files)
    ├── BarcodeDecoder.h/m          # Add quality score support
    ├── BarcodeDecoderZBar.m        # Extract quality scores
    ├── BarcodeResult.h             # Add quality score, original input
    └── WindowController.h/m        # Add encoding, distortion UI
```

---

## Implementation Order (Recommended)

1. **Phase 1** (Encoding): Foundation for creating test barcodes
2. **Phase 4** (Quality/Matching): Enhance existing decoding with quality scores
3. **Phase 3** (Distortion): Core feature for testing decodability
4. **Phase 2** (Dynamic Loading): Flexibility for deployment
5. **Phase 5** (Testing): Advanced features for analysis

---

## Dependencies and Requirements

### Existing Dependencies
- SmallStep framework (cross-platform abstraction)
- ZBar library (decoding) - optional
- ZInt library (encoding) - optional
- GNUstep Base/GUI (Linux) or AppKit (macOS)

### New Dependencies
- None (all features should use existing libraries or pure implementations)

### Build Requirements
- Support both static and dynamic linking
- Conditional compilation based on library availability
- Runtime library discovery

---

## Testing Strategy

### Unit Tests (if test framework available)
- Matrix operations correctness
- Distortion application accuracy
- Input/output matching logic

### Manual Testing
- Encode various barcode types
- Apply different distortions
- Verify decode accuracy
- Test dynamic library loading on both platforms
- Verify quality scores are reasonable

### Edge Cases
- Very high distortion levels
- Invalid library files
- Missing symbols in dynamic libraries
- Large images
- Unsupported barcode formats

---

## Future Enhancements (Out of Scope)

- Support for additional barcode libraries
- Batch processing of multiple images
- Command-line interface
- Plugin system for custom distortions
- Machine learning-based distortion generation
- Performance benchmarking tools

---

## Notes

- All distortion operations should be platform-independent (pure matrix math)
- Dynamic library loading should maintain backward compatibility with static linking
- Quality scores may vary between ZBar versions - document version requirements
- Some barcode formats (especially 2D) are more sensitive to distortion than others
- Consider adding progress indicators for long-running operations (encoding, heavy distortions)
