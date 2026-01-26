//
//  BarcodeTester.h
//  SmallBarcodeReader
//
//  Automated barcode decodability testing framework
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "BarcodeTestResult.h"

@class BarcodeEncoder;
@class BarcodeDecoder;
@class ImageDistorter;
@class BarcodeTestSession;

NS_ASSUME_NONNULL_BEGIN

/// Automated barcode testing framework
@interface BarcodeTester : NSObject {
    BarcodeEncoder *encoder;
    BarcodeDecoder *decoder;
    ImageDistorter *distorter;
}

/// Initialize with encoder and decoder
- (instancetype)initWithEncoder:(BarcodeEncoder *)encoder decoder:(BarcodeDecoder *)decoder;

/// Run a single test
/// @param testData Data to encode
/// @param symbology Barcode symbology ID
/// @param distortionType Distortion type to apply
/// @param intensity Distortion intensity (0.0 to 1.0)
/// @param strength Distortion strength (0.0 to 1.0)
/// @return Test result
- (BarcodeTestResult *)runTestWithData:(NSString *)testData
                              symbology:(int)symbology
                          distortionType:(NSInteger)distortionType
                               intensity:(float)intensity
                                 strength:(float)strength;

/// Run progressive distortion test (gradually increase intensity)
/// @param testData Data to encode
/// @param symbology Barcode symbology ID
/// @param distortionType Distortion type to apply
/// @param startIntensity Starting intensity
/// @param endIntensity Ending intensity
/// @param steps Number of steps
/// @param session Test session to add results to
/// @return Array of test results
- (NSArray *)runProgressiveTestWithData:(NSString *)testData
                                symbology:(int)symbology
                            distortionType:(NSInteger)distortionType
                             startIntensity:(float)startIntensity
                               endIntensity:(float)endIntensity
                                      steps:(NSInteger)steps
                                     session:(BarcodeTestSession *)session;

/// Run comprehensive test suite
/// @param testDataArray Array of test data strings
/// @param symbologyArray Array of symbology IDs
/// @param distortionTypes Array of distortion type IDs
/// @param intensityLevels Array of intensity values
/// @param strengthLevels Array of strength values
/// @param sessionName Name for the test session
/// @return Test session with all results
- (BarcodeTestSession *)runComprehensiveTestSuite:(NSArray *)testDataArray
                                       symbologies:(NSArray *)symbologyArray
                                    distortionTypes:(NSArray *)distortionTypes
                                     intensityLevels:(NSArray *)intensityLevels
                                       strengthLevels:(NSArray *)strengthLevels
                                         sessionName:(NSString *)sessionName;

/// Find minimum distortion level that causes failure
/// @param testData Data to encode
/// @param symbology Barcode symbology ID
/// @param distortionType Distortion type to apply
/// @param maxIntensity Maximum intensity to test
/// @param steps Number of steps
/// @return Minimum intensity that causes failure, or -1 if always succeeds
- (float)findFailureThresholdWithData:(NSString *)testData
                              symbology:(int)symbology
                          distortionType:(NSInteger)distortionType
                            maxIntensity:(float)maxIntensity
                                   steps:(NSInteger)steps;

@end

NS_ASSUME_NONNULL_END
