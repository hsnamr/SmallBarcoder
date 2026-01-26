//
//  WindowController.h
//  SmallBarcodeReader
//
//  Main window controller
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@class BarcodeDecoder;
@class BarcodeEncoder;
@class ImageDistorter;
@class BarcodeTester;
@class BarcodeTestSession;

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
    NSPopUpButton *distortionTypePopup;
    NSSlider *distortionIntensitySlider;
    NSSlider *distortionStrengthSlider;
    NSTextField *distortionIntensityLabel;
    NSTextField *distortionStrengthLabel;
    NSButton *applyDistortionButton;
    NSButton *clearDistortionButton;
    NSButton *previewDistortionButton;
    NSButton *loadLibraryButton;
    NSButton *testDecodabilityButton;
    NSButton *runProgressiveTestButton;
    NSButton *exportTestResultsButton;
    NSSlider *progressiveTestSlider;
    NSTextField *progressiveTestLabel;
    NSMutableArray *loadedLibraries; // Array of DynamicLibrary objects
    BarcodeDecoder *decoder;
    BarcodeEncoder *encoder;
    ImageDistorter *distorter;
    BarcodeTester *tester;
    BarcodeTestSession *currentTestSession;
    NSImage *currentImage;
    NSImage *originalImage; // Original image before distortions
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
@property (retain, nonatomic) NSPopUpButton *distortionTypePopup;
@property (retain, nonatomic) NSSlider *distortionIntensitySlider;
@property (retain, nonatomic) NSSlider *distortionStrengthSlider;
@property (retain, nonatomic) NSTextField *distortionIntensityLabel;
@property (retain, nonatomic) NSTextField *distortionStrengthLabel;
@property (retain, nonatomic) NSButton *applyDistortionButton;
@property (retain, nonatomic) NSButton *clearDistortionButton;
@property (retain, nonatomic) NSButton *previewDistortionButton;
@property (retain, nonatomic) NSButton *loadLibraryButton;
@property (retain, nonatomic) NSButton *testDecodabilityButton;
@property (retain, nonatomic) NSButton *runProgressiveTestButton;
@property (retain, nonatomic) NSButton *exportTestResultsButton;
@property (retain, nonatomic) NSSlider *progressiveTestSlider;
@property (retain, nonatomic) NSTextField *progressiveTestLabel;
@property (retain, nonatomic) NSMutableArray *loadedLibraries;
@property (retain, nonatomic) BarcodeDecoder *decoder;
@property (retain, nonatomic) BarcodeEncoder *encoder;
@property (retain, nonatomic) ImageDistorter *distorter;
@property (retain, nonatomic) BarcodeTester *tester;
@property (retain, nonatomic) BarcodeTestSession *currentTestSession;
@property (retain, nonatomic) NSImage *currentImage;
@property (retain, nonatomic) NSImage *originalImage;
@property (retain, nonatomic) NSString *originalEncodedData;

@end

NS_ASSUME_NONNULL_END
