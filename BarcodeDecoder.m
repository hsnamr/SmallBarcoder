//
//  BarcodeDecoder.m
//  SmallBarcodeReader
//
//  Generic barcode decoder implementation
//

#import "BarcodeDecoder.h"
#import "BarcodeDecoderBackend.h"
#import <string.h>

// Conditionally import ZBar if available
#if defined(HAVE_ZBAR)
#import "BarcodeDecoderZBar.h"
#define ZBAR_BACKEND_AVAILABLE 1
#else
#define ZBAR_BACKEND_AVAILABLE 0
#endif

// Conditionally import ZInt if available
#if defined(HAVE_ZINT)
#import "BarcodeDecoderZInt.h"
#define ZINT_BACKEND_AVAILABLE 1
#else
#define ZINT_BACKEND_AVAILABLE 0
#endif

@implementation BarcodeResult

@synthesize data;
@synthesize type;
@synthesize points;

- (void)dealloc {
    [data release];
    [type release];
    [points release];
    [super dealloc];
}

@end

@implementation BarcodeDecoder

+ (NSArray *)availableBackends {
    NSMutableArray *backends = [NSMutableArray array];
    
    // Check ZBar (if compiled in)
#if ZBAR_BACKEND_AVAILABLE
    if ([BarcodeDecoderZBar isAvailable]) {
        [backends addObject:[BarcodeDecoderZBar backendName]];
    }
#endif
    
    // Check ZInt (if compiled in)
#if ZINT_BACKEND_AVAILABLE
    if ([BarcodeDecoderZInt isAvailable]) {
        [backends addObject:[BarcodeDecoderZInt backendName]];
    }
#endif
    
    return backends;
}

- (instancetype)init {
    // Auto-detect and use first available backend
    // If no backend is available, still initialize (backend will be nil)
    // This allows the app to run and show a graceful error message
    id backend = nil;
    
    // Try ZBar first (primary decoding library) if compiled in
#if ZBAR_BACKEND_AVAILABLE
    if ([BarcodeDecoderZBar isAvailable]) {
        backend = [[BarcodeDecoderZBar alloc] init];
    }
    else
#endif
    // Try ZInt (if compiled in)
#if ZINT_BACKEND_AVAILABLE
    if ([BarcodeDecoderZInt isAvailable]) {
        backend = [[BarcodeDecoderZInt alloc] init];
    }
#endif
    
    // Initialize even if no backend is available
    // The app will show a graceful error message when decoding is attempted
    return [self initWithBackend:backend];
}

- (instancetype)initWithBackend:(id)backend {
    self = [super init];
    if (self) {
        _backend = [backend retain];
    }
    return self;
}

- (void)dealloc {
    [_backend release];
    [super dealloc];
}

- (NSString *)backendName {
    if (_backend && [_backend respondsToSelector:@selector(backendName)]) {
        return [_backend performSelector:@selector(backendName)];
    }
    return @"None";
}

- (BOOL)hasBackend {
    return (_backend != nil);
}

- (NSArray *)decodeBarcodesFromImage:(NSImage *)image {
    // Check if backend is available
    if (!_backend) {
        return nil; // No backend available - caller should show error message
    }
    
    if (!image) {
        return nil;
    }
    
    // Convert NSImage to NSData (TIFF representation)
    NSData *tiffData = [image TIFFRepresentation];
    if (!tiffData) {
        return nil;
    }
    
    // Create bitmap image from TIFF data
    NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:tiffData];
    if (!bitmapRep) {
        return nil;
    }
    
    // Get raw pixel data
    NSInteger width = [bitmapRep pixelsWide];
    NSInteger height = [bitmapRep pixelsHigh];
    NSInteger bitsPerPixel = [bitmapRep bitsPerPixel];
    NSInteger bytesPerRow = [bitmapRep bytesPerRow];
    
    // Always convert to grayscale (ZBar needs Y800 format)
    // Allocate our own buffer so we can safely pass it to ZBar
    unsigned char *rawData = malloc(width * height);
    if (!rawData) {
        return nil;
    }
    
    unsigned char *sourceData = (unsigned char *)[bitmapRep bitmapData];
    BOOL needsConversion = YES;
    
    // Check if already grayscale
    if (bitsPerPixel == 8 && [bitmapRep hasAlpha] == NO) {
        // Copy grayscale data
        NSInteger y;
        for (y = 0; y < height; y++) {
            memcpy(rawData + y * width, sourceData + y * bytesPerRow, width);
        }
        needsConversion = NO;
    }
    
    if (needsConversion) {
        // Convert to grayscale
        NSInteger y, x;
        for (y = 0; y < height; y++) {
            for (x = 0; x < width; x++) {
                NSInteger sourceIndex = y * bytesPerRow + x * (bitsPerPixel / 8);
                NSInteger destIndex = y * width + x;
                
                if (bitsPerPixel == 32) {
                    // RGBA - convert to grayscale
                    unsigned char r = sourceData[sourceIndex];
                    unsigned char g = sourceData[sourceIndex + 1];
                    unsigned char b = sourceData[sourceIndex + 2];
                    rawData[destIndex] = (unsigned char)(0.299 * r + 0.587 * g + 0.114 * b);
                } else if (bitsPerPixel == 24) {
                    // RGB - convert to grayscale
                    unsigned char r = sourceData[sourceIndex];
                    unsigned char g = sourceData[sourceIndex + 1];
                    unsigned char b = sourceData[sourceIndex + 2];
                    rawData[destIndex] = (unsigned char)(0.299 * r + 0.587 * g + 0.114 * b);
                } else {
                    rawData[destIndex] = sourceData[sourceIndex];
                }
            }
        }
    }
    
    // Use backend to decode (backend will handle memory management)
    if (_backend && [_backend respondsToSelector:@selector(decodeBarcodesFromData:width:height:)]) {
        NSArray *results = [_backend decodeBarcodesFromData:rawData width:(unsigned)width height:(unsigned)height];
        // Backend should handle freeing the data, but if it doesn't, we need to free it
        // For now, we'll free it here since the backend might copy the data
        free(rawData);
        return results;
    }
    
    // No backend available
    free(rawData);
    return nil;
}

- (NSArray *)decodeBarcodesFromImageData:(NSData *)imageData {
    if (!imageData) {
        return nil;
    }
    
    NSImage *image = [[NSImage alloc] initWithData:imageData];
    if (!image) {
        return nil;
    }
    
    NSArray *results = [self decodeBarcodesFromImage:image];
    [image release];
    return results;
}

@end
