//
//  WindowController.m
//  SmallBarcodeReader
//
//  Main window controller implementation
//

#import "WindowController.h"
#import "BarcodeDecoder.h"
#import "BarcodeEncoder.h"
#import "ImageDistorter.h"
#import "DynamicLibraryLoader.h"
#import "BackendFactory.h"
#import "BarcodeTester.h"
#import "BarcodeTestResult.h"
#import "../SmallStep/SmallStep/Core/SmallStep.h"

@interface WindowController (Private)

- (void)loadImageFromURL:(NSURL *)url;
- (void)decodeInBackground:(id)object;
- (void)updateResults:(NSArray *)results;
- (void)encodeInBackground:(id)object;
- (void)updateEncodedImage:(NSImage *)image;
- (void)populateSymbologyPopup;
- (void)populateDistortionTypePopup;
- (void)checkAndDisplayBackendStatus;
- (void)saveImageToURL:(NSURL *)url;
- (void)updateDistortionLabels;
- (void)applyDistortionToCurrentImage;
- (void)loadLibraryFromURL:(NSURL *)url;
- (void)updateLibraryStatus;

@end

@implementation WindowController

@synthesize imageView;
@synthesize textView;
@synthesize textScrollView;
@synthesize openButton;
@synthesize decodeButton;
@synthesize encodeButton;
@synthesize saveButton;
@synthesize encodeTextField;
@synthesize symbologyPopup;
@synthesize distortionTypePopup;
@synthesize distortionIntensitySlider;
@synthesize distortionStrengthSlider;
@synthesize distortionIntensityLabel;
@synthesize distortionStrengthLabel;
@synthesize applyDistortionButton;
@synthesize clearDistortionButton;
@synthesize previewDistortionButton;
@synthesize loadLibraryButton;
@synthesize testDecodabilityButton;
@synthesize runProgressiveTestButton;
@synthesize exportTestResultsButton;
@synthesize progressiveTestSlider;
@synthesize progressiveTestLabel;
@synthesize loadedLibraries;
@synthesize decoder;
@synthesize encoder;
@synthesize distorter;
@synthesize tester;
@synthesize currentTestSession;
@synthesize currentImage;
@synthesize originalImage;
@synthesize originalEncodedData;
@synthesize applicationMenu;

- (instancetype)init {
    self = [super init];
    if (self) {
        decoder = [[BarcodeDecoder alloc] init];
        encoder = [[BarcodeEncoder alloc] init];
        distorter = [[ImageDistorter alloc] init];
        tester = [[BarcodeTester alloc] initWithEncoder:encoder decoder:decoder];
        loadedLibraries = [[NSMutableArray alloc] init];
        currentTestSession = nil;
        [self setupWindow];
        
        // Create application menu using SmallStep abstraction
        applicationMenu = [[SSApplicationMenu alloc] initWithDelegate:self];
        [applicationMenu buildMenu];
        [applicationMenu showMenu]; // Shows floating panel on Linux, no-op on macOS
        
        // Check ZInt availability and update UI (deferred to next run loop)
        [self performSelector:@selector(checkAndDisplayBackendStatus) withObject:nil afterDelay:0.1];
    }
    return self;
}

- (void)dealloc {
    [imageView release];
    [textView release];
    [textScrollView release];
    [openButton release];
    [decodeButton release];
    [encodeButton release];
    [saveButton release];
    [encodeTextField release];
    [symbologyPopup release];
    [distortionTypePopup release];
    [distortionIntensitySlider release];
    [distortionStrengthSlider release];
    [distortionIntensityLabel release];
    [distortionStrengthLabel release];
    [applyDistortionButton release];
    [clearDistortionButton release];
    [previewDistortionButton release];
    [decoder release];
    [encoder release];
    [distorter release];
    [tester release];
    [currentTestSession release];
    [loadLibraryButton release];
    [testDecodabilityButton release];
    [runProgressiveTestButton release];
    [exportTestResultsButton release];
    [progressiveTestSlider release];
    [progressiveTestLabel release];
    [loadedLibraries release];
    [currentImage release];
    [originalImage release];
    [originalEncodedData release];
    [applicationMenu release];
    [super dealloc];
}

- (void)setupWindow {
    // Create window using SmallStep abstraction - make it larger for better UI spacing
    NSRect windowRect = NSMakeRect(100, 100, 1400, 1000);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowRect
                                                    styleMask:[SSWindowStyle standardWindowMask]
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setTitle:@"Small Barcode Reader"];
    [window setDelegate:self];
    [window setMinSize:NSMakeSize(1000, 700)]; // Set minimum window size
    [self setWindow:window];
    
    NSView *contentView = [window contentView];
    [contentView setAutoresizesSubviews:YES];
    
    // Calculate half height for horizontal split
    NSRect contentBounds = [contentView bounds];
    float halfHeight = contentBounds.size.height / 2.0;
    
    // UPPER HALF: Image viewer on left, text field on right
    // Create image view - left side of upper half, resizes with window
    NSRect imageViewRect = NSMakeRect(20, halfHeight + 10, (contentBounds.size.width / 2.0) - 30, halfHeight - 20);
    self.imageView = [[NSImageView alloc] initWithFrame:imageViewRect];
    [self.imageView setImageAlignment:NSImageAlignCenter];
    [self.imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.imageView setImageFrameStyle:NSImageFrameGrayBezel];
    [self.imageView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMaxXMargin | NSViewMaxYMargin | NSViewMinYMargin];
    [contentView addSubview:self.imageView];
    
    // Create text view with scroll view - right side of upper half, resizes with window
    NSRect textScrollRect = NSMakeRect((contentBounds.size.width / 2.0) + 10, halfHeight + 10, (contentBounds.size.width / 2.0) - 30, halfHeight - 20);
    self.textScrollView = [[NSScrollView alloc] initWithFrame:textScrollRect];
    [self.textScrollView setHasVerticalScroller:YES];
    [self.textScrollView setHasHorizontalScroller:YES];
    [self.textScrollView setAutohidesScrollers:YES];
    [self.textScrollView setBorderType:NSBezelBorder];
    [self.textScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMaxXMargin | NSViewMaxYMargin | NSViewMinYMargin];
    
    NSRect textViewRect = NSMakeRect(0, 0, [self.textScrollView contentSize].width, [self.textScrollView contentSize].height);
    self.textView = [[NSTextView alloc] initWithFrame:textViewRect];
    [self.textView setEditable:NO];
    [self.textView setFont:[NSFont systemFontOfSize:12]];
    // Check if any backends are available and show appropriate message
    NSArray *availableDecoders = [BarcodeDecoder availableBackends];
    NSArray *availableEncoders = [BarcodeEncoder availableBackends];
    if (availableDecoders.count == 0 && availableEncoders.count == 0) {
        NSMutableString *msg = [NSMutableString string];
        [msg appendString:@"No barcode libraries available.\n\n"];
        [msg appendString:@"This application requires barcode libraries to function:\n"];
        [msg appendString:@"- ZBar (libzbar) for barcode decoding\n"];
        [msg appendString:@"- ZInt (libzint) for barcode encoding\n\n"];
        [msg appendString:@"Please install at least one library:\n"];
        [msg appendString:@"- Linux: sudo apt-get install libzbar-dev libzint-dev\n"];
        [msg appendString:@"- macOS: brew install zbar zint\n\n"];
        [msg appendString:@"Note: Dynamic library loading will be available in a future version."];
        [self.textView setString:msg];
    } else {
        NSMutableString *msg = [NSMutableString string];
        [msg appendString:@"Small Barcode Reader\n"];
        [msg appendString:@"====================\n\n"];
        if (availableDecoders.count > 0) {
            [msg appendFormat:@"Decoders: %@\n", [availableDecoders componentsJoinedByString:@", "]];
        }
        if (availableEncoders.count > 0) {
            [msg appendFormat:@"Encoders: %@\n", [availableEncoders componentsJoinedByString:@", "]];
        }
        [msg appendString:@"\n"];
        [msg appendString:@"Decoding: Click 'Open Image' to load an image, then 'Decode'.\n"];
        [msg appendString:@"Encoding: Enter text below, select barcode type, then 'Encode'."];
        [self.textView setString:msg];
    }
    
    [self.textScrollView setDocumentView:self.textView];
    [contentView addSubview:self.textScrollView];
    
    // BOTTOM HALF: All controls and widgets
    // Layout controls in bottom half, starting from top of bottom half
    float bottomHalfTop = halfHeight - 10;
    float currentY = bottomHalfTop;
    float rowHeight = 35;
    float spacing = 5;
    
    // Row 1: Open and Decode buttons
    currentY -= rowHeight;
    NSRect buttonRect = NSMakeRect(20, currentY, 120, 32);
    self.openButton = [[NSButton alloc] initWithFrame:buttonRect];
    [self.openButton setTitle:@"Open Image..."];
    [self.openButton setButtonType:NSMomentaryPushInButton];
    [self.openButton setBezelStyle:NSRoundedBezelStyle];
    [self.openButton setTarget:self];
    [self.openButton setAction:@selector(openImage:)];
    [self.openButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.openButton];
    
    NSRect decodeButtonRect = NSMakeRect(150, currentY, 120, 32);
    self.decodeButton = [[NSButton alloc] initWithFrame:decodeButtonRect];
    [self.decodeButton setTitle:@"Decode"];
    [self.decodeButton setButtonType:NSMomentaryPushInButton];
    [self.decodeButton setBezelStyle:NSRoundedBezelStyle];
    [self.decodeButton setTarget:self];
    [self.decodeButton setAction:@selector(decodeImage:)];
    [self.decodeButton setEnabled:NO];
    [self.decodeButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.decodeButton];
    
    // Row 2: Encoding text field and symbology popup
    currentY -= (rowHeight + spacing);
    NSRect textFieldRect = NSMakeRect(20, currentY, 300, 24);
    self.encodeTextField = [[NSTextField alloc] initWithFrame:textFieldRect];
    [self.encodeTextField setPlaceholderString:@"Enter text to encode..."];
    [self.encodeTextField setTarget:self];
    [self.encodeTextField setAction:@selector(encodeBarcode:)];
    [self.encodeTextField setAutoresizingMask:NSViewWidthSizable | NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.encodeTextField];
    
    NSRect popupRect = NSMakeRect(330, currentY, 200, 24);
    self.symbologyPopup = [[NSPopUpButton alloc] initWithFrame:popupRect pullsDown:NO];
    // Will be populated after encoder initialization
    [self.symbologyPopup addItemWithTitle:@"Loading..."];
    [self.symbologyPopup setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.symbologyPopup];
    
    // Row 3: Encode and Save buttons
    currentY -= (rowHeight + spacing);
    NSRect encodeButtonRect = NSMakeRect(20, currentY, 120, 32);
    self.encodeButton = [[NSButton alloc] initWithFrame:encodeButtonRect];
    [self.encodeButton setTitle:@"Encode"];
    [self.encodeButton setButtonType:NSMomentaryPushInButton];
    [self.encodeButton setBezelStyle:NSRoundedBezelStyle];
    [self.encodeButton setTarget:self];
    [self.encodeButton setAction:@selector(encodeBarcode:)];
    [self.encodeButton setEnabled:NO]; // Will be enabled after backend check
    [self.encodeButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.encodeButton];
    
    NSRect saveButtonRect = NSMakeRect(150, currentY, 120, 32);
    self.saveButton = [[NSButton alloc] initWithFrame:saveButtonRect];
    [self.saveButton setTitle:@"Save Image..."];
    [self.saveButton setButtonType:NSMomentaryPushInButton];
    [self.saveButton setBezelStyle:NSRoundedBezelStyle];
    [self.saveButton setTarget:self];
    [self.saveButton setAction:@selector(saveImage:)];
    [self.saveButton setEnabled:NO];
    [self.saveButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.saveButton];
    
    // Row 4: Distortion type popup
    currentY -= (rowHeight + spacing);
    NSRect distortionPopupRect = NSMakeRect(20, currentY, 250, 24);
    self.distortionTypePopup = [[NSPopUpButton alloc] initWithFrame:distortionPopupRect pullsDown:NO];
    [self populateDistortionTypePopup];
    [self.distortionTypePopup setAutoresizingMask:NSViewWidthSizable | NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.distortionTypePopup];
    
    // Row 5: Intensity slider and label
    currentY -= (rowHeight + spacing);
    NSRect intensitySliderRect = NSMakeRect(20, currentY, 300, 20);
    self.distortionIntensitySlider = [[NSSlider alloc] initWithFrame:intensitySliderRect];
    [self.distortionIntensitySlider setMinValue:0.0];
    [self.distortionIntensitySlider setMaxValue:1.0];
    [self.distortionIntensitySlider setDoubleValue:0.5];
    [self.distortionIntensitySlider setTarget:self];
    [self.distortionIntensitySlider setAction:@selector(updateDistortionLabels)];
    [self.distortionIntensitySlider setAutoresizingMask:NSViewWidthSizable | NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.distortionIntensitySlider];
    
    NSRect intensityLabelRect = NSMakeRect(330, currentY, 150, 20);
    self.distortionIntensityLabel = [[NSTextField alloc] initWithFrame:intensityLabelRect];
    [self.distortionIntensityLabel setEditable:NO];
    [self.distortionIntensityLabel setBordered:NO];
    [self.distortionIntensityLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [self.distortionIntensityLabel setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.distortionIntensityLabel];
    
    // Row 6: Strength slider and label
    currentY -= (rowHeight + spacing);
    NSRect strengthSliderRect = NSMakeRect(20, currentY, 300, 20);
    self.distortionStrengthSlider = [[NSSlider alloc] initWithFrame:strengthSliderRect];
    [self.distortionStrengthSlider setMinValue:0.0];
    [self.distortionStrengthSlider setMaxValue:1.0];
    [self.distortionStrengthSlider setDoubleValue:0.5];
    [self.distortionStrengthSlider setTarget:self];
    [self.distortionStrengthSlider setAction:@selector(updateDistortionLabels)];
    [self.distortionStrengthSlider setAutoresizingMask:NSViewWidthSizable | NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.distortionStrengthSlider];
    
    NSRect strengthLabelRect = NSMakeRect(330, currentY, 150, 20);
    self.distortionStrengthLabel = [[NSTextField alloc] initWithFrame:strengthLabelRect];
    [self.distortionStrengthLabel setEditable:NO];
    [self.distortionStrengthLabel setBordered:NO];
    [self.distortionStrengthLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [self.distortionStrengthLabel setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.distortionStrengthLabel];
    
    // Row 7: Distortion action buttons
    currentY -= (rowHeight + spacing);
    NSRect applyDistortionRect = NSMakeRect(20, currentY, 120, 32);
    self.applyDistortionButton = [[NSButton alloc] initWithFrame:applyDistortionRect];
    [self.applyDistortionButton setTitle:@"Apply Distortion"];
    [self.applyDistortionButton setButtonType:NSMomentaryPushInButton];
    [self.applyDistortionButton setBezelStyle:NSRoundedBezelStyle];
    [self.applyDistortionButton setTarget:self];
    [self.applyDistortionButton setAction:@selector(applyDistortion:)];
    [self.applyDistortionButton setEnabled:NO];
    [self.applyDistortionButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.applyDistortionButton];
    
    NSRect previewDistortionRect = NSMakeRect(150, currentY, 120, 32);
    self.previewDistortionButton = [[NSButton alloc] initWithFrame:previewDistortionRect];
    [self.previewDistortionButton setTitle:@"Preview"];
    [self.previewDistortionButton setButtonType:NSMomentaryPushInButton];
    [self.previewDistortionButton setBezelStyle:NSRoundedBezelStyle];
    [self.previewDistortionButton setTarget:self];
    [self.previewDistortionButton setAction:@selector(previewDistortion:)];
    [self.previewDistortionButton setEnabled:NO];
    [self.previewDistortionButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.previewDistortionButton];
    
    NSRect clearDistortionRect = NSMakeRect(280, currentY, 120, 32);
    self.clearDistortionButton = [[NSButton alloc] initWithFrame:clearDistortionRect];
    [self.clearDistortionButton setTitle:@"Clear"];
    [self.clearDistortionButton setButtonType:NSMomentaryPushInButton];
    [self.clearDistortionButton setBezelStyle:NSRoundedBezelStyle];
    [self.clearDistortionButton setTarget:self];
    [self.clearDistortionButton setAction:@selector(clearDistortion:)];
    [self.clearDistortionButton setEnabled:NO];
    [self.clearDistortionButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.clearDistortionButton];
    
    // Row 8: Testing controls - Test Decodability button
    currentY -= (rowHeight + spacing);
    NSRect testDecodabilityRect = NSMakeRect(20, currentY, 160, 32);
    self.testDecodabilityButton = [[NSButton alloc] initWithFrame:testDecodabilityRect];
    [self.testDecodabilityButton setTitle:@"Test Decodability"];
    [self.testDecodabilityButton setButtonType:NSMomentaryPushInButton];
    [self.testDecodabilityButton setBezelStyle:NSRoundedBezelStyle];
    [self.testDecodabilityButton setTarget:self];
    [self.testDecodabilityButton setAction:@selector(testDecodability:)];
    [self.testDecodabilityButton setEnabled:NO];
    [self.testDecodabilityButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.testDecodabilityButton];
    
    // Row 9: Progressive test slider and label
    currentY -= (rowHeight + spacing);
    NSRect progressiveSliderRect = NSMakeRect(20, currentY, 350, 20);
    self.progressiveTestSlider = [[NSSlider alloc] initWithFrame:progressiveSliderRect];
    [self.progressiveTestSlider setMinValue:0.0];
    [self.progressiveTestSlider setMaxValue:1.0];
    [self.progressiveTestSlider setDoubleValue:0.0];
    [self.progressiveTestSlider setTarget:self];
    [self.progressiveTestSlider setAction:@selector(progressiveTestSliderChanged:)];
    [self.progressiveTestSlider setEnabled:NO];
    [self.progressiveTestSlider setAutoresizingMask:NSViewWidthSizable | NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.progressiveTestSlider];
    
    NSRect progressiveLabelRect = NSMakeRect(380, currentY, 150, 20);
    self.progressiveTestLabel = [[NSTextField alloc] initWithFrame:progressiveLabelRect];
    [self.progressiveTestLabel setEditable:NO];
    [self.progressiveTestLabel setBordered:NO];
    [self.progressiveTestLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [self.progressiveTestLabel setStringValue:@"Intensity: 0.00"];
    [self.progressiveTestLabel setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.progressiveTestLabel];
    
    // Row 10: Run Progressive Test and Export buttons
    currentY -= (rowHeight + spacing);
    NSRect runProgressiveRect = NSMakeRect(20, currentY, 160, 32);
    self.runProgressiveTestButton = [[NSButton alloc] initWithFrame:runProgressiveRect];
    [self.runProgressiveTestButton setTitle:@"Run Progressive Test"];
    [self.runProgressiveTestButton setButtonType:NSMomentaryPushInButton];
    [self.runProgressiveTestButton setBezelStyle:NSRoundedBezelStyle];
    [self.runProgressiveTestButton setTarget:self];
    [self.runProgressiveTestButton setAction:@selector(runProgressiveTest:)];
    [self.runProgressiveTestButton setEnabled:NO];
    [self.runProgressiveTestButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.runProgressiveTestButton];
    
    NSRect exportResultsRect = NSMakeRect(190, currentY, 160, 32);
    self.exportTestResultsButton = [[NSButton alloc] initWithFrame:exportResultsRect];
    [self.exportTestResultsButton setTitle:@"Export Results..."];
    [self.exportTestResultsButton setButtonType:NSMomentaryPushInButton];
    [self.exportTestResultsButton setBezelStyle:NSRoundedBezelStyle];
    [self.exportTestResultsButton setTarget:self];
    [self.exportTestResultsButton setAction:@selector(exportTestResults:)];
    [self.exportTestResultsButton setEnabled:NO];
    [self.exportTestResultsButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.exportTestResultsButton];
    
    // Load Library button (only on platforms that support dynamic loading)
#if !TARGET_OS_IPHONE && !TARGET_OS_WIN32
    NSRect loadLibraryRect = NSMakeRect(360, currentY, 120, 32);
    self.loadLibraryButton = [[NSButton alloc] initWithFrame:loadLibraryRect];
    [self.loadLibraryButton setTitle:@"Load Library..."];
    [self.loadLibraryButton setButtonType:NSMomentaryPushInButton];
    [self.loadLibraryButton setBezelStyle:NSRoundedBezelStyle];
    [self.loadLibraryButton setTarget:self];
    [self.loadLibraryButton setAction:@selector(loadLibrary:)];
    [self.loadLibraryButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [contentView addSubview:self.loadLibraryButton];
#endif
    
    [self updateDistortionLabels];
}

- (void)openImage:(id)sender {
    SSFileDialog *dialog = [SSFileDialog openDialog];
    [dialog setCanChooseFiles:YES];
    [dialog setCanChooseDirectories:NO];
    [dialog setAllowsMultipleSelection:NO];
    [dialog setAllowedFileTypes:[NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"tiff", @"tif", nil]];
    
#if __has_feature(blocks) || (TARGET_OS_IPHONE && __clang__)
    // Use completion handler on platforms that support blocks (iOS, macOS, Windows)
    [dialog showWithCompletionHandler:^(SSFileDialogResult result, NSArray *urls) {
        if (result == SSFileDialogResultOK && urls.count > 0) {
            NSURL *fileURL = [urls objectAtIndex:0];
            [self loadImageFromURL:fileURL];
        }
    }];
#else
    // GNUstep: Use modal dialog
    NSArray *urls = [dialog showModal];
    if (urls && urls.count > 0) {
        NSURL *fileURL = [urls objectAtIndex:0];
        [self loadImageFromURL:fileURL];
    }
#endif
}

- (void)loadImageFromURL:(NSURL *)url {
#if TARGET_OS_IPHONE
    // iOS: Load UIImage
    UIImage *uiImage = nil;
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    if (imageData) {
        uiImage = [UIImage imageWithData:imageData];
    }
    
    if (uiImage) {
        // Store UIImage directly (decoder will handle conversion)
        self.currentImage = (id)uiImage; // Store as id to work with both UIImage and NSImage
        self.originalImage = (id)uiImage;
        
        // Set image in image view (UIImageView on iOS)
        if ([self.imageView respondsToSelector:@selector(setImage:)]) {
            [self.imageView performSelector:@selector(setImage:) withObject:uiImage];
        }
        
        [self.decodeButton setEnabled:YES];
        [self.applyDistortionButton setEnabled:YES];
        [self.previewDistortionButton setEnabled:YES];
        self.originalEncodedData = nil;
        [self.distorter clearDistortions];
        [self.clearDistortionButton setEnabled:NO];
        [self updateApplicationMenuStates];
        [self.textView setString:[NSString stringWithFormat:@"Image loaded: %@\n\nClick 'Decode' to scan for barcodes, or apply distortions to test decodability.", [url lastPathComponent] ? [url lastPathComponent] : @"from Photos/Files"]];
    } else {
        [self.textView setString:[NSString stringWithFormat:@"Error: Could not load image from:\n%@\n\nPlease ensure the file is a valid image format (JPEG, PNG).", url]];
    }
#else
    // macOS/Linux/Windows: Use NSImage directly
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
    if (image) {
        self.currentImage = image;
        self.originalImage = image; // Store as original
        [self.imageView setImage:image];
        [self.decodeButton setEnabled:YES];
        [self.applyDistortionButton setEnabled:YES];
        [self.previewDistortionButton setEnabled:YES];
        // Clear original encoded data and distortions when loading external image
        self.originalEncodedData = nil;
        [self.distorter clearDistortions];
        [self.clearDistortionButton setEnabled:NO];
        [self updateApplicationMenuStates];
        [self.textView setString:[NSString stringWithFormat:@"Image loaded: %@\n\nClick 'Decode' to scan for barcodes, or apply distortions to test decodability.", [url lastPathComponent]]];
    } else {
        // Show error in text view instead of popup
        [self.textView setString:[NSString stringWithFormat:@"Error: Could not load image from:\n%@\n\nPlease ensure the file exists and is a valid image format (JPEG, PNG, TIFF).", url]];
    }
#endif
}

- (void)decodeImage:(id)sender {
    if (!self.currentImage) {
        return;
    }
    
    [self.textView setString:@"Decoding barcodes...\n"];
    
    // Decode on background thread using SmallStep abstraction
    [SSConcurrency performSelectorInBackground:@selector(decodeInBackground:) onTarget:self withObject:nil];
}

- (void)decodeInBackground:(id)object {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Pass original encoded data if available for matching
    NSArray *results = [self.decoder decodeBarcodesFromImage:self.currentImage originalInput:self.originalEncodedData];
    
    [SSConcurrency performSelectorOnMainThread:@selector(updateResults:) onTarget:self withObject:results waitUntilDone:YES];
    [pool release];
}

- (NSString *)matchStatusForResult:(BarcodeResult *)result {
    if (!result.originalInput) {
        return @"N/A"; // No original input to compare
    }
    
    if ([result.data isEqualToString:result.originalInput]) {
        return @"[MATCH] ✓"; // Green indicator
    } else {
        // Check for partial match (similar strings)
        if ([result.data length] > 0 && [result.originalInput length] > 0) {
            // Simple similarity check - if decoded data contains original or vice versa
            NSRange range = [result.data rangeOfString:result.originalInput];
            if (range.location != NSNotFound) {
                return @"[PARTIAL] ~"; // Yellow indicator
            }
            range = [result.originalInput rangeOfString:result.data];
            if (range.location != NSNotFound) {
                return @"[PARTIAL] ~"; // Yellow indicator
            }
        }
        return @"[MISMATCH] ✗"; // Red indicator
    }
}

- (NSString *)qualityScoreString:(NSInteger)quality {
    if (quality < 0) {
        return @"N/A";
    }
    return [NSString stringWithFormat:@"%ld/100", (long)quality];
}

- (void)updateResults:(NSArray *)results {
    // Check if decoder has a backend
    if (!self.decoder || ![self.decoder hasBackend]) {
        NSMutableString *errorMsg = [NSMutableString string];
        [errorMsg appendString:@"No barcode decoder available.\n\n"];
        [errorMsg appendString:@"This application requires a barcode decoding library to function:\n"];
        [errorMsg appendString:@"- ZBar (libzbar) for barcode decoding\n"];
        [errorMsg appendString:@"- ZInt (libzint) for barcode encoding (decoding not yet supported)\n\n"];
        [errorMsg appendString:@"Please install one of these libraries:\n"];
        [errorMsg appendString:@"- Linux: sudo apt-get install libzbar-dev\n"];
        [errorMsg appendString:@"- macOS: brew install zbar\n\n"];
        [errorMsg appendString:@"Note: Dynamic library loading will be available in a future version."];
        [self.textView setString:errorMsg];
        return;
    }
    
    if (results && results.count > 0) {
        NSMutableString *output = [NSMutableString string];
        [output appendString:@"Barcode Decoding Results:\n"];
        [output appendString:@"========================\n\n"];
        
        NSInteger i;
        for (i = 0; i < results.count; i++) {
            BarcodeResult *result = [results objectAtIndex:i];
            [output appendFormat:@"Barcode #%ld:\n", (long)(i + 1)];
            [output appendFormat:@"  Type: %@\n", result.type];
            [output appendFormat:@"  Data: %@\n", result.data];
            
            // Display quality score
            if (result.quality >= 0) {
                [output appendFormat:@"  Quality: %@\n", [self qualityScoreString:result.quality]];
            } else {
                [output appendString:@"  Quality: N/A\n"];
            }
            
            // Display match status if original input is available
            if (result.originalInput) {
                [output appendFormat:@"  Original Input: %@\n", result.originalInput];
                NSString *matchStatus = [self matchStatusForResult:result];
                [output appendFormat:@"  Match Status: %@\n", matchStatus];
            }
            
            [output appendFormat:@"  Location Points: %lu\n", (unsigned long)result.points.count];
            [output appendString:@"\n"];
        }
        
        // Add summary if original input was provided
        if (self.originalEncodedData) {
            [output appendString:@"\n--- Summary ---\n"];
            NSInteger matchCount = 0;
            NSInteger mismatchCount = 0;
            NSInteger partialCount = 0;
            NSInteger totalQuality = 0;
            NSInteger qualityCount = 0;
            
            for (i = 0; i < results.count; i++) {
                BarcodeResult *result = [results objectAtIndex:i];
                NSString *matchStatus = [self matchStatusForResult:result];
                if ([matchStatus rangeOfString:@"[MATCH]"].location != NSNotFound) {
                    matchCount++;
                } else if ([matchStatus rangeOfString:@"[MISMATCH]"].location != NSNotFound) {
                    mismatchCount++;
                } else if ([matchStatus rangeOfString:@"[PARTIAL]"].location != NSNotFound) {
                    partialCount++;
                }
                
                if (result.quality >= 0) {
                    totalQuality += result.quality;
                    qualityCount++;
                }
            }
            
            [output appendFormat:@"Matches: %ld\n", (long)matchCount];
            [output appendFormat:@"Mismatches: %ld\n", (long)mismatchCount];
            if (partialCount > 0) {
                [output appendFormat:@"Partial: %ld\n", (long)partialCount];
            }
            
            if (qualityCount > 0) {
                NSInteger avgQuality = totalQuality / qualityCount;
                [output appendFormat:@"Average Quality: %ld/100\n", (long)avgQuality];
            }
        }
        
        [self.textView setString:output];
    } else {
        NSMutableString *msg = [NSMutableString string];
        [msg appendString:@"No barcodes found in the image.\n\n"];
        [msg appendString:@"Please try:\n"];
        [msg appendString:@"- Ensuring the image is clear and in focus\n"];
        [msg appendString:@"- Using a higher resolution image\n"];
        [msg appendString:@"- Checking that the barcode is not damaged or obscured\n"];
        if (self.originalEncodedData) {
            [msg appendString:@"\nNote: The barcode was encoded from: "];
            [msg appendString:self.originalEncodedData];
            [msg appendString:@"\nIf decoding failed, the distortion may be too high."];
        }
        [self.textView setString:msg];
    }
}

- (void)checkAndDisplayBackendStatus {
    // Check encoder backend status
    BOOL encoderAvailable = [self.encoder hasBackend];
    NSString *encoderName = [self.encoder backendName];
    
    // Populate symbology popup
    [self populateSymbologyPopup];
    
    // Update UI based on availability
    [self.encodeButton setEnabled:encoderAvailable];
    [self.symbologyPopup setEnabled:encoderAvailable];
    [self updateApplicationMenuStates];
    
    // Display status message
    NSMutableString *statusMessage = [NSMutableString string];
    [statusMessage appendString:@"SmallBarcoder - Barcode Encoder/Decoder\n"];
    [statusMessage appendString:@"=====================================\n\n"];
    
    if (encoderAvailable) {
        [statusMessage appendFormat:@"✓ ZInt encoder loaded successfully\n"];
        [statusMessage appendFormat:@"Backend: %@\n\n", encoderName];
        
        NSArray *symbologies = [self.encoder supportedSymbologies];
        if (symbologies.count > 0) {
            [statusMessage appendFormat:@"Available barcode types: %ld\n", (long)symbologies.count];
            [statusMessage appendString:@"\nYou can now:\n"];
            [statusMessage appendString:@"- Enter text in the encoding field\n"];
            [statusMessage appendString:@"- Select a barcode type from the dropdown\n"];
            [statusMessage appendString:@"- Click 'Encode' to generate a barcode\n"];
        }
    } else {
        [statusMessage appendString:@"✗ ZInt encoder not available\n\n"];
        [statusMessage appendString:@"Please ensure ZInt library is installed:\n"];
        [statusMessage appendString:@"- Linux: sudo apt-get install libzint-dev\n"];
        [statusMessage appendString:@"- macOS: brew install zint\n\n"];
        [statusMessage appendString:@"The library should be linked at build time."];
    }
    
    // Check decoder backend status
    BOOL decoderAvailable = [self.decoder hasBackend];
    NSString *decoderName = [self.decoder backendName];
    
    [statusMessage appendString:@"\n\n"];
    if (decoderAvailable) {
        [statusMessage appendFormat:@"✓ Decoder backend: %@\n", decoderName];
    } else {
        [statusMessage appendString:@"✗ No decoder backend available\n"];
    }
    
    [self.textView setString:statusMessage];
}

- (void)populateSymbologyPopup {
    [self.symbologyPopup removeAllItems];
    
    if (![self.encoder hasBackend]) {
        [self.symbologyPopup addItemWithTitle:@"No encoder available"];
        [self.symbologyPopup setEnabled:NO];
        return;
    }
    
    NSArray *symbologies = [self.encoder supportedSymbologies];
    if (!symbologies || symbologies.count == 0) {
        [self.symbologyPopup addItemWithTitle:@"No symbologies available"];
        [self.symbologyPopup setEnabled:NO];
        return;
    }
    
    [self.symbologyPopup setEnabled:YES];
    NSInteger i;
    for (i = 0; i < symbologies.count; i++) {
        NSDictionary *symbology = [symbologies objectAtIndex:i];
        if (!symbology) continue;
        
        NSString *name = [symbology objectForKey:@"name"];
        if (name && name.length > 0) {
            [self.symbologyPopup addItemWithTitle:name];
            // Store symbology ID in menu item's tag
            NSNumber *symbologyId = [symbology objectForKey:@"id"];
            if (symbologyId) {
                NSInteger itemIndex = [self.symbologyPopup numberOfItems] - 1;
                [[self.symbologyPopup itemAtIndex:itemIndex] setTag:[symbologyId intValue]];
            }
        }
    }
    
    // Select first item by default
    if ([self.symbologyPopup numberOfItems] > 0) {
        [self.symbologyPopup selectItemAtIndex:0];
    }
}

- (void)encodeBarcode:(id)sender {
    if (![self.encoder hasBackend]) {
        [self.textView setString:@"No barcode encoder available.\n\nPlease install ZInt library:\n- Linux: sudo apt-get install libzint-dev\n- macOS: brew install zint"];
        return;
    }
    
    NSString *data = [self.encodeTextField stringValue];
    if (!data || data.length == 0) {
        [self.textView setString:@"Please enter text to encode."];
        return;
    }
    
    NSInteger selectedIndex = [self.symbologyPopup indexOfSelectedItem];
    if (selectedIndex < 0 || selectedIndex >= [self.symbologyPopup numberOfItems]) {
        [self.textView setString:@"Please select a barcode type."];
        return;
    }
    
    // Store original data for matching later
    self.originalEncodedData = data;
    
    [self.textView setString:@"Encoding barcode...\n"];
    
    // Encode on background thread
    NSDictionary *encodeParams = [NSDictionary dictionaryWithObjectsAndKeys:
        data, @"data",
        [NSNumber numberWithInt:[[self.symbologyPopup selectedItem] tag]], @"symbology",
        nil];
    [SSConcurrency performSelectorInBackground:@selector(encodeInBackground:) onTarget:self withObject:encodeParams];
}

- (void)encodeInBackground:(id)object {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *params = (NSDictionary *)object;
    NSString *data = [params objectForKey:@"data"];
    NSNumber *symbologyNum = [params objectForKey:@"symbology"];
    int symbology = [symbologyNum intValue];
    
    NSImage *encodedImage = [self.encoder encodeBarcodeFromData:data symbology:symbology];
    
    [SSConcurrency performSelectorOnMainThread:@selector(updateEncodedImage:) onTarget:self withObject:encodedImage waitUntilDone:YES];
    [pool release];
}

- (void)updateEncodedImage:(NSImage *)image {
    if (!image) {
        [self.textView setString:@"Encoding failed.\n\nPlease check:\n- The text is valid for the selected barcode type\n- ZInt library is properly installed\n- Try a different barcode type"];
        return;
    }
    
    // Store as original before applying any distortions
    self.originalImage = image;
    self.currentImage = image;
    [self.imageView setImage:image];
    [self.decodeButton setEnabled:YES];
    [self.saveButton setEnabled:YES];
    [self.applyDistortionButton setEnabled:YES];
    [self.previewDistortionButton setEnabled:YES];
    [self.testDecodabilityButton setEnabled:YES];
    [self.runProgressiveTestButton setEnabled:YES];
    [self.progressiveTestSlider setEnabled:YES];
    
    // Clear any previous distortions
    [self.distorter clearDistortions];
    [self.clearDistortionButton setEnabled:NO];
    [self updateApplicationMenuStates];
    
    NSMutableString *output = [NSMutableString string];
    [output appendString:@"Barcode Encoded Successfully\n"];
    [output appendString:@"===========================\n\n"];
    [output appendFormat:@"Data: %@\n", self.originalEncodedData];
    [output appendFormat:@"Type: %@\n", [[self.symbologyPopup selectedItem] title]];
    [output appendString:@"\n"];
    [output appendString:@"The barcode image is displayed on the left.\n"];
    [output appendString:@"You can:\n"];
    [output appendString:@"- Apply distortions to test decodability limits\n"];
    [output appendString:@"- Use 'Test Decodability' for single test\n"];
    [output appendString:@"- Use 'Run Progressive Test' for systematic testing\n"];
    [output appendString:@"- Click 'Decode' to verify it can be read\n"];
    [output appendString:@"- Click 'Save Image...' to save it to a file"];
    
    [self.textView setString:output];
}

- (void)saveImage:(id)sender {
    if (!self.currentImage) {
        return;
    }
    
    SSFileDialog *dialog = [SSFileDialog saveDialog];
    [dialog setAllowedFileTypes:[NSArray arrayWithObjects:@"png", @"jpg", @"jpeg", @"tiff", @"tif", nil]];
    [dialog setCanCreateDirectories:YES];
    
#if __has_feature(blocks) || (TARGET_OS_IPHONE && __clang__)
    // Use completion handler on platforms that support blocks
    [dialog showWithCompletionHandler:^(SSFileDialogResult result, NSArray *urls) {
        if (result == SSFileDialogResultOK && urls.count > 0) {
            NSURL *fileURL = [urls objectAtIndex:0];
            [self saveImageToURL:fileURL];
        }
    }];
#else
    // GNUstep: Use modal dialog
    NSArray *urls = [dialog showModal];
    if (urls && urls.count > 0) {
        NSURL *fileURL = [urls objectAtIndex:0];
        [self saveImageToURL:fileURL];
    }
#endif
}

- (void)saveImageToURL:(NSURL *)url {
    // Get file extension to determine format
    NSString *extension = [[url pathExtension] lowercaseString];
    NSBitmapImageRep *bitmapRep = nil;
    
    // Get bitmap representation
    NSArray *reps = [self.currentImage representations];
    for (NSImageRep *rep in reps) {
        if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
            bitmapRep = (NSBitmapImageRep *)rep;
            break;
        }
    }
    
    if (!bitmapRep) {
        // Create bitmap representation if none exists
        NSRect imageRect = NSMakeRect(0, 0, [self.currentImage size].width, [self.currentImage size].height);
        bitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                             pixelsWide:imageRect.size.width
                                                             pixelsHigh:imageRect.size.height
                                                          bitsPerSample:8
                                                        samplesPerPixel:4
                                                               hasAlpha:YES
                                                               isPlanar:NO
                                                         colorSpaceName:NSCalibratedRGBColorSpace
                                                           bytesPerRow:0
                                                          bitsPerPixel:0];
        [self.currentImage lockFocus];
        [bitmapRep setSize:imageRect.size];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapRep]];
        [self.currentImage drawAtPoint:NSZeroPoint fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
        [self.currentImage unlockFocus];
    }
    
    NSData *imageData = nil;
    if ([extension isEqualToString:@"png"]) {
        imageData = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
    } else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
        imageData = [bitmapRep representationUsingType:NSJPEGFileType properties:nil];
    } else if ([extension isEqualToString:@"tiff"] || [extension isEqualToString:@"tif"]) {
        imageData = [bitmapRep representationUsingType:NSTIFFFileType properties:nil];
    } else {
        // Default to PNG
        imageData = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
    }
    
    if (imageData) {
        SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
        NSError *error = nil;
        BOOL success = [fileSystem writeData:imageData toPath:[url path] error:&error];
        if (success) {
            [self.textView setString:[NSString stringWithFormat:@"Image saved successfully to:\n%@", [url path]]];
        } else {
            [self.textView setString:[NSString stringWithFormat:@"Error saving image:\n%@", error ? [error localizedDescription] : @"Unknown error"]];
        }
    } else {
        [self.textView setString:@"Error: Could not create image data."];
    }
}

- (void)populateDistortionTypePopup {
    [self.distortionTypePopup removeAllItems];
    
    NSArray *types = [ImageDistorter availableDistortionTypes];
    NSInteger i;
    for (i = 0; i < types.count; i++) {
        NSNumber *typeNum = [types objectAtIndex:i];
        DistortionType type = (DistortionType)[typeNum intValue];
        NSString *name = [ImageDistorter nameForDistortionType:type];
        [self.distortionTypePopup addItemWithTitle:name];
        [[self.distortionTypePopup itemAtIndex:i] setTag:type];
    }
}

- (void)updateDistortionLabels {
    float intensity = [self.distortionIntensitySlider floatValue];
    float strength = [self.distortionStrengthSlider floatValue];
    
    [self.distortionIntensityLabel setStringValue:[NSString stringWithFormat:@"Intensity: %.2f", intensity]];
    [self.distortionStrengthLabel setStringValue:[NSString stringWithFormat:@"Strength: %.2f", strength]];
}

- (void)applyDistortion:(id)sender {
    if (!self.currentImage) {
        return;
    }
    
    [self applyDistortionToCurrentImage];
}

- (void)previewDistortion:(id)sender {
    if (!self.currentImage) {
        return;
    }
    
    // Create temporary distortion for preview
    NSInteger selectedIndex = [self.distortionTypePopup indexOfSelectedItem];
    if (selectedIndex < 0) {
        return;
    }
    
    DistortionType type = (DistortionType)[[self.distortionTypePopup selectedItem] tag];
    float intensity = [self.distortionIntensitySlider floatValue];
    float strength = [self.distortionStrengthSlider floatValue];
    
    DistortionParameters *params = [DistortionParameters parametersWithType:type intensity:intensity strength:strength];
    NSImage *previewImage = [ImageDistorter applyDistortion:params toImage:self.currentImage];
    
    if (previewImage) {
        [self.imageView setImage:previewImage];
        [self.textView setString:@"Preview: Distortion applied. Click 'Apply Distortion' to make it permanent, or 'Clear' to restore original."];
    }
}

- (void)clearDistortion:(id)sender {
    [self.distorter clearDistortions];
    
    if (self.originalImage) {
        self.currentImage = self.originalImage;
        [self.imageView setImage:self.currentImage];
        [self.textView setString:@"Distortions cleared. Original image restored."];
    }
    
    [self.clearDistortionButton setEnabled:NO];
}

- (void)applyDistortionToCurrentImage {
    NSInteger selectedIndex = [self.distortionTypePopup indexOfSelectedItem];
    if (selectedIndex < 0) {
        return;
    }
    
    DistortionType type = (DistortionType)[[self.distortionTypePopup selectedItem] tag];
    float intensity = [self.distortionIntensitySlider floatValue];
    float strength = [self.distortionStrengthSlider floatValue];
    
    DistortionParameters *params = [DistortionParameters parametersWithType:type intensity:intensity strength:strength];
    [self.distorter addDistortion:params];
    
    // Store original image if not already stored
    if (!self.originalImage) {
        self.originalImage = [self.currentImage retain];
    }
    
    // Apply all distortions
    NSImage *distortedImage = [self.distorter applyDistortionsToImage:self.originalImage];
    if (distortedImage) {
        self.currentImage = distortedImage;
        [self.imageView setImage:self.currentImage];
        [self.decodeButton setEnabled:YES];
        [self.clearDistortionButton setEnabled:YES];
        [self updateApplicationMenuStates];
        
        NSInteger distortionCount = [self.distorter distortions].count;
        [self.textView setString:[NSString stringWithFormat:@"Distortion applied. Total distortions: %ld\n\nYou can apply more distortions or decode the image.", (long)distortionCount]];
    }
}

- (void)loadLibrary:(id)sender {
#if TARGET_OS_IPHONE || TARGET_OS_WIN32
    // Dynamic library loading not supported
    [self.textView setString:@"Dynamic library loading is not supported on this platform.\n\nLibraries must be statically linked at build time."];
#else
    SSFileDialog *dialog = [SSFileDialog openDialog];
    [dialog setCanChooseFiles:YES];
    [dialog setCanChooseDirectories:NO];
    [dialog setAllowsMultipleSelection:NO];
    
    NSString *extension = [DynamicLibraryLoader libraryExtension];
    if (extension) {
        [dialog setAllowedFileTypes:[NSArray arrayWithObjects:extension, nil]];
        
#if __has_feature(blocks) || (TARGET_OS_IPHONE && __clang__)
        [dialog showWithCompletionHandler:^(SSFileDialogResult result, NSArray *urls) {
            if (result == SSFileDialogResultOK && urls.count > 0) {
                NSURL *fileURL = [urls objectAtIndex:0];
                [self loadLibraryFromURL:fileURL];
            }
        }];
#else
        NSArray *urls = [dialog showModal];
        if (urls && urls.count > 0) {
            NSURL *fileURL = [urls objectAtIndex:0];
            [self loadLibraryFromURL:fileURL];
        }
#endif
    } else {
        [self.textView setString:@"Dynamic library loading is not available on this platform."];
    }
#endif
}

- (void)loadLibraryFromURL:(NSURL *)url {
    NSError *error = nil;
    DynamicLibrary *library = [DynamicLibraryLoader loadLibraryAtPath:[url path] error:&error];
    
    if (!library) {
        NSString *errorMsg = error ? [error localizedDescription] : [DynamicLibraryLoader lastError];
        [self.textView setString:[NSString stringWithFormat:@"Failed to load library:\n%@\n\nError: %@", [url path], errorMsg ? errorMsg : @"Unknown error"]];
        return;
    }
    
    // Add to loaded libraries list
    [self.loadedLibraries addObject:library];
    
    // Update status
    [self updateLibraryStatus];
    
    // Try to detect and register backends from the loaded library
    NSDictionary *backends = [BackendFactory scanLibraryForBackends:library];
    NSMutableString *msg = [NSMutableString string];
    [msg appendString:@"Library Loaded Successfully\n"];
    [msg appendString:@"==========================\n\n"];
    [msg appendFormat:@"Path: %@\n", [url path]];
    [msg appendFormat:@"Total libraries loaded: %ld\n\n", (long)self.loadedLibraries.count];
    
    // Check if backends were found
    id decoderBackend = [backends objectForKey:@"decoder"];
    id encoderBackend = [backends objectForKey:@"encoder"];
    
    if (decoderBackend) {
        [self.decoder registerDynamicBackend:decoderBackend];
        [msg appendFormat:@"✓ Decoder backend registered: %@\n", [decoderBackend backendName]];
    }
    
    if (encoderBackend) {
        [self.encoder registerDynamicBackend:encoderBackend];
        [msg appendFormat:@"✓ Encoder backend registered: %@\n", [encoderBackend backendName]];
    }
    
    if (!decoderBackend && !encoderBackend) {
        [msg appendString:@"\nNote: No backends detected in this library.\n"];
        [msg appendString:@"The library may not contain ZBar or ZInt symbols,\n"];
        [msg appendString:@"or dynamic backend loading is not yet fully implemented.\n"];
        [msg appendString:@"Static backends are still available."];
    } else {
        [msg appendString:@"\nBackends are now available for use."];
    }
    
    [self.textView setString:msg];
}

- (void)updateLibraryStatus {
    // Update UI to show loaded libraries
    // This could be enhanced to show library list in a separate view
    if (self.loadedLibraries.count > 0) {
        // Libraries are loaded
    }
    [self updateApplicationMenuStates];
}

- (void)updateApplicationMenuStates {
    // Update application menu states when button states change
    if (applicationMenu) {
        [applicationMenu updateMenuStates];
    }
}

- (void)tryAutoLoadZIntLibrary {
    // Check if encoder already has a backend
    if ([self.encoder hasBackend]) {
        return; // Already have a backend
    }
    
    // Try to find and load ZInt library
    NSString *zintPath = [DynamicLibraryLoader findLibrary:@"zint"];
    if (!zintPath) {
        // Try common locations
        NSArray *searchPaths = [DynamicLibraryLoader standardSearchPaths];
        NSInteger i;
        for (i = 0; i < searchPaths.count; i++) {
            NSString *searchPath = [searchPaths objectAtIndex:i];
            NSString *testPath = [searchPath stringByAppendingPathComponent:@"libzint.so"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:testPath]) {
                zintPath = testPath;
                break;
            }
            // Also try versioned names
            testPath = [searchPath stringByAppendingPathComponent:@"libzint.so.2"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:testPath]) {
                zintPath = testPath;
                break;
            }
            testPath = [searchPath stringByAppendingPathComponent:@"libzint.so.2.15"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:testPath]) {
                zintPath = testPath;
                break;
            }
        }
    }
    
    if (zintPath) {
        NSError *error = nil;
        DynamicLibrary *library = [DynamicLibraryLoader loadLibraryAtPath:zintPath error:&error];
        if (library) {
            [self.loadedLibraries addObject:library];
            
            // Try to register backends from the library
            NSDictionary *backends = [BackendFactory scanLibraryForBackends:library];
            id encoderBackend = [backends objectForKey:@"encoder"];
            if (encoderBackend) {
                [self.encoder registerDynamicBackend:encoderBackend];
            }
        }
    }
}

- (void)testDecodability:(id)sender {
    if (![self.encoder hasBackend] || ![self.decoder hasBackend]) {
        [self.textView setString:@"Both encoder and decoder are required for testing.\n\nPlease ensure ZInt and ZBar libraries are available."];
        return;
    }
    
    NSString *testData = [self.encodeTextField stringValue];
    if (!testData || testData.length == 0) {
        [self.textView setString:@"Please enter test data in the encoding field first."];
        return;
    }
    
    NSInteger selectedIndex = [self.symbologyPopup indexOfSelectedItem];
    if (selectedIndex < 0) {
        [self.textView setString:@"Please select a barcode type."];
        return;
    }
    
    int symbology = [[self.symbologyPopup selectedItem] tag];
    NSInteger distIndex = [self.distortionTypePopup indexOfSelectedItem];
    if (distIndex < 0) {
        [self.textView setString:@"Please select a distortion type."];
        return;
    }
    
    DistortionType distType = (DistortionType)[[self.distortionTypePopup selectedItem] tag];
    float intensity = [self.distortionIntensitySlider floatValue];
    float strength = [self.distortionStrengthSlider floatValue];
    
    [self.textView setString:@"Running decodability test...\n"];
    
    // Run test in background
    NSDictionary *testParams = [NSDictionary dictionaryWithObjectsAndKeys:
        testData, @"data",
        [NSNumber numberWithInt:symbology], @"symbology",
        [NSNumber numberWithInt:distType], @"distortionType",
        [NSNumber numberWithFloat:intensity], @"intensity",
        [NSNumber numberWithFloat:strength], @"strength",
        nil];
    
    [SSConcurrency performSelectorInBackground:@selector(runTestInBackground:) onTarget:self withObject:testParams];
}

- (void)runTestInBackground:(id)object {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *params = (NSDictionary *)object;
    NSString *testData = [params objectForKey:@"data"];
    int symbology = [[params objectForKey:@"symbology"] intValue];
    NSInteger distType = [[params objectForKey:@"distortionType"] intValue];
    float intensity = [[params objectForKey:@"intensity"] floatValue];
    float strength = [[params objectForKey:@"strength"] floatValue];
    
    BarcodeTestResult *result = [self.tester runTestWithData:testData
                                                    symbology:symbology
                                                distortionType:distType
                                                     intensity:intensity
                                                       strength:strength];
    
    [SSConcurrency performSelectorOnMainThread:@selector(updateTestResult:) onTarget:self withObject:result waitUntilDone:YES];
    [pool release];
}

- (void)updateTestResult:(BarcodeTestResult *)result {
    if (!result) {
        [self.textView setString:@"Test failed: Could not encode or decode barcode."];
        return;
    }
    
    NSMutableString *output = [NSMutableString string];
    [output appendString:@"Decodability Test Result\n"];
    [output appendString:@"========================\n\n"];
    [output appendFormat:@"Barcode Type: %@\n", result.barcodeType];
    [output appendFormat:@"Test Data: %@\n", result.testData];
    [output appendFormat:@"Distortion: %@ (Intensity: %.2f, Strength: %.2f)\n", 
        [ImageDistorter nameForDistortionType:(DistortionType)result.distortionType],
        result.distortionIntensity,
        result.distortionStrength];
    [output appendString:@"\n"];
    [output appendFormat:@"Decode Success: %@\n", result.decodeSuccess ? @"YES" : @"NO"];
    
    if (result.decodeSuccess) {
        [output appendFormat:@"Quality Score: %ld/100\n", (long)result.qualityScore];
        [output appendFormat:@"Decoded Data: %@\n", result.decodedData];
        [output appendFormat:@"Data Matches: %@\n", result.dataMatches ? @"YES ✓" : @"NO ✗"];
    } else {
        [output appendString:@"\nThe barcode could not be decoded at this distortion level.\n"];
        [output appendString:@"Try reducing the distortion intensity."];
    }
    
    [self.textView setString:output];
}

- (void)progressiveTestSliderChanged:(id)sender {
    [self updateProgressiveTestLabel];
    
    // Real-time test as slider changes
    if ([self.progressiveTestSlider isEnabled] && self.currentImage && self.originalEncodedData) {
        float intensity = [self.progressiveTestSlider floatValue];
        NSInteger distIndex = [self.distortionTypePopup indexOfSelectedItem];
        if (distIndex >= 0) {
            DistortionType distType = (DistortionType)[[self.distortionTypePopup selectedItem] tag];
            DistortionParameters *params = [DistortionParameters parametersWithType:distType intensity:intensity strength:0.5f];
            NSImage *distortedImage = [ImageDistorter applyDistortion:params toImage:self.originalImage];
            if (distortedImage) {
                self.currentImage = distortedImage;
                [self.imageView setImage:distortedImage];
                
                // Try to decode in background
                NSArray *results = [self.decoder decodeBarcodesFromImage:distortedImage originalInput:self.originalEncodedData];
                if (results && results.count > 0) {
                    BarcodeResult *decodeResult = [results objectAtIndex:0];
                    BOOL matches = decodeResult.originalInput && [decodeResult.data isEqualToString:decodeResult.originalInput];
                    [self.progressiveTestLabel setStringValue:[NSString stringWithFormat:@"Intensity: %.2f [Decoded: %@]", intensity, matches ? @"✓" : @"✗"]];
                } else {
                    [self.progressiveTestLabel setStringValue:[NSString stringWithFormat:@"Intensity: %.2f [Failed]", intensity]];
                }
            }
        }
    }
}

- (void)updateProgressiveTestLabel {
    float intensity = [self.progressiveTestSlider floatValue];
    [self.progressiveTestLabel setStringValue:[NSString stringWithFormat:@"Intensity: %.2f", intensity]];
}

- (void)runProgressiveTest:(id)sender {
    if (![self.encoder hasBackend] || ![self.decoder hasBackend]) {
        [self.textView setString:@"Both encoder and decoder are required for testing."];
        return;
    }
    
    NSString *testData = [self.encodeTextField stringValue];
    if (!testData || testData.length == 0) {
        [self.textView setString:@"Please enter test data in the encoding field first."];
        return;
    }
    
    NSInteger selectedIndex = [self.symbologyPopup indexOfSelectedItem];
    if (selectedIndex < 0) {
        [self.textView setString:@"Please select a barcode type."];
        return;
    }
    
    int symbology = [[self.symbologyPopup selectedItem] tag];
    NSInteger distIndex = [self.distortionTypePopup indexOfSelectedItem];
    if (distIndex < 0) {
        [self.textView setString:@"Please select a distortion type."];
        return;
    }
    
    DistortionType distType = (DistortionType)[[self.distortionTypePopup selectedItem] tag];
    
    // Create new test session
    NSString *sessionName = [NSString stringWithFormat:@"Progressive Test - %@", [[NSDate date] description]];
    self.currentTestSession = [[BarcodeTestSession alloc] initWithName:sessionName];
    
    [self.textView setString:@"Running progressive distortion test...\nThis will test intensity levels from 0.0 to 1.0 in 20 steps.\n"];
    
    // Run progressive test in background
    NSDictionary *testParams = [NSDictionary dictionaryWithObjectsAndKeys:
        testData, @"data",
        [NSNumber numberWithInt:symbology], @"symbology",
        [NSNumber numberWithInt:distType], @"distortionType",
        nil];
    
    [SSConcurrency performSelectorInBackground:@selector(runProgressiveTestInBackground:) onTarget:self withObject:testParams];
}

- (void)runProgressiveTestInBackground:(id)object {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *params = (NSDictionary *)object;
    NSString *testData = [params objectForKey:@"data"];
    int symbology = [[params objectForKey:@"symbology"] intValue];
    NSInteger distType = [[params objectForKey:@"distortionType"] intValue];
    
    NSArray *results = [self.tester runProgressiveTestWithData:testData
                                                      symbology:symbology
                                                  distortionType:distType
                                                   startIntensity:0.0f
                                                     endIntensity:1.0f
                                                            steps:20
                                                           session:self.currentTestSession];
    
    [SSConcurrency performSelectorOnMainThread:@selector(updateProgressiveTestResults:) onTarget:self withObject:results waitUntilDone:YES];
    [pool release];
}

- (void)updateProgressiveTestResults:(NSArray *)results {
    if (!results || results.count == 0) {
        [self.textView setString:@"Progressive test failed: Could not run tests."];
        return;
    }
    
    [self.currentTestSession endSession];
    NSDictionary *summary = [self.currentTestSession summaryStatistics];
    
    NSMutableString *output = [NSMutableString string];
    [output appendString:@"Progressive Test Results\n"];
    [output appendString:@"========================\n\n"];
    [output appendFormat:@"Total Tests: %d\n", [[summary objectForKey:@"totalTests"] intValue]];
    [output appendFormat:@"Successful Decodes: %d\n", [[summary objectForKey:@"successfulDecodes"] intValue]];
    [output appendFormat:@"Matching Decodes: %d\n", [[summary objectForKey:@"matchingDecodes"] intValue]];
    
    NSNumber *avgQuality = [summary objectForKey:@"averageQuality"];
    if (avgQuality) {
        [output appendFormat:@"Average Quality: %.1f/100\n", [avgQuality floatValue]];
    }
    
    NSNumber *successRate = [summary objectForKey:@"successRate"];
    if (successRate) {
        [output appendFormat:@"Success Rate: %.1f%%\n", [successRate floatValue]];
    }
    
    [output appendString:@"\n--- Detailed Results ---\n\n"];
    
    NSInteger successCount = 0;
    NSInteger failureCount = 0;
    float lastSuccessIntensity = -1.0f;
    float firstFailureIntensity = -1.0f;
    
    NSInteger i;
    for (i = 0; i < results.count; i++) {
        BarcodeTestResult *result = [results objectAtIndex:i];
        if (result.decodeSuccess) {
            successCount++;
            lastSuccessIntensity = result.distortionIntensity;
        } else {
            failureCount++;
            if (firstFailureIntensity < 0.0f) {
                firstFailureIntensity = result.distortionIntensity;
            }
        }
    }
    
    if (firstFailureIntensity >= 0.0f) {
        [output appendFormat:@"First Failure at Intensity: %.2f\n", firstFailureIntensity];
        if (lastSuccessIntensity >= 0.0f) {
            [output appendFormat:@"Last Success at Intensity: %.2f\n", lastSuccessIntensity];
            [output appendFormat:@"Failure Threshold: ~%.2f\n", (lastSuccessIntensity + firstFailureIntensity) / 2.0f];
        }
    } else {
        [output appendString:@"All tests passed! Barcode is resilient to this distortion type.\n"];
    }
    
    [self.exportTestResultsButton setEnabled:YES];
    [self updateApplicationMenuStates];
    [self.textView setString:output];
}

- (void)exportTestResults:(id)sender {
    if (!self.currentTestSession || self.currentTestSession.results.count == 0) {
        [self.textView setString:@"No test results to export."];
        return;
    }
    
    SSFileDialog *dialog = [SSFileDialog saveDialog];
    [dialog setAllowedFileTypes:[NSArray arrayWithObjects:@"csv", @"json", @"txt", nil]];
    [dialog setCanCreateDirectories:YES];
    
#if __has_feature(blocks) || (TARGET_OS_IPHONE && __clang__)
    [dialog showWithCompletionHandler:^(SSFileDialogResult result, NSArray *urls) {
        if (result == SSFileDialogResultOK && urls.count > 0) {
            NSURL *fileURL = [urls objectAtIndex:0];
            [self exportTestResultsToURL:fileURL];
        }
    }];
#else
    NSArray *urls = [dialog showModal];
    if (urls && urls.count > 0) {
        NSURL *fileURL = [urls objectAtIndex:0];
        [self exportTestResultsToURL:fileURL];
    }
#endif
}

- (void)exportTestResultsToURL:(NSURL *)url {
    NSString *extension = [[url pathExtension] lowercaseString];
    NSString *content = nil;
    
    if ([extension isEqualToString:@"csv"]) {
        content = [self.currentTestSession exportToCSV];
    } else if ([extension isEqualToString:@"json"]) {
        content = [self.currentTestSession exportToJSON];
    } else {
        // Default to CSV
        content = [self.currentTestSession exportToCSV];
    }
    
    if (content) {
        SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
        NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        BOOL success = [fileSystem writeData:data toPath:[url path] error:&error];
        if (success) {
            [self.textView setString:[NSString stringWithFormat:@"Test results exported successfully to:\n%@", [url path]]];
        } else {
            [self.textView setString:[NSString stringWithFormat:@"Error exporting results:\n%@", error ? [error localizedDescription] : @"Unknown error"]];
        }
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    // Close application menu (floating panel on Linux)
    if (applicationMenu) {
        [applicationMenu hideMenu];
    }
    
    // Unload all libraries before closing
    NSInteger i;
    for (i = 0; i < self.loadedLibraries.count; i++) {
        DynamicLibrary *library = [self.loadedLibraries objectAtIndex:i];
        [DynamicLibraryLoader unloadLibrary:library];
    }
    [self.loadedLibraries removeAllObjects];
    
    [NSApp terminate:nil];
}

#pragma mark - SSApplicationMenuDelegate

- (void)menuOpenImage:(id)sender {
    [self openImage:sender];
}

- (void)menuSaveImage:(id)sender {
    [self saveImage:sender];
}

- (void)menuDecodeImage:(id)sender {
    [self decodeImage:sender];
}

- (void)menuEncodeBarcode:(id)sender {
    [self encodeBarcode:sender];
}

- (void)menuApplyDistortion:(id)sender {
    [self applyDistortion:sender];
}

- (void)menuPreviewDistortion:(id)sender {
    [self previewDistortion:sender];
}

- (void)menuClearDistortion:(id)sender {
    [self clearDistortion:sender];
}

- (void)menuTestDecodability:(id)sender {
    [self testDecodability:sender];
}

- (void)menuRunProgressiveTest:(id)sender {
    [self runProgressiveTest:sender];
}

- (void)menuExportTestResults:(id)sender {
    [self exportTestResults:sender];
}

- (void)menuLoadLibrary:(id)sender {
    [self loadLibrary:sender];
}

- (BOOL)isSaveImageEnabled {
    return [self.saveButton isEnabled];
}

- (BOOL)isDecodeImageEnabled {
    return [self.decodeButton isEnabled];
}

- (BOOL)isEncodeBarcodeEnabled {
    return [self.encodeButton isEnabled];
}

- (BOOL)isApplyDistortionEnabled {
    return [self.applyDistortionButton isEnabled];
}

- (BOOL)isPreviewDistortionEnabled {
    return [self.previewDistortionButton isEnabled];
}

- (BOOL)isClearDistortionEnabled {
    return [self.clearDistortionButton isEnabled];
}

- (BOOL)isTestDecodabilityEnabled {
    return [self.testDecodabilityButton isEnabled];
}

- (BOOL)isRunProgressiveTestEnabled {
    return [self.runProgressiveTestButton isEnabled];
}

- (BOOL)isExportTestResultsEnabled {
    return [self.exportTestResultsButton isEnabled];
}

@end
