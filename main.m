//
//  main.m
//  SmallBarcodeReader
//
//  Entry point for the application
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSApplication *application = [NSApplication sharedApplication];
    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    [application setDelegate:appDelegate];
    [application run];
    [pool release];
    return 0;
}
