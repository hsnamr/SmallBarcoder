//
//  BarcodeEncoderBackend.h
//  SmallBarcodeReader
//
//  Protocol for barcode encoder backends
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/// Protocol that barcode encoder backends must implement
@protocol BarcodeEncoderBackend <NSObject>

/// Encode barcode from text data
/// @param data The text data to encode
/// @param symbology Barcode symbology/type identifier (backend-specific)
/// @param options Dictionary of encoding options (size, error correction, etc.)
/// @return NSImage containing the encoded barcode, or nil on error
- (NSImage *)encodeBarcodeFromData:(NSString *)data symbology:(int)symbology options:(NSDictionary *)options;

/// Get list of supported symbologies
/// @return Array of dictionaries with keys: "id" (int), "name" (NSString), "description" (NSString)
+ (NSArray *)supportedSymbologies;

/// Check if this backend is available
+ (BOOL)isAvailable;

/// Name of the backend
+ (NSString *)backendName;

@end
