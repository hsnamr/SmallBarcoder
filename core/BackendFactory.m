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
    // Check if ZInt symbols are available
    if (![self libraryContainsZInt:library]) {
        return nil;
    }
    
    // For now, if the library is loaded and contains ZInt symbols,
    // we can try to create a BarcodeEncoderZInt instance
    // This works because BarcodeEncoderZInt uses the ZInt functions directly
    // which should resolve from the dynamically loaded library
    
    // Import the backend class (it should be available if compiled in)
#if defined(HAVE_ZINT) || __has_include(<zint.h>)
    // Try to create an instance - the ZInt functions should resolve from the loaded library
    Class encoderClass = NSClassFromString(@"BarcodeEncoderZInt");
    if (encoderClass && [encoderClass respondsToSelector:@selector(isAvailable)]) {
        // Create instance - the library is already loaded, so symbols should resolve
        id encoder = [[encoderClass alloc] init];
        if (encoder) {
            return [encoder autorelease];
        }
    }
#endif
    
    return nil;
}

+ (id<BarcodeDecoderBackend>)createZIntDecoderFromLibrary:(DynamicLibrary *)library {
    // Check if ZInt symbols are available
    if (![self libraryContainsZInt:library]) {
        return nil;
    }
    
    // Try to create a BarcodeDecoderZInt instance
#if defined(HAVE_ZINT) || __has_include(<zint.h>)
    Class decoderClass = NSClassFromString(@"BarcodeDecoderZInt");
    if (decoderClass && [decoderClass respondsToSelector:@selector(isAvailable)]) {
        id decoder = [[decoderClass alloc] init];
        if (decoder) {
            return [decoder autorelease];
        }
    }
#endif
    
    return nil;
}

@end
