//
//  BarcodeEncoder.m
//  SmallBarcodeReader
//
//  Generic barcode encoder implementation
//

#import "BarcodeEncoder.h"
#import "BarcodeEncoderBackend.h"
#import <string.h>

// Conditionally import ZInt if available
#if defined(HAVE_ZINT)
#import "BarcodeEncoderZInt.h"
#define ZINT_BACKEND_AVAILABLE 1
#else
#define ZINT_BACKEND_AVAILABLE 0
#endif

// Encoding option keys
NSString * const BarcodeEncoderOptionWidth = @"width";
NSString * const BarcodeEncoderOptionHeight = @"height";
NSString * const BarcodeEncoderOptionScale = @"scale";
NSString * const BarcodeEncoderOptionBorderWidth = @"borderWidth";
NSString * const BarcodeEncoderOptionErrorCorrection = @"errorCorrection";
NSString * const BarcodeEncoderOptionForegroundColor = @"foregroundColor";
NSString * const BarcodeEncoderOptionBackgroundColor = @"backgroundColor";

@implementation BarcodeEncoder

+ (NSArray *)availableBackends {
    NSMutableArray *backends = [NSMutableArray array];
    
    // Check ZInt (if compiled in)
#if ZINT_BACKEND_AVAILABLE
    if ([BarcodeEncoderZInt isAvailable]) {
        [backends addObject:[BarcodeEncoderZInt backendName]];
    }
#endif
    
    return backends;
}

- (instancetype)init {
    // Auto-detect and use first available backend
    // If no backend is available, still initialize (backend will be nil)
    // This allows the app to run and show a graceful error message
    id backend = nil;
    
    // Try ZInt (if compiled in)
#if ZINT_BACKEND_AVAILABLE
    if ([BarcodeEncoderZInt isAvailable]) {
        backend = [[BarcodeEncoderZInt alloc] init];
    }
#endif
    
    // Initialize even if no backend is available
    // The app will show a graceful error message when encoding is attempted
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

- (void)registerDynamicBackend:(id<BarcodeEncoderBackend>)backend {
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

- (NSImage *)encodeBarcodeFromData:(NSString *)data symbology:(int)symbology options:(NSDictionary *)options {
    // Check if backend is available
    if (!_backend) {
        return nil; // No backend available - caller should show error message
    }
    
    if (!data || data.length == 0) {
        return nil;
    }
    
    // Use backend to encode
    if (_backend && [_backend respondsToSelector:@selector(encodeBarcodeFromData:symbology:options:)]) {
        return [_backend encodeBarcodeFromData:data symbology:symbology options:options];
    }
    
    return nil;
}

- (NSImage *)encodeBarcodeFromData:(NSString *)data symbology:(int)symbology {
    return [self encodeBarcodeFromData:data symbology:symbology options:nil];
}

- (NSArray *)supportedSymbologies {
    if (_backend && [_backend respondsToSelector:@selector(supportedSymbologies)]) {
        return [_backend performSelector:@selector(supportedSymbologies)];
    }
    return [NSArray array];
}

@end
