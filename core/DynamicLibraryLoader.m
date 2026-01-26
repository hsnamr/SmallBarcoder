//
//  DynamicLibraryLoader.m
//  SmallBarcodeReader
//
//  Platform-agnostic dynamic library loader implementation
//

#import "DynamicLibraryLoader.h"
#import "../SmallStep/SmallStep/Core/SmallStep.h"
#import <dlfcn.h>
#import <string.h>

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#endif

static NSString *_lastError = nil;

@implementation DynamicLibrary

@synthesize path = _path;
@synthesize isLoaded = _isLoaded;

- (instancetype)initWithHandle:(void *)handle path:(NSString *)path {
    self = [super init];
    if (self) {
        _handle = handle;
        _path = [path retain];
        _isLoaded = (handle != NULL);
    }
    return self;
}

- (void)dealloc {
    if (_handle) {
        dlclose(_handle);
        _handle = NULL;
    }
    [_path release];
    [super dealloc];
}

- (void)setHandle:(void *)handle {
    if (_handle && _handle != handle) {
        dlclose(_handle);
    }
    _handle = handle;
    _isLoaded = (handle != NULL);
}

- (void *)handle {
    return _handle;
}

- (BOOL)isLoaded {
    return _isLoaded;
}

@end

@implementation DynamicLibraryLoader

+ (NSString *)libraryExtension {
#if TARGET_OS_IPHONE || TARGET_OS_WIN32
    // Dynamic library loading not supported on iOS/Windows
    return nil;
#elif TARGET_OS_MAC && !TARGET_OS_IPHONE
    return @".dylib";
#else
    return @".so";
#endif
}

+ (NSArray *)standardSearchPaths {
#if TARGET_OS_IPHONE || TARGET_OS_WIN32
    // Dynamic library loading not supported on iOS/Windows
    return [NSArray array];
#else
    NSMutableArray *paths = [NSMutableArray array];
    
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
    // macOS paths
    [paths addObject:@"/usr/local/lib"];
    [paths addObject:@"/opt/homebrew/lib"];
    [paths addObject:[@"~/lib" stringByExpandingTildeInPath]];
    [paths addObject:[@"~/Library/Frameworks" stringByExpandingTildeInPath]];
    [paths addObject:@"/Library/Frameworks"];
    [paths addObject:@"/System/Library/Frameworks"];
#else
    // Linux paths
    [paths addObject:@"/usr/lib"];
    [paths addObject:@"/usr/local/lib"];
    [paths addObject:@"/lib"];
    [paths addObject:@"/lib64"];
    [paths addObject:[@"~/lib" stringByExpandingTildeInPath]];
    
    // Check LD_LIBRARY_PATH
    NSString *ldLibraryPath = [[[NSProcessInfo processInfo] environment] objectForKey:@"LD_LIBRARY_PATH"];
    if (ldLibraryPath) {
        NSArray *ldPaths = [ldLibraryPath componentsSeparatedByString:@":"];
        [paths addObjectsFromArray:ldPaths];
    }
#endif
    
    return paths;
#endif
}

+ (NSString *)findLibrary:(NSString *)libraryName {
    if (!libraryName || libraryName.length == 0) {
        return nil;
    }
    
    NSString *extension = [self libraryExtension];
    NSArray *searchPaths = [self standardSearchPaths];
    
    // Try with "lib" prefix
    NSString *baseName = libraryName;
    if (![baseName hasPrefix:@"lib"]) {
        baseName = [NSString stringWithFormat:@"lib%@", libraryName];
    }
    
    // Try various naming patterns
    NSArray *namePatterns = [NSArray arrayWithObjects:
        [NSString stringWithFormat:@"%@%@", baseName, extension],
        [NSString stringWithFormat:@"%@.0%@", baseName, extension],
        [NSString stringWithFormat:@"%@.1%@", baseName, extension],
        [NSString stringWithFormat:@"%@.2%@", baseName, extension],
        nil];
    
    NSInteger i, j;
    for (i = 0; i < searchPaths.count; i++) {
        NSString *searchPath = [searchPaths objectAtIndex:i];
        for (j = 0; j < namePatterns.count; j++) {
            NSString *fullPath = [searchPath stringByAppendingPathComponent:[namePatterns objectAtIndex:j]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                return fullPath;
            }
        }
    }
    
    return nil;
}

+ (DynamicLibrary *)loadLibraryAtPath:(NSString *)path error:(NSError **)error {
#if TARGET_OS_IPHONE || TARGET_OS_WIN32
    // Dynamic library loading not supported on iOS/Windows
    if (error) {
        *error = [NSError errorWithDomain:@"DynamicLibraryLoader" code:100 userInfo:
            [NSDictionary dictionaryWithObject:@"Dynamic library loading is not supported on this platform. Libraries must be statically linked." forKey:NSLocalizedDescriptionKey]];
    }
    _lastError = @"Dynamic library loading not supported on this platform";
    return nil;
#else
    if (!path || path.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"DynamicLibraryLoader" code:1 userInfo:
                [NSDictionary dictionaryWithObject:@"Invalid library path" forKey:NSLocalizedDescriptionKey]];
        }
        _lastError = @"Invalid library path";
        return nil;
    }
    
    // Check if file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (error) {
            *error = [NSError errorWithDomain:@"DynamicLibraryLoader" code:2 userInfo:
                [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Library file not found: %@", path] forKey:NSLocalizedDescriptionKey]];
        }
        _lastError = [NSString stringWithFormat:@"Library file not found: %@", path];
        return nil;
    }
    
    // Load library using dlopen
    void *handle = dlopen([path UTF8String], RTLD_LAZY | RTLD_LOCAL);
    if (!handle) {
        const char *dlError = dlerror();
        NSString *errorMsg = dlError ? [NSString stringWithUTF8String:dlError] : @"Unknown error";
        if (error) {
            *error = [NSError errorWithDomain:@"DynamicLibraryLoader" code:3 userInfo:
                [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey]];
        }
        _lastError = errorMsg;
        return nil;
    }
    
    _lastError = nil;
    return [[[DynamicLibrary alloc] initWithHandle:handle path:path] autorelease];
#endif
}

+ (void)unloadLibrary:(DynamicLibrary *)library {
    if (library) {
        void *handle = [library handle];
        if (handle) {
            dlclose(handle);
            [library setHandle:NULL];
        }
    }
}

+ (void *)getSymbol:(NSString *)symbolName fromLibrary:(DynamicLibrary *)library {
    if (!symbolName || symbolName.length == 0 || !library) {
        _lastError = @"Invalid symbol name or library";
        return NULL;
    }
    
    void *handle = [library handle];
    if (!handle) {
        _lastError = @"Library not loaded";
        return NULL;
    }
    
    void *symbol = dlsym(handle, [symbolName UTF8String]);
    if (!symbol) {
        const char *dlError = dlerror();
        _lastError = dlError ? [NSString stringWithUTF8String:dlError] : @"Symbol not found";
        return NULL;
    }
    
    _lastError = nil;
    return symbol;
}

+ (BOOL)isLibraryLoaded:(DynamicLibrary *)library {
    return library && [library isLoaded];
}

+ (NSString *)lastError {
    return _lastError;
}

@end
