//
//  BackendFactory.h
//  SmallBarcodeReader
//
//  Factory for creating backends from dynamically loaded libraries
//

#import <Foundation/Foundation.h>

@class DynamicLibrary;
@protocol BarcodeDecoderBackend;
@protocol BarcodeEncoderBackend;

NS_ASSUME_NONNULL_BEGIN

/// Factory for creating backends from dynamic libraries
@interface BackendFactory : NSObject

/// Try to create a decoder backend from a dynamically loaded library
/// @param library Loaded dynamic library
/// @return Backend instance if successful, nil otherwise
+ (id<BarcodeDecoderBackend>)createDecoderBackendFromLibrary:(DynamicLibrary *)library;

/// Try to create an encoder backend from a dynamically loaded library
/// @param library Loaded dynamic library
/// @return Backend instance if successful, nil otherwise
+ (id<BarcodeEncoderBackend>)createEncoderBackendFromLibrary:(DynamicLibrary *)library;

/// Scan a library for known backend entry points
/// @param library Loaded dynamic library
/// @return Dictionary with "decoder" and/or "encoder" keys containing backend instances
+ (NSDictionary *)scanLibraryForBackends:(DynamicLibrary *)library;

/// Check if a library contains ZBar symbols
/// @param library Loaded dynamic library
/// @return YES if ZBar symbols are found, NO otherwise
+ (BOOL)libraryContainsZBar:(DynamicLibrary *)library;

/// Check if a library contains ZInt symbols
/// @param library Loaded dynamic library
/// @return YES if ZInt symbols are found, NO otherwise
+ (BOOL)libraryContainsZInt:(DynamicLibrary *)library;

/// Create a decoder backend from a ZBar library
/// @param library Loaded dynamic library containing ZBar
/// @return Backend instance if successful, nil otherwise
+ (id<BarcodeDecoderBackend>)createZBarDecoderFromLibrary:(DynamicLibrary *)library;

/// Create an encoder backend from a ZInt library
/// @param library Loaded dynamic library containing ZInt
/// @return Backend instance if successful, nil otherwise
+ (id<BarcodeEncoderBackend>)createZIntEncoderFromLibrary:(DynamicLibrary *)library;

/// Create a decoder backend from a ZInt library
/// @param library Loaded dynamic library containing ZInt
/// @return Backend instance if successful, nil otherwise
+ (id<BarcodeDecoderBackend>)createZIntDecoderFromLibrary:(DynamicLibrary *)library;

@end

NS_ASSUME_NONNULL_END
