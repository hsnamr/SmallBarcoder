//
//  ImageDistorter.h
//  SmallBarcodeReader
//
//  Image distortion pipeline for testing decodability
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Distortion types
typedef NS_ENUM(NSInteger, DistortionType) {
    DistortionTypeNone = 0,
    DistortionTypeGaussianBlur,
    DistortionTypeBoxBlur,
    DistortionTypeSharpen,
    DistortionTypeEdgeDetection,
    DistortionTypeMotionBlur,
    DistortionTypeLaplacian,
    DistortionTypeRotate,
    DistortionTypeScale,
    DistortionTypeSkew,
    DistortionTypeNoise
};

/// Distortion parameters
@interface DistortionParameters : NSObject {
    DistortionType type;
    float intensity;      // 0.0 to 1.0
    float strength;       // Additional parameter (kernel size, angle, etc.)
    float strength2;     // Second parameter if needed
}

@property (assign, nonatomic) DistortionType type;
@property (assign, nonatomic) float intensity;
@property (assign, nonatomic) float strength;
@property (assign, nonatomic) float strength2;

+ (instancetype)parametersWithType:(DistortionType)type intensity:(float)intensity strength:(float)strength;
+ (instancetype)parametersWithType:(DistortionType)type intensity:(float)intensity strength:(float)strength strength2:(float)strength2;

@end

/// Image distortion pipeline
@interface ImageDistorter : NSObject {
    NSMutableArray *distortions; // Array of DistortionParameters
}

/// Initialize empty distorter
- (instancetype)init;

/// Add a distortion to the pipeline
/// @param parameters Distortion parameters
- (void)addDistortion:(DistortionParameters *)parameters;

/// Remove all distortions
- (void)clearDistortions;

/// Get all distortions
- (NSArray *)distortions;

/// Apply all distortions to an image
/// @param image Source image
/// @return Distorted image (new instance)
- (NSImage *)applyDistortionsToImage:(NSImage *)image;

/// Apply a single distortion to an image
/// @param image Source image
/// @param parameters Distortion parameters
/// @return Distorted image (new instance)
+ (NSImage *)applyDistortion:(DistortionParameters *)parameters toImage:(NSImage *)image;

/// Get distortion type name
/// @param type Distortion type
/// @return Human-readable name
+ (NSString *)nameForDistortionType:(DistortionType)type;

/// Get all available distortion types
/// @return Array of distortion type names
+ (NSArray *)availableDistortionTypes;

@end

NS_ASSUME_NONNULL_END
