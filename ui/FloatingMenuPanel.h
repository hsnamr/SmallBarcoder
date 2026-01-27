//
//  FloatingMenuPanel.h
//  SmallBarcodeReader
//
//  GNUstep-style floating menu panel
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class WindowController;

@interface FloatingMenuPanel : NSPanel {
    NSMenu *mainMenu;
    NSMenu *fileMenu;
    NSMenu *encodeMenu;
    NSMenu *decodeMenu;
    NSMenu *distortionMenu;
    NSMenu *testingMenu;
    NSMenu *libraryMenu;
    WindowController *windowController;
}

@property (retain, nonatomic) NSMenu *mainMenu;
@property (retain, nonatomic) NSMenu *fileMenu;
@property (retain, nonatomic) NSMenu *encodeMenu;
@property (retain, nonatomic) NSMenu *decodeMenu;
@property (retain, nonatomic) NSMenu *distortionMenu;
@property (retain, nonatomic) NSMenu *testingMenu;
@property (retain, nonatomic) NSMenu *libraryMenu;
@property (assign, nonatomic) WindowController *windowController;

- (instancetype)initWithWindowController:(WindowController *)controller;
- (void)updateMenuStates;
- (void)showPanel;
- (void)hidePanel;
- (void)togglePanel;

@end

NS_ASSUME_NONNULL_END
