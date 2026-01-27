//
//  BarcodeDecoderZBar.m
//  SmallBarcodeReader
//
//  ZBar-based barcode decoder implementation
//

#import "BarcodeDecoderZBar.h"
#import "BarcodeDecoder.h"  // Contains BarcodeResult definition
#import <string.h>

#if defined(HAVE_ZBAR) || __has_include(<zbar.h>)
#import <zbar.h>
#define ZBAR_AVAILABLE 1
#else
#define ZBAR_AVAILABLE 0
#endif

@implementation BarcodeDecoderZBar

+ (BOOL)isAvailable {
#if ZBAR_AVAILABLE
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
    return @"ZBar";
}

- (NSArray *)decodeBarcodesFromData:(unsigned char *)data width:(unsigned)width height:(unsigned)height {
#if ZBAR_AVAILABLE
    // Create ZBar image scanner
    zbar_image_scanner_t *scanner = zbar_image_scanner_create();
    if (!scanner) {
        return nil;
    }
    
    // Configure scanner to detect all symbologies
    zbar_image_scanner_set_config(scanner, 0, ZBAR_CFG_ENABLE, 1);
    
    // Create ZBar image
    zbar_image_t *image = zbar_image_create();
    if (!image) {
        zbar_image_scanner_destroy(scanner);
        return nil;
    }
    
    zbar_image_set_format(image, zbar_fourcc('Y','8','0','0'));
    zbar_image_set_size(image, width, height);
    // Don't use zbar_image_free_data - we'll free the data ourselves after ZBar is done
    // This prevents double-free errors since we allocated the data
    zbar_image_set_data(image, data, width * height, NULL);
    
    // Scan the image
    int n = zbar_scan_image(scanner, image);
    
    NSMutableArray *results = [NSMutableArray array];
    
    if (n > 0) {
        // Get first symbol
        const zbar_symbol_t *symbol = zbar_image_first_symbol(image);
        
        while (symbol) {
            BarcodeResult *result = [[BarcodeResult alloc] init];
            
            // Get symbol data
            zbar_symbol_type_t typ = zbar_symbol_get_type(symbol);
            const char *symbolData = zbar_symbol_get_data(symbol);
            
            if (symbolData) {
                result.data = [NSString stringWithUTF8String:symbolData];
                if (!result.data) {
                    // Fallback: create string from raw bytes
                    unsigned int dataLength = zbar_symbol_get_data_length(symbol);
                    result.data = [[NSString alloc] initWithBytes:symbolData length:dataLength encoding:NSUTF8StringEncoding];
                    if (!result.data) {
                        result.data = [[NSString alloc] initWithBytes:symbolData length:dataLength encoding:NSISOLatin1StringEncoding];
                    }
                }
            } else {
                result.data = @"";
            }
            
            const char *typeName = zbar_get_symbol_name(typ);
            result.type = typeName ? [NSString stringWithUTF8String:typeName] : @"Unknown";
            
            // Get quality score (ZBar quality is typically 0-100, but can vary)
            // zbar_symbol_get_quality returns an integer quality metric
            int zbarQuality = zbar_symbol_get_quality(symbol);
            // ZBar quality can be negative or very high, normalize to 0-100 range
            if (zbarQuality >= 0) {
                // Clamp to 0-100 range (ZBar may return values outside this)
                if (zbarQuality > 100) {
                    result.quality = 100;
                } else {
                    result.quality = zbarQuality;
                }
            } else {
                result.quality = -1; // Quality not available
            }
            
            // Get symbol location points
            NSMutableArray *points = [NSMutableArray array];
            int pointCount = zbar_symbol_get_loc_size(symbol);
            int i;
            for (i = 0; i < pointCount; i++) {
                int x = zbar_symbol_get_loc_x(symbol, i);
                int y = zbar_symbol_get_loc_y(symbol, i);
                NSRect rect = NSMakeRect(x, y, 0, 0);
                [points addObject:[NSValue valueWithRect:rect]];
            }
            result.points = points;
            
            [results addObject:result];
            [result release];
            
            // Get next symbol
            symbol = zbar_symbol_next(symbol);
        }
    }
    
    // Cleanup
    // Note: We don't free 'data' here because it's owned by the caller (BarcodeDecoder)
    // The caller will free it after we return
    zbar_image_destroy(image);
    zbar_image_scanner_destroy(scanner);
    
    return results.count > 0 ? results : nil;
#else
    return nil;
#endif
}

@end
