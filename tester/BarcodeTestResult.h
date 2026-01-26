//
//  BarcodeTestResult.h
//  SmallBarcodeReader
//
//  Test result for decodability testing
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Test result for a single distortion test
@interface BarcodeTestResult : NSObject {
    NSString *barcodeType;
    NSString *testData;
    NSInteger distortionType;
    float distortionIntensity;
    float distortionStrength;
    BOOL decodeSuccess;
    NSInteger qualityScore;
    BOOL dataMatches;
    NSString *decodedData;
}

@property (retain, nonatomic) NSString *barcodeType;
@property (retain, nonatomic) NSString *testData;
@property (assign, nonatomic) NSInteger distortionType;
@property (assign, nonatomic) float distortionIntensity;
@property (assign, nonatomic) float distortionStrength;
@property (assign, nonatomic) BOOL decodeSuccess;
@property (assign, nonatomic) NSInteger qualityScore;
@property (assign, nonatomic) BOOL dataMatches;
@property (retain, nonatomic) NSString *decodedData;

+ (instancetype)resultWithBarcodeType:(NSString *)type 
                              testData:(NSString *)data 
                         distortionType:(NSInteger)distType 
                                intensity:(float)intensity 
                                strength:(float)strength 
                                success:(BOOL)success 
                                quality:(NSInteger)quality 
                                matches:(BOOL)matches 
                                decoded:(NSString *)decoded;

@end

/// Test session containing multiple test results
@interface BarcodeTestSession : NSObject {
    NSMutableArray *results;
    NSString *sessionName;
    NSDate *startTime;
    NSDate *endTime;
}

@property (retain, nonatomic) NSMutableArray *results;
@property (retain, nonatomic) NSString *sessionName;
@property (retain, nonatomic) NSDate *startTime;
@property (retain, nonatomic) NSDate *endTime;

- (instancetype)initWithName:(NSString *)name;
- (void)addResult:(BarcodeTestResult *)result;
- (void)endSession;
- (NSDictionary *)summaryStatistics;
- (NSString *)exportToCSV;
- (NSString *)exportToJSON;
- (NSString *)escapeJSONString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
