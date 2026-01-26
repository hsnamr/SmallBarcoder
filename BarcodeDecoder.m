//
//  BarcodeDecoder.m
//  SmallBarcodeReader
//
//  Barcode decoding implementation using ZBar
//

#import "BarcodeDecoder.h"
#import <zbar.h>
#import <string.h>

@implementation BarcodeResult

@end

@implementation BarcodeDecoder

- (void)dealloc {
    [super dealloc];
}

- (NSArray *)decodeBarcodesFromImage:(NSImage *)image {
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
        for (NSInteger y = 0; y < height; y++) {
            memcpy(rawData + y * width, sourceData + y * bytesPerRow, width);
        }
        needsConversion = NO;
    }
    
    if (needsConversion) {
        // Convert to grayscale
        for (NSInteger y = 0; y < height; y++) {
            for (NSInteger x = 0; x < width; x++) {
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
    
    // Use ZBar to decode (ZBar will free the data)
    NSArray *results = [self decodeWithZBar:rawData width:(unsigned)width height:(unsigned)height shouldFreeData:YES];
    
    return results;
}

- (nullable NSArray<BarcodeResult *> *)decodeBarcodesFromImageData:(NSData *)imageData {
    if (!imageData) {
        return nil;
    }
    
    NSImage *image = [[NSImage alloc] initWithData:imageData];
    if (!image) {
        return nil;
    }
    
    return [self decodeBarcodesFromImage:image];
}

- (NSArray *)decodeWithZBar:(unsigned char *)data width:(unsigned)width height:(unsigned)height shouldFreeData:(BOOL)shouldFree {
    // Create ZBar image scanner
    zbar_image_scanner_t *scanner = zbar_image_scanner_create();
    if (!scanner) {
        if (shouldFree) {
            free(data);
        }
        return nil;
    }
    
    // Configure scanner to detect all symbologies
    zbar_image_scanner_set_config(scanner, 0, ZBAR_CFG_ENABLE, 1);
    
    // Create ZBar image
    zbar_image_t *image = zbar_image_create();
    if (!image) {
        zbar_image_scanner_destroy(scanner);
        if (shouldFree) {
            free(data);
        }
        return nil;
    }
    
    zbar_image_set_format(image, zbar_fourcc('Y','8','0','0'));
    zbar_image_set_size(image, width, height);
    if (shouldFree) {
        zbar_image_set_data(image, data, width * height, zbar_image_free_data);
    } else {
        zbar_image_set_data(image, data, width * height, NULL);
    }
    
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
            const char *data = zbar_symbol_get_data(symbol);
            
            if (data) {
                result.data = [NSString stringWithUTF8String:data];
                if (!result.data) {
                    // Fallback: create string from raw bytes
                    unsigned int dataLength = zbar_symbol_get_data_length(symbol);
                    result.data = [[NSString alloc] initWithBytes:data length:dataLength encoding:NSUTF8StringEncoding];
                    if (!result.data) {
                        result.data = [[NSString alloc] initWithBytes:data length:dataLength encoding:NSISOLatin1StringEncoding];
                    }
                }
            } else {
                result.data = @"";
            }
            
            const char *typeName = zbar_get_symbol_name(typ);
            result.type = typeName ? [NSString stringWithUTF8String:typeName] : @"Unknown";
            
            // Get symbol location points
            NSMutableArray<NSValue *> *points = [NSMutableArray array];
            int pointCount = zbar_symbol_get_loc_size(symbol);
            for (int i = 0; i < pointCount; i++) {
                int x = zbar_symbol_get_loc_x(symbol, i);
                int y = zbar_symbol_get_loc_y(symbol, i);
                NSRect rect = NSMakeRect(x, y, 0, 0);
                [points addObject:[NSValue valueWithRect:rect]];
            }
            result.points = points;
            
            [results addObject:result];
            
            // Get next symbol
            symbol = zbar_symbol_next(symbol);
        }
    }
    
    // Cleanup
    zbar_image_destroy(image);
    zbar_image_scanner_destroy(scanner);
    
    return results.count > 0 ? results : nil;
}

@end
