//
//  BarcodeDecoderZBar.h
//  SmallBarcodeReader
//
//  ZBar-based barcode decoder implementation
//

#import <Foundation/Foundation.h>
#import "BarcodeDecoderBackend.h"

/// ZBar-based barcode decoder backend
@interface BarcodeDecoderZBar : NSObject <BarcodeDecoderBackend>

@end
