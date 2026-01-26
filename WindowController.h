//
//  WindowController.h
//  SmallBarcodeReader
//
//  Main window controller
//

#import <AppKit/AppKit.h>

@class BarcodeDecoder;

NS_ASSUME_NONNULL_BEGIN

@interface WindowController : NSWindowController <NSWindowDelegate> {
    NSImageView *imageView;
    NSTextView *textView;
    NSScrollView *textScrollView;
    NSButton *openButton;
    NSButton *decodeButton;
    BarcodeDecoder *decoder;
    NSImage *currentImage;
}

@property (retain, nonatomic) NSImageView *imageView;
@property (retain, nonatomic) NSTextView *textView;
@property (retain, nonatomic) NSScrollView *textScrollView;
@property (retain, nonatomic) NSButton *openButton;
@property (retain, nonatomic) NSButton *decodeButton;
@property (retain, nonatomic) BarcodeDecoder *decoder;
@property (retain, nonatomic) NSImage *currentImage;

@end

NS_ASSUME_NONNULL_END
