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
    return YES;
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
    zbar_image_set_data(image, data, width * height, zbar_image_free_data);
    
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
    zbar_image_destroy(image);
    zbar_image_scanner_destroy(scanner);
    
    return results.count > 0 ? results : nil;
#else
    return nil;
#endif
}

@end
