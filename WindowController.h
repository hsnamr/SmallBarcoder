//
//  WindowController.h
//  SmallBarcodeReader
//
//  Main window controller
//

#import <AppKit/AppKit.h>

@class BarcodeDecoder;
@class BarcodeEncoder;

NS_ASSUME_NONNULL_BEGIN

@interface WindowController : NSWindowController <NSWindowDelegate> {
    NSImageView *imageView;
    NSTextView *textView;
    NSScrollView *textScrollView;
    NSButton *openButton;
    NSButton *decodeButton;
    NSButton *encodeButton;
    NSButton *saveButton;
    NSTextField *encodeTextField;
    NSPopUpButton *symbologyPopup;
    BarcodeDecoder *decoder;
    BarcodeEncoder *encoder;
    NSImage *currentImage;
    NSString *originalEncodedData; // Track original input for matching
}

@property (retain, nonatomic) NSImageView *imageView;
@property (retain, nonatomic) NSTextView *textView;
@property (retain, nonatomic) NSScrollView *textScrollView;
@property (retain, nonatomic) NSButton *openButton;
@property (retain, nonatomic) NSButton *decodeButton;
@property (retain, nonatomic) NSButton *encodeButton;
@property (retain, nonatomic) NSButton *saveButton;
@property (retain, nonatomic) NSTextField *encodeTextField;
@property (retain, nonatomic) NSPopUpButton *symbologyPopup;
@property (retain, nonatomic) BarcodeDecoder *decoder;
@property (retain, nonatomic) BarcodeEncoder *encoder;
@property (retain, nonatomic) NSImage *currentImage;
@property (retain, nonatomic) NSString *originalEncodedData;

@end

NS_ASSUME_NONNULL_END
