//
//  BarcodeDecoder.h
//  SmallBarcodeReader
//
//  Generic barcode decoder supporting multiple backends (ZBar, ZInt, etc.)
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/// Barcode decoding result
@interface BarcodeResult : NSObject {
    NSString *data;
    NSString *type;
    NSArray *points; // NSArray of NSValue (NSRect values)
    NSInteger quality; // Quality score (0-100, or -1 if not available)
    NSString *originalInput; // Original input data if this was encoded (for matching)
}

@property (retain, nonatomic) NSString *data;
@property (retain, nonatomic) NSString *type;
@property (retain, nonatomic) NSArray *points; // NSArray of NSValue (NSRect values)
@property (assign, nonatomic) NSInteger quality; // Quality score (0-100, or -1 if not available)
@property (retain, nonatomic) NSString *originalInput; // Original input data if this was encoded (for matching)

@end

/// Generic barcode decoder supporting multiple backends
@interface BarcodeDecoder : NSObject {
    id _backend; // id<BarcodeDecoderBackend>
}

/// Initialize with auto-detected backend
- (instancetype)init;

/// Initialize with specific backend
/// @param backend Backend implementation (must conform to BarcodeDecoderBackend protocol)
- (instancetype)initWithBackend:(id)backend;

/// Get available backend names
+ (NSArray *)availableBackends;

/// Get current backend name
- (NSString *)backendName;

/// Check if a backend is available
- (BOOL)hasBackend;

/// Decode barcodes from an image
/// @param image The image to decode (NSImage on macOS/Linux/Windows, UIImage on iOS)
/// @return Array of BarcodeResult objects, or nil on error
- (NSArray *)decodeBarcodesFromImage:(id)image;

/// Decode barcodes from an image with original input for matching
/// @param image The image to decode (NSImage on macOS/Linux/Windows, UIImage on iOS)
/// @param originalInput Original input data (if this image was encoded, for matching)
/// @return Array of BarcodeResult objects, or nil on error
- (NSArray *)decodeBarcodesFromImage:(id)image originalInput:(NSString *)originalInput;

/// Decode barcodes from image data
/// @param imageData The image data (JPEG, PNG, etc.)
/// @return Array of BarcodeResult objects, or nil on error
- (NSArray *)decodeBarcodesFromImageData:(NSData *)imageData;

@end

NS_ASSUME_NONNULL_END
