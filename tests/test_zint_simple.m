#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "encoder/BarcodeEncoder.h"

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"=== ZInt Encoding Test ===");
    
    BarcodeEncoder *encoder = [[BarcodeEncoder alloc] init];
    
    if (![encoder hasBackend]) {
        NSLog(@"ERROR: No encoder backend available");
        [encoder release];
        [pool release];
        return 1;
    }
    
    NSLog(@"Backend: %@", [encoder backendName]);
    
    NSArray *symbologies = [encoder supportedSymbologies];
    NSLog(@"Found %ld symbologies", (long)symbologies.count);
    
    // Find QR Code (ID 58)
    int qrCodeId = 58;
    NSImage *image = [encoder encodeBarcodeFromData:@"Hello World" symbology:qrCodeId];
    
    if (image) {
        NSSize size = [image size];
        NSLog(@"SUCCESS: Encoded QR Code");
        NSLog(@"Image size: %.0f x %.0f", size.width, size.height);
        NSLog(@"TEST PASSED!");
    } else {
        NSLog(@"ERROR: Encoding failed");
        [encoder release];
        [pool release];
        return 1;
    }
    
    [encoder release];
    [pool release];
    return 0;
}
