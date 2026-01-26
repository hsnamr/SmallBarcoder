//
//  BarcodeDecoder.h
//  SmallBarcodeReader
//
//  Barcode decoding using ZBar library
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

/// Barcode decoder wrapper for ZBar
@interface BarcodeDecoder : NSObject

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
