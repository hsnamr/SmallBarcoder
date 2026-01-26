//
//  BarcodeEncoderZInt.m
//  SmallBarcodeReader
//
//  ZInt-based barcode encoder implementation
//

#import "BarcodeEncoderZInt.h"
#import "../SmallStep/SmallStep/Core/SmallStep.h"
#import <string.h>

#if defined(HAVE_ZINT) || __has_include(<zint.h>)
#import <zint.h>
#define ZINT_AVAILABLE 1
#else
#define ZINT_AVAILABLE 0
// ZInt symbology constants (fallback if zint.h not available)
// These match the values in zint.h
#define BARCODE_QRCODE 58
#define BARCODE_DATAMATRIX 71
#define BARCODE_PDF417 55
#define BARCODE_AZTEC 92
#define BARCODE_CODE128 20
#define BARCODE_CODE39 1
#define BARCODE_EANX 13
#define BARCODE_UPCA 34
#endif

// Use ZInt constants if available, otherwise use fallback defines
#if ZINT_AVAILABLE
// Constants are defined in zint.h (BARCODE_*)
#else
// Use fallback defines (already defined above)
#endif

@implementation BarcodeEncoderZInt

+ (BOOL)isAvailable {
#if ZINT_AVAILABLE
  #if defined(DYNAMIC_ONLY)
    // In dynamic-only mode, check if library is actually loaded at runtime
    // For now, return NO - backends must be loaded via dynamic library loading
    return NO;
  #else
    return YES;
  #endif
#else
    return NO;
#endif
}

+ (NSString *)backendName {
    return @"ZInt";
}

+ (NSArray *)supportedSymbologies {
    NSMutableArray *symbologies = [NSMutableArray array];
    
#if ZINT_AVAILABLE
    // Add common 1D barcodes
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_CODE128], @"id",
        @"Code 128", @"name",
        @"Code 128 - High density alphanumeric barcode", @"description",
        nil]];
    
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_CODE39], @"id",
        @"Code 39", @"name",
        @"Code 39 - Alphanumeric barcode", @"description",
        nil]];
    
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_EANX], @"id",
        @"EAN-13", @"name",
        @"EAN-13 - European Article Number", @"description",
        nil]];
    
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_UPCA], @"id",
        @"UPC-A", @"name",
        @"UPC-A - Universal Product Code", @"description",
        nil]];
    
    // Add common 2D barcodes
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_QRCODE], @"id",
        @"QR Code", @"name",
        @"QR Code - Quick Response Code", @"description",
        nil]];
    
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_DATAMATRIX], @"id",
        @"Data Matrix", @"name",
        @"Data Matrix - 2D matrix barcode", @"description",
        nil]];
    
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_PDF417], @"id",
        @"PDF417", @"name",
        @"PDF417 - Stacked linear barcode", @"description",
        nil]];
    
    [symbologies addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:BARCODE_AZTEC], @"id",
        @"Aztec Code", @"name",
        @"Aztec Code - 2D matrix barcode", @"description",
        nil]];
#endif
    
    return symbologies;
}

- (NSImage *)encodeBarcodeFromData:(NSString *)data symbology:(int)symbology options:(NSDictionary *)options {
#if ZINT_AVAILABLE
    if (!data || data.length == 0) {
        return nil;
    }
    
    // Create ZInt symbol
    struct zint_symbol *symbol = ZBarcode_Create();
    if (!symbol) {
        return nil;
    }
    
    // Set symbology
    symbol->symbology = symbology;
    
    // Apply options
    if (options) {
        // Width (scale factor)
        NSNumber *width = [options objectForKey:@"width"];
        if (width) {
            symbol->scale = [width floatValue];
        }
        
        // Height
        NSNumber *height = [options objectForKey:@"height"];
        if (height) {
            symbol->height = [height intValue];
        }
        
        // Scale (overrides width if both set)
        NSNumber *scale = [options objectForKey:@"scale"];
        if (scale) {
            symbol->scale = [scale floatValue];
        }
        
        // Border width
        NSNumber *borderWidth = [options objectForKey:@"borderWidth"];
        if (borderWidth) {
            symbol->border_width = [borderWidth intValue];
        }
        
        // Error correction level (for QR Code, etc.)
        NSNumber *errorCorrection = [options objectForKey:@"errorCorrection"];
        if (errorCorrection) {
            symbol->option_1 = [errorCorrection intValue];
        }
        
        // Foreground color (hex string like "000000")
        NSString *fgColor = [options objectForKey:@"foregroundColor"];
        if (fgColor && fgColor.length == 6) {
            strncpy(symbol->fgcolour, [fgColor UTF8String], 7);
        }
        
        // Background color (hex string like "FFFFFF")
        NSString *bgColor = [options objectForKey:@"backgroundColor"];
        if (bgColor && bgColor.length == 6) {
            strncpy(symbol->bgcolour, [bgColor UTF8String], 7);
        }
    }
    
    // Set default colors if not specified
    if (strlen(symbol->fgcolour) == 0) {
        strcpy(symbol->fgcolour, "000000"); // Black
    }
    if (strlen(symbol->bgcolour) == 0) {
        strcpy(symbol->bgcolour, "FFFFFF"); // White
    }
    
    // Encode the barcode
    const char *dataUTF8 = [data UTF8String];
    int error = ZBarcode_Encode(symbol, (const unsigned char *)dataUTF8, 0);
    
    if (error != 0) {
        // Encoding failed
        ZBarcode_Delete(symbol);
        return nil;
    }
    
    // Get temporary directory using SmallStep
    SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
    NSString *tempDir = [fileSystem temporaryDirectory];
    if (!tempDir) {
        ZBarcode_Delete(symbol);
        return nil;
    }
    
    // Create temporary file path
    NSString *tempFileName = [NSString stringWithFormat:@"barcode_%ld.png", (long)[[NSDate date] timeIntervalSince1970]];
    NSString *tempFilePath = [tempDir stringByAppendingPathComponent:tempFileName];
    
    // Set output file in symbol
    strncpy(symbol->outfile, [tempFilePath UTF8String], 256);
    
    // Print to file (PNG format)
    error = ZBarcode_Print(symbol, 0);
    
    NSImage *resultImage = nil;
    
    if (error == 0) {
        // Load the image from file
        NSData *imageData = [NSData dataWithContentsOfFile:tempFilePath];
        if (imageData) {
            resultImage = [[NSImage alloc] initWithData:imageData];
        }
        
        // Clean up temporary file
        [fileSystem deleteFileAtPath:tempFilePath error:NULL];
    }
    
    // Clean up symbol
    ZBarcode_Delete(symbol);
    
    return [resultImage autorelease];
#else
    return nil;
#endif
}

@end
