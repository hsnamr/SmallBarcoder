//
//  BarcodeDecoderBackend.h
//  SmallBarcodeReader
//
//  Protocol for barcode decoder backends
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class BarcodeResult;

/// Protocol that barcode decoder backends must implement
@protocol BarcodeDecoderBackend <NSObject>

/// Decode barcodes from raw image data
/// @param data Grayscale image data (Y800 format)
/// @param width Image width in pixels
/// @param height Image height in pixels
/// @return Array of BarcodeResult objects, or nil on error
- (NSArray *)decodeBarcodesFromData:(unsigned char *)data width:(unsigned)width height:(unsigned)height;

/// Check if this backend is available
+ (BOOL)isAvailable;

/// Name of the backend
+ (NSString *)backendName;

@end
