//
//  AppDelegate.m
//  SmallBarcodeReader
//
//  Application delegate implementation (SSAppDelegate).
//

#import "AppDelegate.h"
#import "WindowController.h"

@implementation AppDelegate

@synthesize windowController;

- (void)applicationDidFinishLaunching {
    self.windowController = [[WindowController alloc] init];
    [self.windowController showWindow:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(id)sender {
    (void)sender;
    return YES;
}

- (void)dealloc {
    [windowController release];
    [super dealloc];
}

@end
