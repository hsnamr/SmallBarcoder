//
//  WindowController.m
//  SmallBarcodeReader
//
//  Main window controller implementation
//

#import "WindowController.h"
#import "BarcodeDecoder.h"
#import "../SmallStep/SmallStep/Core/SmallStep.h"

@interface WindowController () <NSWindowDelegate> {
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

@implementation WindowController

@synthesize imageView;
@synthesize textView;
@synthesize textScrollView;
@synthesize openButton;
@synthesize decodeButton;
@synthesize decoder;
@synthesize currentImage;

- (instancetype)init {
    self = [super init];
    if (self) {
        decoder = [[BarcodeDecoder alloc] init];
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
    [decoder release];
    [currentImage release];
    [super dealloc];
}

- (void)setupWindow {
    // Create window using SmallStep abstraction
    NSRect windowRect = NSMakeRect(100, 100, 800, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowRect
                                                    styleMask:[SSWindowStyle standardWindowMask]
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [window setTitle:@"Small Barcode Reader"];
    [window setDelegate:self];
    [self setWindow:window];
    
    NSView *contentView = [window contentView];
    
    // Create image view
    NSRect imageViewRect = NSMakeRect(20, 300, 360, 260);
    self.imageView = [[NSImageView alloc] initWithFrame:imageViewRect];
    [self.imageView setImageAlignment:NSImageAlignCenter];
    [self.imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self.imageView setImageFrameStyle:NSImageFrameGrayBezel];
    [contentView addSubview:self.imageView];
    
    // Create text view with scroll view
    NSRect textScrollRect = NSMakeRect(400, 50, 380, 510);
    self.textScrollView = [[NSScrollView alloc] initWithFrame:textScrollRect];
    [self.textScrollView setHasVerticalScroller:YES];
    [self.textScrollView setHasHorizontalScroller:YES];
    [self.textScrollView setAutohidesScrollers:YES];
    [self.textScrollView setBorderType:NSBezelBorder];
    
    NSRect textViewRect = [self.textScrollView contentSize];
    self.textView = [[NSTextView alloc] initWithFrame:textViewRect];
    [self.textView setEditable:NO];
    [self.textView setFont:[NSFont systemFontOfSize:12]];
    [self.textView setString:@"No image loaded.\n\nClick 'Open Image' to load a JPEG or PNG image containing barcodes."];
    
    [self.textScrollView setDocumentView:self.textView];
    [contentView addSubview:self.textScrollView];
    
    // Create open button
    NSRect buttonRect = NSMakeRect(20, 250, 120, 32);
    self.openButton = [[NSButton alloc] initWithFrame:buttonRect];
    [self.openButton setTitle:@"Open Image..."];
    [self.openButton setButtonType:NSButtonTypeMomentaryPushIn];
    [self.openButton setBezelStyle:NSBezelStyleRounded];
    [self.openButton setTarget:self];
    [self.openButton setAction:@selector(openImage:)];
    [contentView addSubview:self.openButton];
    
    // Create decode button
    NSRect decodeButtonRect = NSMakeRect(150, 250, 120, 32);
    self.decodeButton = [[NSButton alloc] initWithFrame:decodeButtonRect];
    [self.decodeButton setTitle:@"Decode"];
    [self.decodeButton setButtonType:NSButtonTypeMomentaryPushIn];
    [self.decodeButton setBezelStyle:NSBezelStyleRounded];
    [self.decodeButton setTarget:self];
    [self.decodeButton setAction:@selector(decodeImage:)];
    [self.decodeButton setEnabled:NO];
    [contentView addSubview:self.decodeButton];
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
        [self.imageView setImage:image];
        [self.decodeButton setEnabled:YES];
        [self.textView setString:[NSString stringWithFormat:@"Image loaded: %@\n\nClick 'Decode' to scan for barcodes.", [url lastPathComponent]]];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Error Loading Image"];
        [alert setInformativeText:[NSString stringWithFormat:@"Could not load image from: %@", url]];
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert runModal];
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
    NSArray *results = [self.decoder decodeBarcodesFromImage:self.currentImage];
    
    [SSConcurrency performSelectorOnMainThread:@selector(updateResults:) onTarget:self withObject:results waitUntilDone:YES];
    [pool release];
}

- (void)updateResults:(NSArray *)results {
    if (results && results.count > 0) {
        NSMutableString *output = [NSMutableString string];
        [output appendString:@"Barcode Decoding Results:\n"];
        [output appendString:@"========================\n\n"];
        
        for (NSInteger i = 0; i < results.count; i++) {
            BarcodeResult *result = [results objectAtIndex:i];
            [output appendFormat:@"Barcode #%ld:\n", (long)(i + 1)];
            [output appendFormat:@"  Type: %@\n", result.type];
            [output appendFormat:@"  Data: %@\n", result.data];
            [output appendFormat:@"  Location Points: %lu\n", (unsigned long)result.points.count];
            [output appendString:@"\n"];
        }
        
        [self.textView setString:output];
    } else {
        [self.textView setString:@"No barcodes found in the image.\n\nPlease try:\n- Ensuring the image is clear and in focus\n- Using a higher resolution image\n- Checking that the barcode is not damaged or obscured"];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp terminate:nil];
}

@end
