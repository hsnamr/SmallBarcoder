//
//  BarcodeTester.m
//  SmallBarcodeReader
//
//  Automated barcode testing framework implementation
//

#import "BarcodeTester.h"
#import "BarcodeEncoder.h"
#import "BarcodeDecoder.h"
#import "ImageDistorter.h"
#import "BarcodeTestResult.h"

@implementation BarcodeTester

- (instancetype)initWithEncoder:(BarcodeEncoder *)enc decoder:(BarcodeDecoder *)dec {
    self = [super init];
    if (self) {
        encoder = [enc retain];
        decoder = [dec retain];
        distorter = [[ImageDistorter alloc] init];
    }
    return self;
}

- (void)dealloc {
    [encoder release];
    [decoder release];
    [distorter release];
    [super dealloc];
}

- (BarcodeTestResult *)runTestWithData:(NSString *)testData
                              symbology:(int)symbology
                          distortionType:(NSInteger)distortionType
                               intensity:(float)intensity
                                 strength:(float)strength {
    if (!encoder || ![encoder hasBackend] || !decoder || ![decoder hasBackend]) {
        return nil;
    }
    
    // Encode barcode
    NSImage *encodedImage = [encoder encodeBarcodeFromData:testData symbology:symbology];
    if (!encodedImage) {
        return nil;
    }
    
    // Apply distortion
    DistortionParameters *params = [DistortionParameters parametersWithType:(DistortionType)distortionType 
                                                                   intensity:intensity 
                                                                     strength:strength];
    NSImage *distortedImage = [ImageDistorter applyDistortion:params toImage:encodedImage];
    if (!distortedImage) {
        distortedImage = encodedImage; // Use original if distortion fails
    }
    
    // Decode
    NSArray *results = [decoder decodeBarcodesFromImage:distortedImage originalInput:testData];
    
    // Analyze results
    BOOL decodeSuccess = (results != nil && results.count > 0);
    NSInteger qualityScore = -1;
    BOOL dataMatches = NO;
    NSString *decodedData = @"";
    
    if (decodeSuccess && results.count > 0) {
        BarcodeResult *result = [results objectAtIndex:0];
        qualityScore = result.quality;
        decodedData = result.data ? result.data : @"";
        dataMatches = [decodedData isEqualToString:testData];
    }
    
    // Get barcode type name
    NSArray *symbologies = [encoder supportedSymbologies];
    NSString *barcodeTypeName = @"Unknown";
    NSInteger i;
    int targetSymbology = symbology;
    for (i = 0; i < symbologies.count; i++) {
        NSDictionary *symbology = [symbologies objectAtIndex:i];
        NSNumber *symbologyId = [symbology objectForKey:@"id"];
        if (symbologyId && [symbologyId intValue] == targetSymbology) {
            barcodeTypeName = [symbology objectForKey:@"name"];
            break;
        }
    }
    
    if ([barcodeTypeName isEqualToString:@"Unknown"]) {
        barcodeTypeName = [NSString stringWithFormat:@"Symbology %d", targetSymbology];
    }
    
    return [BarcodeTestResult resultWithBarcodeType:barcodeTypeName
                                            testData:testData
                                       distortionType:distortionType
                                            intensity:intensity
                                             strength:strength
                                              success:decodeSuccess
                                              quality:qualityScore
                                              matches:dataMatches
                                              decoded:decodedData];
}

- (NSArray *)runProgressiveTestWithData:(NSString *)testData
                                symbology:(int)symbology
                            distortionType:(NSInteger)distortionType
                             startIntensity:(float)startIntensity
                               endIntensity:(float)endIntensity
                                      steps:(NSInteger)steps
                                     session:(BarcodeTestSession *)session {
    if (steps < 1) steps = 1;
    
    NSMutableArray *testResults = [NSMutableArray array];
    float stepSize = (endIntensity - startIntensity) / (steps - 1);
    
    NSInteger i;
    for (i = 0; i < steps; i++) {
        float intensity = startIntensity + (stepSize * i);
        if (intensity > 1.0f) intensity = 1.0f;
        if (intensity < 0.0f) intensity = 0.0f;
        
        BarcodeTestResult *result = [self runTestWithData:testData
                                                symbology:symbology
                                            distortionType:distortionType
                                                 intensity:intensity
                                                   strength:0.5f]; // Default strength
        
        if (result) {
            [testResults addObject:result];
            if (session) {
                [session addResult:result];
            }
        }
    }
    
    return testResults;
}

- (BarcodeTestSession *)runComprehensiveTestSuite:(NSArray *)testDataArray
                                       symbologies:(NSArray *)symbologyArray
                                    distortionTypes:(NSArray *)distortionTypes
                                     intensityLevels:(NSArray *)intensityLevels
                                       strengthLevels:(NSArray *)strengthLevels
                                         sessionName:(NSString *)sessionName {
    BarcodeTestSession *session = [[BarcodeTestSession alloc] initWithName:sessionName];
    
    NSInteger dataIdx, symbIdx, distIdx, intensityIdx, strengthIdx;
    
    for (dataIdx = 0; dataIdx < testDataArray.count; dataIdx++) {
        NSString *testData = [testDataArray objectAtIndex:dataIdx];
        
        for (symbIdx = 0; symbIdx < symbologyArray.count; symbIdx++) {
            NSNumber *symbologyNum = [symbologyArray objectAtIndex:symbIdx];
            int symbology = [symbologyNum intValue];
            
            for (distIdx = 0; distIdx < distortionTypes.count; distIdx++) {
                NSNumber *distTypeNum = [distortionTypes objectAtIndex:distIdx];
                NSInteger distType = [distTypeNum intValue];
                
                for (intensityIdx = 0; intensityIdx < intensityLevels.count; intensityIdx++) {
                    NSNumber *intensityNum = [intensityLevels objectAtIndex:intensityIdx];
                    float intensity = [intensityNum floatValue];
                    
                    for (strengthIdx = 0; strengthIdx < strengthLevels.count; strengthIdx++) {
                        NSNumber *strengthNum = [strengthLevels objectAtIndex:strengthIdx];
                        float strength = [strengthNum floatValue];
                        
                        BarcodeTestResult *result = [self runTestWithData:testData
                                                                 symbology:symbology
                                                             distortionType:distType
                                                                  intensity:intensity
                                                                    strength:strength];
                        
                        if (result) {
                            [session addResult:result];
                        }
                    }
                }
            }
        }
    }
    
    [session endSession];
    return [session autorelease];
}

- (float)findFailureThresholdWithData:(NSString *)testData
                              symbology:(int)symbology
                          distortionType:(NSInteger)distortionType
                            maxIntensity:(float)maxIntensity
                                   steps:(NSInteger)steps {
    if (steps < 2) steps = 10;
    
    float stepSize = maxIntensity / steps;
    float lastSuccessIntensity = -1.0f;
    
    NSInteger i;
    for (i = 0; i <= steps; i++) {
        float intensity = stepSize * i;
        if (intensity > 1.0f) intensity = 1.0f;
        
        BarcodeTestResult *result = [self runTestWithData:testData
                                                  symbology:symbology
                                              distortionType:distortionType
                                                   intensity:intensity
                                                     strength:0.5f];
        
        if (result && result.decodeSuccess) {
            lastSuccessIntensity = intensity;
        } else {
            // Found failure point
            if (lastSuccessIntensity >= 0.0f) {
                // Return midpoint between last success and first failure
                return (lastSuccessIntensity + intensity) / 2.0f;
            } else {
                // Failed from the start
                return 0.0f;
            }
        }
    }
    
    // Never failed
    return -1.0f;
}

@end
