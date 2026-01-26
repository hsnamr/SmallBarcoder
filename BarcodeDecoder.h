//
//  BarcodeDecoder.h
//  SmallBarcodeReader
//
//  Generic barcode decoder supporting multiple backends (ZBar, ZInt, etc.)
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Barcode decoding result
@interface BarcodeResult : NSObject {
    NSString *data;
    NSString *type;
    NSArray *points; // NSArray of NSValue (NSRect values)
}

@property (retain, nonatomic) NSString *data;
@property (retain, nonatomic) NSString *type;
@property (retain, nonatomic) NSArray *points; // NSArray of NSValue (NSRect values)

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

/// Decode barcodes from an NSImage
/// @param image The image to decode
/// @return Array of BarcodeResult objects, or nil on error
- (NSArray *)decodeBarcodesFromImage:(NSImage *)image;

/// Decode barcodes from image data
/// @param imageData The image data (JPEG, PNG, etc.)
/// @return Array of BarcodeResult objects, or nil on error
- (NSArray *)decodeBarcodesFromImageData:(NSData *)imageData;

@end

NS_ASSUME_NONNULL_END
