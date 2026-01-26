//
//  BarcodeEncoder.h
//  SmallBarcodeReader
//
//  Generic barcode encoder supporting multiple backends (ZInt, etc.)
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@protocol BarcodeEncoderBackend;

NS_ASSUME_NONNULL_BEGIN

/// Encoding options keys
extern NSString * const BarcodeEncoderOptionWidth;
extern NSString * const BarcodeEncoderOptionHeight;
extern NSString * const BarcodeEncoderOptionScale;
extern NSString * const BarcodeEncoderOptionBorderWidth;
extern NSString * const BarcodeEncoderOptionErrorCorrection;
extern NSString * const BarcodeEncoderOptionForegroundColor;
extern NSString * const BarcodeEncoderOptionBackgroundColor;

/// Generic barcode encoder supporting multiple backends
@interface BarcodeEncoder : NSObject {
    id _backend; // id<BarcodeEncoderBackend>
    NSMutableArray *_dynamicBackends; // Array of dynamically loaded backends
}

/// Initialize with auto-detected backend
- (instancetype)init;

/// Initialize with specific backend
/// @param backend Backend implementation (must conform to BarcodeEncoderBackend protocol)
- (instancetype)initWithBackend:(id)backend;

/// Get available backend names
+ (NSArray *)availableBackends;

/// Get current backend name
- (NSString *)backendName;

/// Check if a backend is available
- (BOOL)hasBackend;

/// Encode barcode from text data
/// @param data The text data to encode
/// @param symbology Barcode symbology/type identifier (backend-specific)
/// @param options Dictionary of encoding options (size, error correction, etc.)
/// @return NSImage containing the encoded barcode, or nil on error
- (NSImage *)encodeBarcodeFromData:(NSString *)data symbology:(int)symbology options:(NSDictionary *)options;

/// Encode barcode with default options
/// @param data The text data to encode
/// @param symbology Barcode symbology/type identifier
/// @return NSImage containing the encoded barcode, or nil on error
- (NSImage *)encodeBarcodeFromData:(NSString *)data symbology:(int)symbology;

/// Get list of supported symbologies from current backend
/// @return Array of dictionaries with keys: "id" (int), "name" (NSString), "description" (NSString)
- (NSArray *)supportedSymbologies;

/// Register a dynamically loaded backend
- (void)registerDynamicBackend:(id<BarcodeEncoderBackend>)backend;

/// Get all registered backends (static + dynamic)
- (NSArray *)allBackends;

@end

NS_ASSUME_NONNULL_END
