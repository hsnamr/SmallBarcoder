//
//  BarcodeDecoder.m
//  SmallBarcodeReader
//
//  Generic barcode decoder implementation
//

#import "BarcodeDecoder.h"
#import "BarcodeDecoderBackend.h"
#import <string.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#endif

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
@synthesize quality;
@synthesize originalInput;

- (instancetype)init {
    self = [super init];
    if (self) {
        quality = -1; // -1 means quality not available
        originalInput = nil;
    }
    return self;
}

- (void)dealloc {
    [data release];
    [type release];
    [points release];
    [originalInput release];
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
        _dynamicBackends = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_backend release];
    [_dynamicBackends release];
    [super dealloc];
}

- (void)registerDynamicBackend:(id<BarcodeDecoderBackend>)backend {
    if (backend && ![_dynamicBackends containsObject:backend]) {
        [_dynamicBackends addObject:backend];
        
        // If no static backend is set, use the first dynamic one
        if (!_backend && _dynamicBackends.count > 0) {
            _backend = [[_dynamicBackends objectAtIndex:0] retain];
        }
    }
}

- (NSArray *)allBackends {
    NSMutableArray *all = [NSMutableArray array];
    
    if (_backend) {
        [all addObject:_backend];
    }
    
    [all addObjectsFromArray:_dynamicBackends];
    
    return all;
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

- (NSArray *)decodeBarcodesFromImage:(id)image {
    return [self decodeBarcodesFromImage:image originalInput:nil];
}

- (NSArray *)decodeBarcodesFromImage:(id)image originalInput:(NSString *)originalInput {
    // Check if backend is available
    if (!_backend) {
        return nil; // No backend available - caller should show error message
    }
    
    if (!image) {
        return nil;
    }
    
#if TARGET_OS_IPHONE
    // iOS: Convert UIImage to raw pixel data
    UIImage *uiImage = nil;
    if ([image isKindOfClass:[UIImage class]]) {
        uiImage = (UIImage *)image;
    } else {
        // Try to extract UIImage from NSImage representation
        // On iOS, NSImage might wrap UIImage
        return nil;
    }
    
    // Get image dimensions
    CGSize size = [uiImage size];
    int width = (int)size.width;
    int height = (int)size.height;
    
    // Create bitmap context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char *)malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    // Draw image to context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [uiImage CGImage]);
    
    // Convert to grayscale
    unsigned char *grayData = (unsigned char *)malloc(width * height);
    int i;
    for (i = 0; i < width * height; i++) {
        unsigned char r = rawData[i * 4];
        unsigned char g = rawData[i * 4 + 1];
        unsigned char b = rawData[i * 4 + 2];
        grayData[i] = (unsigned char)(0.299 * r + 0.587 * g + 0.114 * b);
    }
    
    CGContextRelease(context);
    free(rawData);
    
    // Use backend to decode
    if (_backend && [_backend respondsToSelector:@selector(decodeBarcodesFromData:width:height:)]) {
        NSArray *results = [_backend decodeBarcodesFromData:grayData width:(unsigned)width height:(unsigned)height];
        
        // Set original input for matching if provided
        if (originalInput && results) {
            NSInteger j;
            for (j = 0; j < results.count; j++) {
                BarcodeResult *result = [results objectAtIndex:j];
                result.originalInput = originalInput;
            }
        }
        
        free(grayData);
        return results;
    }
    
    free(grayData);
    return nil;
#else
    // macOS/Linux/Windows: Convert NSImage to NSData (TIFF representation)
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
        
        // Set original input for matching if provided
        if (originalInput && results) {
            NSInteger i;
            for (i = 0; i < results.count; i++) {
                BarcodeResult *result = [results objectAtIndex:i];
                result.originalInput = originalInput;
            }
        }
        
        // Free the data after backend is done with it
        // We allocated it, so we're responsible for freeing it
        // The backend should NOT free it (we pass NULL as cleanup function to ZBar)
        free(rawData);
        return results;
    }
    
    // No backend available - free the data we allocated
    free(rawData);
    return nil;
#endif
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
