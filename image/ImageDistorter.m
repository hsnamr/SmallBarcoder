//
//  ImageDistorter.m
//  SmallBarcodeReader
//
//  Image distortion pipeline implementation
//

#import "ImageDistorter.h"
#import "ImageMatrix.h"
#import <math.h>
#import <stdlib.h>

@implementation DistortionParameters

@synthesize type;
@synthesize intensity;
@synthesize strength;
@synthesize strength2;

+ (instancetype)parametersWithType:(DistortionType)type intensity:(float)intensity strength:(float)strength {
    DistortionParameters *params = [[DistortionParameters alloc] init];
    params.type = type;
    params.intensity = intensity;
    params.strength = strength;
    params.strength2 = 0.0f;
    return [params autorelease];
}

+ (instancetype)parametersWithType:(DistortionType)type intensity:(float)intensity strength:(float)strength strength2:(float)strength2 {
    DistortionParameters *params = [[DistortionParameters alloc] init];
    params.type = type;
    params.intensity = intensity;
    params.strength = strength;
    params.strength2 = strength2;
    return [params autorelease];
}

@end

@implementation ImageDistorter

- (instancetype)init {
    self = [super init];
    if (self) {
        distortions = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [distortions release];
    [super dealloc];
}

- (void)addDistortion:(DistortionParameters *)parameters {
    if (parameters) {
        [distortions addObject:parameters];
    }
}

- (void)clearDistortions {
    [distortions removeAllObjects];
}

- (NSArray *)distortions {
    return [NSArray arrayWithArray:distortions];
}

- (NSImage *)applyDistortionsToImage:(NSImage *)image {
    if (!image) {
        return nil;
    }
    
    NSImage *result = image;
    NSInteger i;
    for (i = 0; i < distortions.count; i++) {
        DistortionParameters *params = [distortions objectAtIndex:i];
        result = [[self class] applyDistortion:params toImage:result];
        if (!result) {
            return nil; // Distortion failed
        }
    }
    
    return result;
}

+ (NSString *)nameForDistortionType:(DistortionType)type {
    switch (type) {
        case DistortionTypeNone:
            return @"None";
        case DistortionTypeGaussianBlur:
            return @"Gaussian Blur";
        case DistortionTypeBoxBlur:
            return @"Box Blur";
        case DistortionTypeSharpen:
            return @"Sharpen";
        case DistortionTypeEdgeDetection:
            return @"Edge Detection";
        case DistortionTypeMotionBlur:
            return @"Motion Blur";
        case DistortionTypeLaplacian:
            return @"Laplacian";
        case DistortionTypeRotate:
            return @"Rotate";
        case DistortionTypeScale:
            return @"Scale";
        case DistortionTypeSkew:
            return @"Skew";
        case DistortionTypeNoise:
            return @"Noise";
        default:
            return @"Unknown";
    }
}

+ (NSArray *)availableDistortionTypes {
    return [NSArray arrayWithObjects:
        [NSNumber numberWithInt:DistortionTypeGaussianBlur],
        [NSNumber numberWithInt:DistortionTypeBoxBlur],
        [NSNumber numberWithInt:DistortionTypeSharpen],
        [NSNumber numberWithInt:DistortionTypeEdgeDetection],
        [NSNumber numberWithInt:DistortionTypeMotionBlur],
        [NSNumber numberWithInt:DistortionTypeLaplacian],
        [NSNumber numberWithInt:DistortionTypeRotate],
        [NSNumber numberWithInt:DistortionTypeScale],
        [NSNumber numberWithInt:DistortionTypeSkew],
        [NSNumber numberWithInt:DistortionTypeNoise],
        nil];
}

// Helper function to apply convolution kernel to grayscale image
static unsigned char *applyConvolution(unsigned char *data, int width, int height, ImageMatrix kernel) {
    if (!data || width <= 0 || height <= 0) {
        return NULL;
    }
    
    unsigned char *result = (unsigned char *)malloc(width * height);
    if (!result) {
        return NULL;
    }
    
    int kernelSize = kernel.rows;
    int halfKernel = kernelSize / 2;
    
    int y, x;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            float sum = 0.0f;
            int ky, kx;
            for (ky = 0; ky < kernelSize; ky++) {
                for (kx = 0; kx < kernelSize; kx++) {
                    int px = x + kx - halfKernel;
                    int py = y + ky - halfKernel;
                    
                    // Handle boundaries (clamp to edge)
                    if (px < 0) px = 0;
                    if (px >= width) px = width - 1;
                    if (py < 0) py = 0;
                    if (py >= height) py = height - 1;
                    
                    float kernelValue = ImageMatrixGet(kernel, ky, kx);
                    sum += data[py * width + px] * kernelValue;
                }
            }
            
            // Clamp to 0-255
            int value = (int)(sum + 0.5f);
            if (value < 0) value = 0;
            if (value > 255) value = 255;
            result[y * width + x] = (unsigned char)value;
        }
    }
    
    return result;
}

// Helper function to convert NSImage to grayscale buffer
static unsigned char *imageToGrayscale(NSImage *image, int *width, int *height) {
    if (!image) {
        return NULL;
    }
    
    NSData *tiffData = [image TIFFRepresentation];
    if (!tiffData) {
        return NULL;
    }
    
    NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:tiffData];
    if (!bitmapRep) {
        return NULL;
    }
    
    *width = (int)[bitmapRep pixelsWide];
    *height = (int)[bitmapRep pixelsHigh];
    int bitsPerPixel = (int)[bitmapRep bitsPerPixel];
    int bytesPerRow = (int)[bitmapRep bytesPerRow];
    
    unsigned char *grayData = (unsigned char *)malloc(*width * *height);
    if (!grayData) {
        return NULL;
    }
    
    unsigned char *sourceData = (unsigned char *)[bitmapRep bitmapData];
    
    int y, x;
    for (y = 0; y < *height; y++) {
        for (x = 0; x < *width; x++) {
            int sourceIndex = y * bytesPerRow + x * (bitsPerPixel / 8);
            int destIndex = y * *width + x;
            
            if (bitsPerPixel == 32) {
                // RGBA
                unsigned char r = sourceData[sourceIndex];
                unsigned char g = sourceData[sourceIndex + 1];
                unsigned char b = sourceData[sourceIndex + 2];
                grayData[destIndex] = (unsigned char)(0.299 * r + 0.587 * g + 0.114 * b);
            } else if (bitsPerPixel == 24) {
                // RGB
                unsigned char r = sourceData[sourceIndex];
                unsigned char g = sourceData[sourceIndex + 1];
                unsigned char b = sourceData[sourceIndex + 2];
                grayData[destIndex] = (unsigned char)(0.299 * r + 0.587 * g + 0.114 * b);
            } else if (bitsPerPixel == 8) {
                grayData[destIndex] = sourceData[sourceIndex];
            } else {
                grayData[destIndex] = 128; // Default gray
            }
        }
    }
    
    return grayData;
}

// Helper function to convert grayscale buffer to NSImage
static NSImage *grayscaleToImage(unsigned char *data, int width, int height) {
    if (!data || width <= 0 || height <= 0) {
        return nil;
    }
    
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] 
        initWithBitmapDataPlanes:NULL
        pixelsWide:width
        pixelsHigh:height
        bitsPerSample:8
        samplesPerPixel:1
        hasAlpha:NO
        isPlanar:NO
        colorSpaceName:NSCalibratedWhiteColorSpace
        bytesPerRow:width
        bitsPerPixel:8];
    
    if (!bitmapRep) {
        return nil;
    }
    
    unsigned char *bitmapData = [bitmapRep bitmapData];
    memcpy(bitmapData, data, width * height);
    
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    [bitmapRep release];
    
    return [image autorelease];
}

+ (NSImage *)applyDistortion:(DistortionParameters *)parameters toImage:(NSImage *)image {
    if (!parameters || !image || parameters.type == DistortionTypeNone) {
        return image;
    }
    
    int width, height;
    unsigned char *grayData = imageToGrayscale(image, &width, &height);
    if (!grayData) {
        return nil;
    }
    
    unsigned char *resultData = NULL;
    ImageMatrix kernel;
    int kernelSize;
    
    switch (parameters.type) {
        case DistortionTypeGaussianBlur: {
            kernelSize = 3 + (int)(parameters.strength * 8); // 3 to 11
            if (kernelSize % 2 == 0) kernelSize++;
            float sigma = 1.0f + parameters.intensity * 3.0f;
            kernel = ImageMatrixGaussianBlur(kernelSize, sigma);
            resultData = applyConvolution(grayData, width, height, kernel);
            ImageMatrixFree(&kernel);
            break;
        }
        
        case DistortionTypeBoxBlur: {
            kernelSize = 3 + (int)(parameters.strength * 8); // 3 to 11
            if (kernelSize % 2 == 0) kernelSize++;
            kernel = ImageMatrixBoxBlur(kernelSize);
            resultData = applyConvolution(grayData, width, height, kernel);
            ImageMatrixFree(&kernel);
            break;
        }
        
        case DistortionTypeSharpen: {
            kernel = ImageMatrixSharpen();
            // Blend with original based on intensity
            unsigned char *sharpData = applyConvolution(grayData, width, height, kernel);
            if (sharpData) {
                resultData = (unsigned char *)malloc(width * height);
                int i;
                for (i = 0; i < width * height; i++) {
                    float blended = grayData[i] * (1.0f - parameters.intensity) + 
                                   sharpData[i] * parameters.intensity;
                    resultData[i] = (unsigned char)(blended + 0.5f);
                }
                free(sharpData);
            }
            ImageMatrixFree(&kernel);
            break;
        }
        
        case DistortionTypeEdgeDetection: {
            kernel = ImageMatrixEdgeDetection((int)parameters.strength); // 0 or 1
            resultData = applyConvolution(grayData, width, height, kernel);
            ImageMatrixFree(&kernel);
            break;
        }
        
        case DistortionTypeMotionBlur: {
            int length = 3 + (int)(parameters.strength * 10); // 3 to 13
            if (length % 2 == 0) length++;
            float angle = parameters.strength2 * 360.0f; // 0 to 360 degrees
            kernel = ImageMatrixMotionBlur(length, angle);
            resultData = applyConvolution(grayData, width, height, kernel);
            ImageMatrixFree(&kernel);
            break;
        }
        
        case DistortionTypeLaplacian: {
            kernel = ImageMatrixLaplacian();
            resultData = applyConvolution(grayData, width, height, kernel);
            ImageMatrixFree(&kernel);
            break;
        }
        
        case DistortionTypeRotate: {
            // Simple rotation (90, 180, 270 degrees)
            float angle = parameters.strength * 360.0f;
            int angleInt = ((int)(angle / 90.0f + 0.5f)) % 4;
            
            resultData = (unsigned char *)malloc(width * height);
            int y, x;
            for (y = 0; y < height; y++) {
                for (x = 0; x < width; x++) {
                    int srcX, srcY;
                    switch (angleInt) {
                        case 1: // 90 degrees
                            srcX = height - 1 - y;
                            srcY = x;
                            break;
                        case 2: // 180 degrees
                            srcX = width - 1 - x;
                            srcY = height - 1 - y;
                            break;
                        case 3: // 270 degrees
                            srcX = y;
                            srcY = width - 1 - x;
                            break;
                        default: // 0 degrees
                            srcX = x;
                            srcY = y;
                            break;
                    }
                    if (srcX >= 0 && srcX < width && srcY >= 0 && srcY < height) {
                        resultData[y * width + x] = grayData[srcY * width + srcX];
                    } else {
                        resultData[y * width + x] = 255; // White background
                    }
                }
            }
            break;
        }
        
        case DistortionTypeScale: {
            float scaleX = 0.5f + parameters.strength * 1.5f; // 0.5 to 2.0
            float scaleY = 0.5f + parameters.strength2 * 1.5f;
            if (scaleY <= 0) scaleY = scaleX; // Use scaleX if scaleY not set
            
            int newWidth = (int)(width * scaleX + 0.5f);
            int newHeight = (int)(height * scaleY + 0.5f);
            if (newWidth < 1) newWidth = 1;
            if (newHeight < 1) newHeight = 1;
            
            unsigned char *scaledData = (unsigned char *)malloc(newWidth * newHeight);
            if (scaledData) {
                int y, x;
                for (y = 0; y < newHeight; y++) {
                    for (x = 0; x < newWidth; x++) {
                        int srcX = (int)(x / scaleX + 0.5f);
                        int srcY = (int)(y / scaleY + 0.5f);
                        if (srcX >= 0 && srcX < width && srcY >= 0 && srcY < height) {
                            scaledData[y * newWidth + x] = grayData[srcY * width + srcX];
                        } else {
                            scaledData[y * newWidth + x] = 255;
                        }
                    }
                }
                free(grayData);
                grayData = scaledData;
                width = newWidth;
                height = newHeight;
                resultData = grayData;
                grayData = NULL; // Don't free it, resultData points to it
            }
            break;
        }
        
        case DistortionTypeNoise: {
            resultData = (unsigned char *)malloc(width * height);
            if (resultData) {
                int i;
                for (i = 0; i < width * height; i++) {
                    float noise = (float)(rand() % 256 - 128) * parameters.intensity;
                    float value = grayData[i] + noise;
                    if (value < 0) value = 0;
                    if (value > 255) value = 255;
                    resultData[i] = (unsigned char)(value + 0.5f);
                }
            }
            break;
        }
        
        default:
            free(grayData);
            return image;
    }
    
    free(grayData);
    
    if (!resultData) {
        return nil;
    }
    
    NSImage *result = grayscaleToImage(resultData, width, height);
    free(resultData);
    
    return result;
}

@end
