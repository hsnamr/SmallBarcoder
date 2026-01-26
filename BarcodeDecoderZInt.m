//
//  BarcodeDecoderZInt.m
//  SmallBarcodeReader
//
//  ZInt-based barcode decoder implementation (placeholder)
//  Note: ZInt is primarily an encoding library, not decoding
//

#import "BarcodeDecoderZInt.h"

#if defined(HAVE_ZINT) || __has_include(<zint.h>)
#import <zint.h>
#define ZINT_AVAILABLE 1
#else
#define ZINT_AVAILABLE 0
#endif

@implementation BarcodeDecoderZInt

+ (BOOL)isAvailable {
#if ZINT_AVAILABLE
    // ZInt is available, but it doesn't support decoding
    // Return NO for now, but keep the structure for future use
    return NO;
#else
    return NO;
#endif
}

+ (NSString *)backendName {
    return @"ZInt";
}

- (NSArray *)decodeBarcodesFromData:(unsigned char *)data width:(unsigned)width height:(unsigned)height {
    // ZInt is an encoding library, not a decoding library
    // This is a placeholder for future implementation if ZInt adds decoding support
    // For now, return nil to indicate decoding is not supported
    return nil;
}

@end
