//
//  BarcodeTestResult.m
//  SmallBarcodeReader
//
//  Test result implementation
//

#import "BarcodeTestResult.h"

@implementation BarcodeTestResult

@synthesize barcodeType;
@synthesize testData;
@synthesize distortionType;
@synthesize distortionIntensity;
@synthesize distortionStrength;
@synthesize decodeSuccess;
@synthesize qualityScore;
@synthesize dataMatches;
@synthesize decodedData;

+ (instancetype)resultWithBarcodeType:(NSString *)type 
                              testData:(NSString *)data 
                         distortionType:(NSInteger)distType 
                                intensity:(float)intensity 
                                strength:(float)strength 
                                success:(BOOL)success 
                                quality:(NSInteger)quality 
                                matches:(BOOL)matches 
                                decoded:(NSString *)decoded {
    BarcodeTestResult *result = [[BarcodeTestResult alloc] init];
    result.barcodeType = type;
    result.testData = data;
    result.distortionType = distType;
    result.distortionIntensity = intensity;
    result.distortionStrength = strength;
    result.decodeSuccess = success;
    result.qualityScore = quality;
    result.dataMatches = matches;
    result.decodedData = decoded;
    return [result autorelease];
}

- (void)dealloc {
    [barcodeType release];
    [testData release];
    [decodedData release];
    [super dealloc];
}

@end

@implementation BarcodeTestSession

@synthesize results;
@synthesize sessionName;
@synthesize startTime;
@synthesize endTime;

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        sessionName = [name retain];
        results = [[NSMutableArray alloc] init];
        startTime = [[NSDate date] retain];
        endTime = nil;
    }
    return self;
}

- (void)dealloc {
    [results release];
    [sessionName release];
    [startTime release];
    [endTime release];
    [super dealloc];
}

- (void)addResult:(BarcodeTestResult *)result {
    if (result) {
        [results addObject:result];
    }
}

- (void)endSession {
    if (!endTime) {
        endTime = [[NSDate date] retain];
    }
}

- (NSDictionary *)summaryStatistics {
    [self endSession];
    
    NSInteger totalTests = results.count;
    NSInteger successfulDecodes = 0;
    NSInteger matchingDecodes = 0;
    NSInteger totalQuality = 0;
    NSInteger qualityCount = 0;
    
    NSMutableDictionary *byBarcodeType = [NSMutableDictionary dictionary];
    NSMutableDictionary *byDistortionType = [NSMutableDictionary dictionary];
    
    NSInteger i;
    for (i = 0; i < results.count; i++) {
        BarcodeTestResult *result = [results objectAtIndex:i];
        
        if (result.decodeSuccess) {
            successfulDecodes++;
            if (result.dataMatches) {
                matchingDecodes++;
            }
            if (result.qualityScore >= 0) {
                totalQuality += result.qualityScore;
                qualityCount++;
            }
        }
        
        // Group by barcode type
        NSString *type = result.barcodeType;
        if (![byBarcodeType objectForKey:type]) {
            [byBarcodeType setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:0], @"total",
                [NSNumber numberWithInt:0], @"success",
                nil] forKey:type];
        }
        NSMutableDictionary *typeStats = [byBarcodeType objectForKey:type];
        NSInteger total = [[typeStats objectForKey:@"total"] intValue] + 1;
        [typeStats setObject:[NSNumber numberWithInt:total] forKey:@"total"];
        if (result.decodeSuccess) {
            NSInteger success = [[typeStats objectForKey:@"success"] intValue] + 1;
            [typeStats setObject:[NSNumber numberWithInt:success] forKey:@"success"];
        }
        
        // Group by distortion type
        NSString *distTypeKey = [NSString stringWithFormat:@"%ld", (long)result.distortionType];
        if (![byDistortionType objectForKey:distTypeKey]) {
            [byDistortionType setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:0], @"total",
                [NSNumber numberWithInt:0], @"success",
                nil] forKey:distTypeKey];
        }
        NSMutableDictionary *distStats = [byDistortionType objectForKey:distTypeKey];
        total = [[distStats objectForKey:@"total"] intValue] + 1;
        [distStats setObject:[NSNumber numberWithInt:total] forKey:@"total"];
        if (result.decodeSuccess) {
            NSInteger success = [[distStats objectForKey:@"success"] intValue] + 1;
            [distStats setObject:[NSNumber numberWithInt:success] forKey:@"success"];
        }
    }
    
    NSMutableDictionary *summary = [NSMutableDictionary dictionary];
    [summary setObject:[NSNumber numberWithInt:totalTests] forKey:@"totalTests"];
    [summary setObject:[NSNumber numberWithInt:successfulDecodes] forKey:@"successfulDecodes"];
    [summary setObject:[NSNumber numberWithInt:matchingDecodes] forKey:@"matchingDecodes"];
    if (qualityCount > 0) {
        [summary setObject:[NSNumber numberWithFloat:(float)totalQuality / qualityCount] forKey:@"averageQuality"];
    }
    if (totalTests > 0) {
        [summary setObject:[NSNumber numberWithFloat:(float)successfulDecodes / totalTests * 100.0f] forKey:@"successRate"];
    }
    [summary setObject:byBarcodeType forKey:@"byBarcodeType"];
    [summary setObject:byDistortionType forKey:@"byDistortionType"];
    [summary setObject:startTime forKey:@"startTime"];
    [summary setObject:endTime ? endTime : [NSDate date] forKey:@"endTime"];
    
    return summary;
}

- (NSString *)exportToCSV {
    NSMutableString *csv = [NSMutableString string];
    
    // Header
    [csv appendString:@"Barcode Type,Test Data,Distortion Type,Intensity,Strength,Decode Success,Quality Score,Data Matches,Decoded Data\n"];
    
    // Data rows
    NSInteger i;
    for (i = 0; i < results.count; i++) {
        BarcodeTestResult *result = [results objectAtIndex:i];
        [csv appendFormat:@"%@,%@,%ld,%.2f,%.2f,%d,%ld,%d,%@\n",
            result.barcodeType ? result.barcodeType : @"",
            result.testData ? result.testData : @"",
            (long)result.distortionType,
            result.distortionIntensity,
            result.distortionStrength,
            result.decodeSuccess ? 1 : 0,
            (long)result.qualityScore,
            result.dataMatches ? 1 : 0,
            result.decodedData ? result.decodedData : @""];
    }
    
    return csv;
}

- (NSString *)exportToJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    [json setObject:sessionName ? sessionName : @"Test Session" forKey:@"sessionName"];
    [json setObject:[startTime description] forKey:@"startTime"];
    if (endTime) {
        [json setObject:[endTime description] forKey:@"endTime"];
    }
    
    NSMutableArray *resultsArray = [NSMutableArray array];
    NSInteger i;
    for (i = 0; i < results.count; i++) {
        BarcodeTestResult *result = [results objectAtIndex:i];
        NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
        [resultDict setObject:result.barcodeType ? result.barcodeType : @"" forKey:@"barcodeType"];
        [resultDict setObject:result.testData ? result.testData : @"" forKey:@"testData"];
        [resultDict setObject:[NSNumber numberWithInt:(int)result.distortionType] forKey:@"distortionType"];
        [resultDict setObject:[NSNumber numberWithFloat:result.distortionIntensity] forKey:@"intensity"];
        [resultDict setObject:[NSNumber numberWithFloat:result.distortionStrength] forKey:@"strength"];
        [resultDict setObject:[NSNumber numberWithBool:result.decodeSuccess] forKey:@"decodeSuccess"];
        [resultDict setObject:[NSNumber numberWithInt:(int)result.qualityScore] forKey:@"qualityScore"];
        [resultDict setObject:[NSNumber numberWithBool:result.dataMatches] forKey:@"dataMatches"];
        [resultDict setObject:result.decodedData ? result.decodedData : @"" forKey:@"decodedData"];
        [resultsArray addObject:resultDict];
    }
    [json setObject:resultsArray forKey:@"results"];
    
    [json setObject:[self summaryStatistics] forKey:@"summary"];
    
    // Simple JSON serialization (for basic compatibility)
    // In a real implementation, you might want to use NSJSONSerialization if available
    NSMutableString *jsonString = [NSMutableString string];
    [jsonString appendString:@"{\n"];
    [jsonString appendFormat:@"  \"sessionName\": \"%@\",\n", [self escapeJSONString:sessionName ? sessionName : @""]];
    [jsonString appendFormat:@"  \"startTime\": \"%@\",\n", [self escapeJSONString:[startTime description]]];
    if (endTime) {
        [jsonString appendFormat:@"  \"endTime\": \"%@\",\n", [self escapeJSONString:[endTime description]]];
    }
    [jsonString appendString:@"  \"results\": [\n"];
    
    for (i = 0; i < resultsArray.count; i++) {
        NSDictionary *resultDict = [resultsArray objectAtIndex:i];
        [jsonString appendString:@"    {\n"];
        NSString *barcodeType = [resultDict objectForKey:@"barcodeType"];
        NSString *testData = [resultDict objectForKey:@"testData"];
        NSString *decodedData = [resultDict objectForKey:@"decodedData"];
        [jsonString appendFormat:@"      \"barcodeType\": \"%@\",\n", [self escapeJSONString:barcodeType ? barcodeType : @""]];
        [jsonString appendFormat:@"      \"testData\": \"%@\",\n", [self escapeJSONString:testData ? testData : @""]];
        [jsonString appendFormat:@"      \"distortionType\": %d,\n", [[resultDict objectForKey:@"distortionType"] intValue]];
        [jsonString appendFormat:@"      \"intensity\": %.2f,\n", [[resultDict objectForKey:@"intensity"] floatValue]];
        [jsonString appendFormat:@"      \"strength\": %.2f,\n", [[resultDict objectForKey:@"strength"] floatValue]];
        [jsonString appendFormat:@"      \"decodeSuccess\": %@,\n", [[resultDict objectForKey:@"decodeSuccess"] boolValue] ? @"true" : @"false"];
        [jsonString appendFormat:@"      \"qualityScore\": %d,\n", [[resultDict objectForKey:@"qualityScore"] intValue]];
        [jsonString appendFormat:@"      \"dataMatches\": %@,\n", [[resultDict objectForKey:@"dataMatches"] boolValue] ? @"true" : @"false"];
        [jsonString appendFormat:@"      \"decodedData\": \"%@\"\n", [self escapeJSONString:decodedData ? decodedData : @""]];
        [jsonString appendString:i < resultsArray.count - 1 ? @"    },\n" : @"    }\n"];
    }
    
    [jsonString appendString:@"  ]\n"];
    [jsonString appendString:@"}\n"];
    
    return jsonString;
}

- (NSString *)escapeJSONString:(NSString *)string {
    if (!string) {
        return @"";
    }
    NSMutableString *escaped = [NSMutableString stringWithString:string];
    [escaped replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, escaped.length)];
    return escaped;
}

@end
