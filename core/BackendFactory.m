//
//  BackendFactory.m
//  SmallBarcodeReader
//
//  Factory for creating backends from dynamically loaded libraries
//

#import "BackendFactory.h"
#import "DynamicLibraryLoader.h"
#import "BarcodeDecoderBackend.h"
#import "BarcodeEncoderBackend.h"

// Forward declarations for backend classes
@class BarcodeDecoderZBar;
@class BarcodeEncoderZInt;
@class BarcodeDecoderZInt;

@implementation BackendFactory

+ (id<BarcodeDecoderBackend>)createDecoderBackendFromLibrary:(DynamicLibrary *)library {
    if (!library || ![DynamicLibraryLoader isLibraryLoaded:library]) {
        return nil;
    }
    
    // Try to detect library type and create appropriate backend
    if ([self libraryContainsZBar:library]) {
        return [self createZBarDecoderFromLibrary:library];
    } else if ([self libraryContainsZInt:library]) {
        return [self createZIntDecoderFromLibrary:library];
    }
    
    return nil;
}

+ (id<BarcodeEncoderBackend>)createEncoderBackendFromLibrary:(DynamicLibrary *)library {
    if (!library || ![DynamicLibraryLoader isLibraryLoaded:library]) {
        return nil;
    }
    
    // Try to detect library type and create appropriate backend
    if ([self libraryContainsZInt:library]) {
        return [self createZIntEncoderFromLibrary:library];
    }
    
    return nil;
}

+ (NSDictionary *)scanLibraryForBackends:(DynamicLibrary *)library {
    NSMutableDictionary *backends = [NSMutableDictionary dictionary];
    
    if (!library || ![DynamicLibraryLoader isLibraryLoaded:library]) {
        return backends;
    }
    
    // Try to create decoder backend
    id<BarcodeDecoderBackend> decoder = [self createDecoderBackendFromLibrary:library];
    if (decoder) {
        [backends setObject:decoder forKey:@"decoder"];
    }
    
    // Try to create encoder backend
    id<BarcodeEncoderBackend> encoder = [self createEncoderBackendFromLibrary:library];
    if (encoder) {
        [backends setObject:encoder forKey:@"encoder"];
    }
    
    return backends;
}

+ (BOOL)libraryContainsZBar:(DynamicLibrary *)library {
    if (!library || ![DynamicLibraryLoader isLibraryLoaded:library]) {
        return NO;
    }
    
    // Check for ZBar symbols
    void *symbol = [DynamicLibraryLoader getSymbol:@"zbar_image_scanner_create" fromLibrary:library];
    if (symbol) {
        return YES;
    }
    
    // Try alternative symbol names
    symbol = [DynamicLibraryLoader getSymbol:@"_zbar_image_scanner_create" fromLibrary:library];
    if (symbol) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)libraryContainsZInt:(DynamicLibrary *)library {
    if (!library || ![DynamicLibraryLoader isLibraryLoaded:library]) {
        return NO;
    }
    
    // Check for ZInt symbols
    void *symbol = [DynamicLibraryLoader getSymbol:@"ZBarcode_Create" fromLibrary:library];
    if (symbol) {
        return YES;
    }
    
    // Try alternative symbol names
    symbol = [DynamicLibraryLoader getSymbol:@"_ZBarcode_Create" fromLibrary:library];
    if (symbol) {
        return YES;
    }
    
    return NO;
}

+ (id<BarcodeDecoderBackend>)createZBarDecoderFromLibrary:(DynamicLibrary *)library {
    // For now, we can't dynamically create a ZBar backend without the headers
    // This would require a wrapper class that uses dlsym to call ZBar functions
    // For Phase 2.2, we'll return nil and note that this requires a wrapper implementation
    
    // TODO: Create a dynamic ZBar wrapper that uses dlsym
    // This is complex because we need to:
    // 1. Define function pointer types for all ZBar functions we use
    // 2. Resolve all symbols at runtime
    // 3. Create a wrapper class that uses these function pointers
    
    // For now, return nil - static linking still works
    return nil;
}

+ (id<BarcodeEncoderBackend>)createZIntEncoderFromLibrary:(DynamicLibrary *)library {
    // Similar to ZBar - requires a wrapper implementation
    // TODO: Create a dynamic ZInt wrapper that uses dlsym
    
    return nil;
}

+ (id<BarcodeDecoderBackend>)createZIntDecoderFromLibrary:(DynamicLibrary *)library {
    // Similar to ZBar - requires a wrapper implementation
    // TODO: Create a dynamic ZInt decoder wrapper that uses dlsym
    
    return nil;
}

@end
