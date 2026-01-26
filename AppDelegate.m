//
//  AppDelegate.m
//  SmallBarcodeReader
//
//  Application delegate implementation
//

#import "AppDelegate.h"
#import "WindowController.h"

@implementation AppDelegate

@synthesize windowController;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.windowController = [[WindowController alloc] init];
    [self.windowController showWindow:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(id)sender {
    return YES;
}

- (void)dealloc {
    [windowController release];
    [super dealloc];
}

@end
