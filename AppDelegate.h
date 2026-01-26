//
//  AppDelegate.h
//  SmallBarcodeReader
//
//  Application delegate
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    WindowController *windowController;
}

@property (retain, nonatomic) WindowController *windowController;

@end

NS_ASSUME_NONNULL_END
