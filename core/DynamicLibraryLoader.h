//
//  DynamicLibraryLoader.h
//  SmallBarcodeReader
//
//  Platform-agnostic dynamic library loader
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Dynamic library handle (opaque type)
@class DynamicLibrary;

/// Platform-agnostic dynamic library loader
@interface DynamicLibraryLoader : NSObject

/// Load a dynamic library from a file path
/// @param path Path to the library file (.so on Linux, .dylib on macOS)
/// @return DynamicLibrary object, or nil on error
+ (DynamicLibrary *)loadLibraryAtPath:(NSString *)path error:(NSError **)error;

/// Unload a dynamic library
/// @param library Library to unload
+ (void)unloadLibrary:(DynamicLibrary *)library;

/// Get a symbol from a loaded library
/// @param library Loaded library
/// @param symbolName Name of the symbol to resolve
/// @return Pointer to the symbol, or NULL if not found
+ (void *)getSymbol:(NSString *)symbolName fromLibrary:(DynamicLibrary *)library;

/// Check if a library is loaded
/// @param library Library to check
/// @return YES if library is loaded, NO otherwise
+ (BOOL)isLibraryLoaded:(DynamicLibrary *)library;

/// Get error message for the last operation
/// @return Error message string, or nil if no error
+ (NSString *)lastError;

/// Find library in standard search paths
/// @param libraryName Base name of library (e.g., "zbar", "zint")
/// @return Full path to library if found, nil otherwise
+ (NSString *)findLibrary:(NSString *)libraryName;

/// Get standard library search paths
/// @return Array of directory paths where libraries are typically found
+ (NSArray *)standardSearchPaths;

/// Get library file extension for current platform
/// @return File extension (".so" for Linux, ".dylib" for macOS)
+ (NSString *)libraryExtension;

@end

/// Dynamic library handle
@interface DynamicLibrary : NSObject {
    void *_handle;
    NSString *_path;
    BOOL _isLoaded;
}

@property (readonly, nonatomic) NSString *path;
@property (readonly, nonatomic) BOOL isLoaded;

// Internal method to set handle (used by DynamicLibraryLoader)
- (void)setHandle:(void *)handle;
- (void *)handle;

@end

NS_ASSUME_NONNULL_END
