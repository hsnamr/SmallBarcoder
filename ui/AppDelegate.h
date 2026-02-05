//
//  AppDelegate.h
//  SmallBarcodeReader
//
//  Application delegate (SSAppDelegate): lifecycle and main window.
//

#import <AppKit/AppKit.h>
#import "SSAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class WindowController;

@interface AppDelegate : NSObject <SSAppDelegate> {
    WindowController *windowController;
}

@property (retain, nonatomic) WindowController *windowController;

@end

NS_ASSUME_NONNULL_END
