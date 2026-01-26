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
#import "../SmallStep/SmallStep/Core/SmallStep.h"

@interface WindowController (Private)

- (void)loadImageFromURL:(NSURL *)url;
- (void)decodeInBackground:(id)object;
- (void)updateResults:(NSArray *)results;
- (void)encodeInBackground:(id)object;
- (void)updateEncodedImage:(NSImage *)image;
- (void)populateSymbologyPopup;
- (void)populateDistortionTypePopup;
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
@synthesize loadedLibraries;
@synthesize decoder;
@synthesize encoder;
@synthesize distorter;
@synthesize currentImage;
@synthesize originalImage;
@synthesize originalEncodedData;

- (instancetype)init {
    self = [super init];
    if (self) {
        decoder = [[BarcodeDecoder alloc] init];
        encoder = [[BarcodeEncoder alloc] init];
        distorter = [[ImageDistorter alloc] init];
        loadedLibraries = [[NSMutableArray alloc] init];
        [self setupWindow];
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
    [loadLibraryButton release];
    [loadedLibraries release];
    [currentImage release];
    [originalImage release];
    [originalEncodedData release];
    [super dealloc];
}

- (void)setupWindow {
    // Create window using SmallStep abstraction - make it wider for encoding UI
    NSRect windowRect = NSMakeRect(100, 100, 900, 700);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowRect
                                                    styleMask:[SSWindowStyle standardWindowMask]
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setTitle:@"Small Barcode Reader"];
    [window setDelegate:self];
    [self setWindow:window];
    
    NSView *contentView = [window contentView];
    
    // Create image view
    NSRect imageViewRect = NSMakeRect(20, 350, 360, 300);
    self.imageView = [[NSImageView alloc] initWithFrame:imageViewRect];
    [self.imageView setImageAlignment:NSImageAlignCenter];
    [self.imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.imageView setImageFrameStyle:NSImageFrameGrayBezel];
    [contentView addSubview:self.imageView];
    
    // Create text view with scroll view
    NSRect textScrollRect = NSMakeRect(400, 50, 480, 600);
    self.textScrollView = [[NSScrollView alloc] initWithFrame:textScrollRect];
    [self.textScrollView setHasVerticalScroller:YES];
    [self.textScrollView setHasHorizontalScroller:YES];
    [self.textScrollView setAutohidesScrollers:YES];
    [self.textScrollView setBorderType:NSBezelBorder];
    
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
    
    // Create open button
    NSRect buttonRect = NSMakeRect(20, 300, 120, 32);
    self.openButton = [[NSButton alloc] initWithFrame:buttonRect];
    [self.openButton setTitle:@"Open Image..."];
    [self.openButton setButtonType:NSMomentaryPushInButton];
    [self.openButton setBezelStyle:NSRoundedBezelStyle];
    [self.openButton setTarget:self];
    [self.openButton setAction:@selector(openImage:)];
    [contentView addSubview:self.openButton];
    
    // Create decode button
    NSRect decodeButtonRect = NSMakeRect(150, 300, 120, 32);
    self.decodeButton = [[NSButton alloc] initWithFrame:decodeButtonRect];
    [self.decodeButton setTitle:@"Decode"];
    [self.decodeButton setButtonType:NSMomentaryPushInButton];
    [self.decodeButton setBezelStyle:NSRoundedBezelStyle];
    [self.decodeButton setTarget:self];
    [self.decodeButton setAction:@selector(decodeImage:)];
    [self.decodeButton setEnabled:NO];
    [contentView addSubview:self.decodeButton];
    
    // Create encoding text field
    NSRect textFieldRect = NSMakeRect(20, 250, 200, 24);
    self.encodeTextField = [[NSTextField alloc] initWithFrame:textFieldRect];
    [self.encodeTextField setPlaceholderString:@"Enter text to encode..."];
    [self.encodeTextField setTarget:self];
    [self.encodeTextField setAction:@selector(encodeBarcode:)];
    [contentView addSubview:self.encodeTextField];
    
    // Create symbology popup
    NSRect popupRect = NSMakeRect(230, 250, 150, 24);
    self.symbologyPopup = [[NSPopUpButton alloc] initWithFrame:popupRect pullsDown:NO];
    [self populateSymbologyPopup];
    [contentView addSubview:self.symbologyPopup];
    
    // Create encode button
    NSRect encodeButtonRect = NSMakeRect(20, 220, 120, 32);
    self.encodeButton = [[NSButton alloc] initWithFrame:encodeButtonRect];
    [self.encodeButton setTitle:@"Encode"];
    [self.encodeButton setButtonType:NSMomentaryPushInButton];
    [self.encodeButton setBezelStyle:NSRoundedBezelStyle];
    [self.encodeButton setTarget:self];
    [self.encodeButton setAction:@selector(encodeBarcode:)];
    [self.encodeButton setEnabled:[self.encoder hasBackend]];
    [contentView addSubview:self.encodeButton];
    
    // Create save button
    NSRect saveButtonRect = NSMakeRect(150, 220, 120, 32);
    self.saveButton = [[NSButton alloc] initWithFrame:saveButtonRect];
    [self.saveButton setTitle:@"Save Image..."];
    [self.saveButton setButtonType:NSMomentaryPushInButton];
    [self.saveButton setBezelStyle:NSRoundedBezelStyle];
    [self.saveButton setTarget:self];
    [self.saveButton setAction:@selector(saveImage:)];
    [self.saveButton setEnabled:NO];
    [contentView addSubview:self.saveButton];
    
    // Distortion controls section
    // Distortion type popup
    NSRect distortionPopupRect = NSMakeRect(20, 180, 150, 24);
    self.distortionTypePopup = [[NSPopUpButton alloc] initWithFrame:distortionPopupRect pullsDown:NO];
    [self populateDistortionTypePopup];
    [contentView addSubview:self.distortionTypePopup];
    
    // Intensity slider
    NSRect intensitySliderRect = NSMakeRect(20, 150, 200, 20);
    self.distortionIntensitySlider = [[NSSlider alloc] initWithFrame:intensitySliderRect];
    [self.distortionIntensitySlider setMinValue:0.0];
    [self.distortionIntensitySlider setMaxValue:1.0];
    [self.distortionIntensitySlider setDoubleValue:0.5];
    [self.distortionIntensitySlider setTarget:self];
    [self.distortionIntensitySlider setAction:@selector(updateDistortionLabels)];
    [contentView addSubview:self.distortionIntensitySlider];
    
    // Intensity label
    NSRect intensityLabelRect = NSMakeRect(230, 150, 100, 20);
    self.distortionIntensityLabel = [[NSTextField alloc] initWithFrame:intensityLabelRect];
    [self.distortionIntensityLabel setEditable:NO];
    [self.distortionIntensityLabel setBordered:NO];
    [self.distortionIntensityLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:self.distortionIntensityLabel];
    
    // Strength slider
    NSRect strengthSliderRect = NSMakeRect(20, 120, 200, 20);
    self.distortionStrengthSlider = [[NSSlider alloc] initWithFrame:strengthSliderRect];
    [self.distortionStrengthSlider setMinValue:0.0];
    [self.distortionStrengthSlider setMaxValue:1.0];
    [self.distortionStrengthSlider setDoubleValue:0.5];
    [self.distortionStrengthSlider setTarget:self];
    [self.distortionStrengthSlider setAction:@selector(updateDistortionLabels)];
    [contentView addSubview:self.distortionStrengthSlider];
    
    // Strength label
    NSRect strengthLabelRect = NSMakeRect(230, 120, 100, 20);
    self.distortionStrengthLabel = [[NSTextField alloc] initWithFrame:strengthLabelRect];
    [self.distortionStrengthLabel setEditable:NO];
    [self.distortionStrengthLabel setBordered:NO];
    [self.distortionStrengthLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [contentView addSubview:self.distortionStrengthLabel];
    
    // Apply distortion button
    NSRect applyDistortionRect = NSMakeRect(20, 90, 100, 32);
    self.applyDistortionButton = [[NSButton alloc] initWithFrame:applyDistortionRect];
    [self.applyDistortionButton setTitle:@"Apply Distortion"];
    [self.applyDistortionButton setButtonType:NSMomentaryPushInButton];
    [self.applyDistortionButton setBezelStyle:NSRoundedBezelStyle];
    [self.applyDistortionButton setTarget:self];
    [self.applyDistortionButton setAction:@selector(applyDistortion:)];
    [self.applyDistortionButton setEnabled:NO];
    [contentView addSubview:self.applyDistortionButton];
    
    // Preview distortion button
    NSRect previewDistortionRect = NSMakeRect(130, 90, 100, 32);
    self.previewDistortionButton = [[NSButton alloc] initWithFrame:previewDistortionRect];
    [self.previewDistortionButton setTitle:@"Preview"];
    [self.previewDistortionButton setButtonType:NSMomentaryPushInButton];
    [self.previewDistortionButton setBezelStyle:NSRoundedBezelStyle];
    [self.previewDistortionButton setTarget:self];
    [self.previewDistortionButton setAction:@selector(previewDistortion:)];
    [self.previewDistortionButton setEnabled:NO];
    [contentView addSubview:self.previewDistortionButton];
    
    // Clear distortion button
    NSRect clearDistortionRect = NSMakeRect(240, 90, 100, 32);
    self.clearDistortionButton = [[NSButton alloc] initWithFrame:clearDistortionRect];
    [self.clearDistortionButton setTitle:@"Clear"];
    [self.clearDistortionButton setButtonType:NSMomentaryPushInButton];
    [self.clearDistortionButton setBezelStyle:NSRoundedBezelStyle];
    [self.clearDistortionButton setTarget:self];
    [self.clearDistortionButton setAction:@selector(clearDistortion:)];
    [self.clearDistortionButton setEnabled:NO];
    [contentView addSubview:self.clearDistortionButton];
    
    // Load Library button
    NSRect loadLibraryRect = NSMakeRect(20, 50, 120, 32);
    self.loadLibraryButton = [[NSButton alloc] initWithFrame:loadLibraryRect];
    [self.loadLibraryButton setTitle:@"Load Library..."];
    [self.loadLibraryButton setButtonType:NSMomentaryPushInButton];
    [self.loadLibraryButton setBezelStyle:NSRoundedBezelStyle];
    [self.loadLibraryButton setTarget:self];
    [self.loadLibraryButton setAction:@selector(loadLibrary:)];
    [contentView addSubview:self.loadLibraryButton];
    
    [self updateDistortionLabels];
}

- (void)openImage:(id)sender {
    SSFileDialog *dialog = [SSFileDialog openDialog];
    [dialog setCanChooseFiles:YES];
    [dialog setCanChooseDirectories:NO];
    [dialog setAllowsMultipleSelection:NO];
    [dialog setAllowedFileTypes:[NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"tiff", @"tif", nil]];
    
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
    [dialog showWithCompletionHandler:^(SSFileDialogResult result, NSArray *urls) {
        if (result == SSFileDialogResultOK && urls.count > 0) {
            NSURL *fileURL = [urls objectAtIndex:0];
            [self loadImageFromURL:fileURL];
        }
    }];
#else
    NSArray *urls = [dialog showModal];
    if (urls && urls.count > 0) {
        NSURL *fileURL = [urls objectAtIndex:0];
        [self loadImageFromURL:fileURL];
    }
#endif
}

- (void)loadImageFromURL:(NSURL *)url {
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
        [self.textView setString:[NSString stringWithFormat:@"Image loaded: %@\n\nClick 'Decode' to scan for barcodes, or apply distortions to test decodability.", [url lastPathComponent]]];
    } else {
        // Show error in text view instead of popup
        [self.textView setString:[NSString stringWithFormat:@"Error: Could not load image from:\n%@\n\nPlease ensure the file exists and is a valid image format (JPEG, PNG, TIFF).", url]];
    }
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

- (void)populateSymbologyPopup {
    [self.symbologyPopup removeAllItems];
    
    if (![self.encoder hasBackend]) {
        [self.symbologyPopup addItemWithTitle:@"No encoder available"];
        [self.symbologyPopup setEnabled:NO];
        return;
    }
    
    NSArray *symbologies = [self.encoder supportedSymbologies];
    if (symbologies.count == 0) {
        [self.symbologyPopup addItemWithTitle:@"No symbologies available"];
        [self.symbologyPopup setEnabled:NO];
        return;
    }
    
    [self.symbologyPopup setEnabled:YES];
    NSInteger i;
    for (i = 0; i < symbologies.count; i++) {
        NSDictionary *symbology = [symbologies objectAtIndex:i];
        NSString *name = [symbology objectForKey:@"name"];
        if (name) {
            [self.symbologyPopup addItemWithTitle:name];
            // Store symbology ID in menu item's tag
            NSNumber *symbologyId = [symbology objectForKey:@"id"];
            if (symbologyId) {
                [[self.symbologyPopup itemAtIndex:i] setTag:[symbologyId intValue]];
            }
        }
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
    
    // Clear any previous distortions
    [self.distorter clearDistortions];
    [self.clearDistortionButton setEnabled:NO];
    
    NSMutableString *output = [NSMutableString string];
    [output appendString:@"Barcode Encoded Successfully\n"];
    [output appendString:@"===========================\n\n"];
    [output appendFormat:@"Data: %@\n", self.originalEncodedData];
    [output appendFormat:@"Type: %@\n", [[self.symbologyPopup selectedItem] title]];
    [output appendString:@"\n"];
    [output appendString:@"The barcode image is displayed on the left.\n"];
    [output appendString:@"You can:\n"];
    [output appendString:@"- Apply distortions to test decodability limits\n"];
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
    
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
    [dialog showWithCompletionHandler:^(SSFileDialogResult result, NSArray *urls) {
        if (result == SSFileDialogResultOK && urls.count > 0) {
            NSURL *fileURL = [urls objectAtIndex:0];
            [self saveImageToURL:fileURL];
        }
    }];
#else
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
        
        NSInteger distortionCount = [self.distorter distortions].count;
        [self.textView setString:[NSString stringWithFormat:@"Distortion applied. Total distortions: %ld\n\nYou can apply more distortions or decode the image.", (long)distortionCount]];
    }
}

- (void)loadLibrary:(id)sender {
    SSFileDialog *dialog = [SSFileDialog openDialog];
    [dialog setCanChooseFiles:YES];
    [dialog setCanChooseDirectories:NO];
    [dialog setAllowsMultipleSelection:NO];
    
    NSString *extension = [DynamicLibraryLoader libraryExtension];
    [dialog setAllowedFileTypes:[NSArray arrayWithObjects:extension, nil]];
    
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
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
    
    // Try to refresh backends (this would require backend system updates)
    // For now, just show success message
    NSMutableString *msg = [NSMutableString string];
    [msg appendString:@"Library Loaded Successfully\n"];
    [msg appendString:@"==========================\n\n"];
    [msg appendFormat:@"Path: %@\n", [url path]];
    [msg appendFormat:@"Total libraries loaded: %ld\n\n", (long)self.loadedLibraries.count];
    [msg appendString:@"Note: Backend system integration for dynamic loading is in progress.\n"];
    [msg appendString:@"Static backends are still available."];
    
    [self.textView setString:msg];
}

- (void)updateLibraryStatus {
    // Update UI to show loaded libraries
    // This could be enhanced to show library list in a separate view
    if (self.loadedLibraries.count > 0) {
        // Libraries are loaded
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    // Unload all libraries before closing
    NSInteger i;
    for (i = 0; i < self.loadedLibraries.count; i++) {
        DynamicLibrary *library = [self.loadedLibraries objectAtIndex:i];
        [DynamicLibraryLoader unloadLibrary:library];
    }
    [self.loadedLibraries removeAllObjects];
    
    [NSApp terminate:nil];
}

@end
