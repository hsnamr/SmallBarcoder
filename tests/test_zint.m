//
//  test_zint.m
//  Simple test to verify ZInt encoding works
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "encoder/BarcodeEncoder.h"
#import "encoder/BarcodeEncoderZInt.h"

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"=== ZInt Encoding Test ===");
    
    // Check if ZInt backend is available
    BOOL isAvailable = [BarcodeEncoderZInt isAvailable];
    NSLog(@"ZInt Backend Available: %@", isAvailable ? @"YES" : @"NO");
    
    if (!isAvailable) {
        NSLog(@"ERROR: ZInt backend is not available!");
        [pool release];
        return 1;
    }
    
    // Create encoder
    BarcodeEncoder *encoder = [[BarcodeEncoder alloc] init];
    BOOL hasBackend = [encoder hasBackend];
    NSString *backendName = [encoder backendName];
    
    NSLog(@"Encoder Backend: %@", backendName);
    NSLog(@"Has Backend: %@", hasBackend ? @"YES" : @"NO");
    
    if (!hasBackend) {
        NSLog(@"ERROR: Encoder has no backend!");
        [encoder release];
        [pool release];
        return 1;
    }
    
    // Get supported symbologies
    NSArray *symbologies = [encoder supportedSymbologies];
    NSLog(@"Supported Symbologies: %ld", (long)symbologies.count);
    
    // Find QR Code symbology
    int qrCodeSymbology = -1;
    NSInteger i;
    for (i = 0; i < symbologies.count; i++) {
        NSDictionary *symbology = [symbologies objectAtIndex:i];
        NSString *name = [symbology objectForKey:@"name"];
        if ([name isEqualToString:@"QR Code"]) {
            NSNumber *symbologyId = [symbology objectForKey:@"id"];
            qrCodeSymbology = [symbologyId intValue];
            NSLog(@"Found QR Code symbology: ID = %d", qrCodeSymbology);
            break;
        }
    }
    
    if (qrCodeSymbology == -1) {
        NSLog(@"ERROR: QR Code symbology not found!");
        [encoder release];
        [pool release];
        return 1;
    }
    
    // Test encoding "Hello World" as QR Code
    NSString *testData = @"Hello World";
    NSLog(@"\nEncoding: '%@' as QR Code...", testData);
    
    NSImage *encodedImage = [encoder encodeBarcodeFromData:testData symbology:qrCodeSymbology];
    
    if (encodedImage) {
        NSSize imageSize = [encodedImage size];
        NSLog(@"SUCCESS: Barcode encoded successfully!");
        NSLog(@"Image size: %.0f x %.0f", imageSize.width, imageSize.height);
        
        // Try to save the image to verify it's valid
        NSData *tiffData = [encodedImage TIFFRepresentation];
        if (tiffData && tiffData.length > 0) {
            NSLog(@"Image data size: %lu bytes", (unsigned long)tiffData.length);
            NSLog(@"\n✓ TEST PASSED: ZInt encoding works correctly!");
        } else {
            NSLog(@"WARNING: Image has no data representation");
        }
    } else {
        NSLog(@"ERROR: Encoding failed - returned nil");
        [encoder release];
        [pool release];
        return 1;
    }
    
    [encoder release];
    [pool release];
    return 0;
}
