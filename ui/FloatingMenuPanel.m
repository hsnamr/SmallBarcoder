//
//  FloatingMenuPanel.m
//  SmallBarcodeReader
//
//  GNUstep-style floating menu panel implementation
//

#import "FloatingMenuPanel.h"
#import "WindowController.h"

@implementation FloatingMenuPanel

@synthesize mainMenu;
@synthesize fileMenu;
@synthesize encodeMenu;
@synthesize decodeMenu;
@synthesize distortionMenu;
@synthesize testingMenu;
@synthesize libraryMenu;
@synthesize windowController;

- (instancetype)initWithWindowController:(WindowController *)controller {
    // Create a floating utility panel
    NSRect panelRect = NSMakeRect(50, 50, 300, 400);
    // Use NSUtilityWindowMask for GNUstep compatibility, fallback to NSWindowStyleMaskUtilityWindow for newer APIs
    NSUInteger styleMask = NSTitledWindowMask | NSClosableWindowMask;
#if defined(NSUtilityWindowMask)
    styleMask |= NSUtilityWindowMask;
#elif defined(NSWindowStyleMaskUtilityWindow)
    styleMask |= NSWindowStyleMaskUtilityWindow;
#endif
    self = [super initWithContentRect:panelRect
                             styleMask:styleMask
                               backing:NSBackingStoreBuffered
                                 defer:NO];
    
    if (self) {
        windowController = controller; // Weak reference
        
        [self setTitle:@"Control Menu"];
        [self setFloatingPanel:YES];
        [self setLevel:NSFloatingWindowLevel];
        [self setHidesOnDeactivate:NO];
        [self setBecomesKeyOnlyIfNeeded:YES];
        
        // Create menu structure
        [self createMenus];
        
        // Create menu view
        [self setupMenuView];
    }
    
    return self;
}

- (void)createMenus {
    // Main menu bar
    mainMenu = [[NSMenu alloc] initWithTitle:@"Main"];
    
    // File Menu
    fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:@"Open Image..." action:@selector(openImage:) keyEquivalent:@"o"];
    [openItem setTarget:windowController];
    [fileMenu addItem:openItem];
    [openItem release];
    
    NSMenuItem *saveItem = [[NSMenuItem alloc] initWithTitle:@"Save Image..." action:@selector(saveImage:) keyEquivalent:@"s"];
    [saveItem setTarget:windowController];
    [fileMenu addItem:saveItem];
    [saveItem release];
    
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] initWithTitle:@"File" action:NULL keyEquivalent:@""];
    [fileMenuItem setSubmenu:fileMenu];
    [mainMenu addItem:fileMenuItem];
    [fileMenuItem release];
    
    // Decode Menu
    decodeMenu = [[NSMenu alloc] initWithTitle:@"Decode"];
    NSMenuItem *decodeItem = [[NSMenuItem alloc] initWithTitle:@"Decode Barcode" action:@selector(decodeImage:) keyEquivalent:@"d"];
    [decodeItem setTarget:windowController];
    [decodeMenu addItem:decodeItem];
    [decodeItem release];
    
    NSMenuItem *decodeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Decode" action:NULL keyEquivalent:@""];
    [decodeMenuItem setSubmenu:decodeMenu];
    [mainMenu addItem:decodeMenuItem];
    [decodeMenuItem release];
    
    // Encode Menu
    encodeMenu = [[NSMenu alloc] initWithTitle:@"Encode"];
    NSMenuItem *encodeItem = [[NSMenuItem alloc] initWithTitle:@"Encode Barcode" action:@selector(encodeBarcode:) keyEquivalent:@"e"];
    [encodeItem setTarget:windowController];
    [encodeMenu addItem:encodeItem];
    [encodeItem release];
    
    NSMenuItem *encodeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Encode" action:NULL keyEquivalent:@""];
    [encodeMenuItem setSubmenu:encodeMenu];
    [mainMenu addItem:encodeMenuItem];
    [encodeMenuItem release];
    
    // Distortion Menu
    distortionMenu = [[NSMenu alloc] initWithTitle:@"Distortion"];
    NSMenuItem *applyDistortionItem = [[NSMenuItem alloc] initWithTitle:@"Apply Distortion" action:@selector(applyDistortion:) keyEquivalent:@""];
    [applyDistortionItem setTarget:windowController];
    [distortionMenu addItem:applyDistortionItem];
    [applyDistortionItem release];
    
    NSMenuItem *previewDistortionItem = [[NSMenuItem alloc] initWithTitle:@"Preview Distortion" action:@selector(previewDistortion:) keyEquivalent:@""];
    [previewDistortionItem setTarget:windowController];
    [distortionMenu addItem:previewDistortionItem];
    [previewDistortionItem release];
    
    NSMenuItem *clearDistortionItem = [[NSMenuItem alloc] initWithTitle:@"Clear Distortion" action:@selector(clearDistortion:) keyEquivalent:@""];
    [clearDistortionItem setTarget:windowController];
    [distortionMenu addItem:clearDistortionItem];
    [clearDistortionItem release];
    
    NSMenuItem *distortionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Distortion" action:NULL keyEquivalent:@""];
    [distortionMenuItem setSubmenu:distortionMenu];
    [mainMenu addItem:distortionMenuItem];
    [distortionMenuItem release];
    
    // Testing Menu
    testingMenu = [[NSMenu alloc] initWithTitle:@"Testing"];
    NSMenuItem *testDecodabilityItem = [[NSMenuItem alloc] initWithTitle:@"Test Decodability" action:@selector(testDecodability:) keyEquivalent:@""];
    [testDecodabilityItem setTarget:windowController];
    [testingMenu addItem:testDecodabilityItem];
    [testDecodabilityItem release];
    
    NSMenuItem *runProgressiveTestItem = [[NSMenuItem alloc] initWithTitle:@"Run Progressive Test" action:@selector(runProgressiveTest:) keyEquivalent:@""];
    [runProgressiveTestItem setTarget:windowController];
    [testingMenu addItem:runProgressiveTestItem];
    [runProgressiveTestItem release];
    
    NSMenuItem *exportResultsItem = [[NSMenuItem alloc] initWithTitle:@"Export Test Results..." action:@selector(exportTestResults:) keyEquivalent:@""];
    [exportResultsItem setTarget:windowController];
    [testingMenu addItem:exportResultsItem];
    [exportResultsItem release];
    
    NSMenuItem *testingMenuItem = [[NSMenuItem alloc] initWithTitle:@"Testing" action:NULL keyEquivalent:@""];
    [testingMenuItem setSubmenu:testingMenu];
    [mainMenu addItem:testingMenuItem];
    [testingMenuItem release];
    
    // Library Menu (only on platforms that support dynamic loading)
#if !TARGET_OS_IPHONE && !TARGET_OS_WIN32
    libraryMenu = [[NSMenu alloc] initWithTitle:@"Library"];
    NSMenuItem *loadLibraryItem = [[NSMenuItem alloc] initWithTitle:@"Load Library..." action:@selector(loadLibrary:) keyEquivalent:@""];
    [loadLibraryItem setTarget:windowController];
    [libraryMenu addItem:loadLibraryItem];
    [loadLibraryItem release];
    
    NSMenuItem *libraryMenuItem = [[NSMenuItem alloc] initWithTitle:@"Library" action:NULL keyEquivalent:@""];
    [libraryMenuItem setSubmenu:libraryMenu];
    [mainMenu addItem:libraryMenuItem];
    [libraryMenuItem release];
#endif
}

- (void)setupMenuView {
    NSView *contentView = [self contentView];
    NSRect bounds = [contentView bounds];
    [contentView setAutoresizesSubviews:YES];
    
    // Create a scroll view for the menu items
    NSRect scrollRect = NSMakeRect(0, 0, bounds.size.width, bounds.size.height);
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:scrollRect];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:NSBezelBorder];
    [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    // Create container view for menu items
    NSRect containerRect = NSMakeRect(0, 0, bounds.size.width - 20, 0);
    NSView *containerView = [[NSView alloc] initWithFrame:containerRect];
    
    float currentY = 10;
    float buttonHeight = 28;
    float spacing = 5;
    float buttonWidth = bounds.size.width - 40;
    
    // File section
    NSTextField *fileLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, 20)];
    [fileLabel setStringValue:@"File"];
    [fileLabel setEditable:NO];
    [fileLabel setBordered:NO];
    [fileLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [fileLabel setFont:[NSFont boldSystemFontOfSize:12]];
    [containerView addSubview:fileLabel];
    [fileLabel release];
    currentY += 25;
    
    NSButton *openButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [openButton setTitle:@"Open Image..."];
    [openButton setButtonType:NSMomentaryPushInButton];
    [openButton setBezelStyle:NSRoundedBezelStyle];
    [openButton setTarget:windowController];
    [openButton setAction:@selector(openImage:)];
    [openButton setKeyEquivalent:@"o"];
    [openButton setKeyEquivalentModifierMask:NSCommandKeyMask];
    [containerView addSubview:openButton];
    [openButton release];
    currentY += (buttonHeight + spacing);
    
    NSButton *saveButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [saveButton setTitle:@"Save Image..."];
    [saveButton setButtonType:NSMomentaryPushInButton];
    [saveButton setBezelStyle:NSRoundedBezelStyle];
    [saveButton setTarget:windowController];
    [saveButton setAction:@selector(saveImage:)];
    [saveButton setKeyEquivalent:@"s"];
    [saveButton setKeyEquivalentModifierMask:NSCommandKeyMask];
    [containerView addSubview:saveButton];
    [saveButton release];
    currentY += (buttonHeight + spacing + 10);
    
    // Decode section
    NSTextField *decodeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, 20)];
    [decodeLabel setStringValue:@"Decode"];
    [decodeLabel setEditable:NO];
    [decodeLabel setBordered:NO];
    [decodeLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [decodeLabel setFont:[NSFont boldSystemFontOfSize:12]];
    [containerView addSubview:decodeLabel];
    [decodeLabel release];
    currentY += 25;
    
    NSButton *decodeButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [decodeButton setTitle:@"Decode Barcode"];
    [decodeButton setButtonType:NSMomentaryPushInButton];
    [decodeButton setBezelStyle:NSRoundedBezelStyle];
    [decodeButton setTarget:windowController];
    [decodeButton setAction:@selector(decodeImage:)];
    [decodeButton setKeyEquivalent:@"d"];
    [decodeButton setKeyEquivalentModifierMask:NSCommandKeyMask];
    [containerView addSubview:decodeButton];
    [decodeButton release];
    currentY += (buttonHeight + spacing + 10);
    
    // Encode section
    NSTextField *encodeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, 20)];
    [encodeLabel setStringValue:@"Encode"];
    [encodeLabel setEditable:NO];
    [encodeLabel setBordered:NO];
    [encodeLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [encodeLabel setFont:[NSFont boldSystemFontOfSize:12]];
    [containerView addSubview:encodeLabel];
    [encodeLabel release];
    currentY += 25;
    
    NSButton *encodeButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [encodeButton setTitle:@"Encode Barcode"];
    [encodeButton setButtonType:NSMomentaryPushInButton];
    [encodeButton setBezelStyle:NSRoundedBezelStyle];
    [encodeButton setTarget:windowController];
    [encodeButton setAction:@selector(encodeBarcode:)];
    [encodeButton setKeyEquivalent:@"e"];
    [encodeButton setKeyEquivalentModifierMask:NSCommandKeyMask];
    [containerView addSubview:encodeButton];
    [encodeButton release];
    currentY += (buttonHeight + spacing + 10);
    
    // Distortion section
    NSTextField *distortionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, 20)];
    [distortionLabel setStringValue:@"Distortion"];
    [distortionLabel setEditable:NO];
    [distortionLabel setBordered:NO];
    [distortionLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [distortionLabel setFont:[NSFont boldSystemFontOfSize:12]];
    [containerView addSubview:distortionLabel];
    [distortionLabel release];
    currentY += 25;
    
    NSButton *applyButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [applyButton setTitle:@"Apply Distortion"];
    [applyButton setButtonType:NSMomentaryPushInButton];
    [applyButton setBezelStyle:NSRoundedBezelStyle];
    [applyButton setTarget:windowController];
    [applyButton setAction:@selector(applyDistortion:)];
    [containerView addSubview:applyButton];
    [applyButton release];
    currentY += (buttonHeight + spacing);
    
    NSButton *previewButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [previewButton setTitle:@"Preview Distortion"];
    [previewButton setButtonType:NSMomentaryPushInButton];
    [previewButton setBezelStyle:NSRoundedBezelStyle];
    [previewButton setTarget:windowController];
    [previewButton setAction:@selector(previewDistortion:)];
    [containerView addSubview:previewButton];
    [previewButton release];
    currentY += (buttonHeight + spacing);
    
    NSButton *clearButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [clearButton setTitle:@"Clear Distortion"];
    [clearButton setButtonType:NSMomentaryPushInButton];
    [clearButton setBezelStyle:NSRoundedBezelStyle];
    [clearButton setTarget:windowController];
    [clearButton setAction:@selector(clearDistortion:)];
    [containerView addSubview:clearButton];
    [clearButton release];
    currentY += (buttonHeight + spacing + 10);
    
    // Testing section
    NSTextField *testingLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, 20)];
    [testingLabel setStringValue:@"Testing"];
    [testingLabel setEditable:NO];
    [testingLabel setBordered:NO];
    [testingLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [testingLabel setFont:[NSFont boldSystemFontOfSize:12]];
    [containerView addSubview:testingLabel];
    [testingLabel release];
    currentY += 25;
    
    NSButton *testButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [testButton setTitle:@"Test Decodability"];
    [testButton setButtonType:NSMomentaryPushInButton];
    [testButton setBezelStyle:NSRoundedBezelStyle];
    [testButton setTarget:windowController];
    [testButton setAction:@selector(testDecodability:)];
    [containerView addSubview:testButton];
    [testButton release];
    currentY += (buttonHeight + spacing);
    
    NSButton *progressiveButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [progressiveButton setTitle:@"Run Progressive Test"];
    [progressiveButton setButtonType:NSMomentaryPushInButton];
    [progressiveButton setBezelStyle:NSRoundedBezelStyle];
    [progressiveButton setTarget:windowController];
    [progressiveButton setAction:@selector(runProgressiveTest:)];
    [containerView addSubview:progressiveButton];
    [progressiveButton release];
    currentY += (buttonHeight + spacing);
    
    NSButton *exportButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [exportButton setTitle:@"Export Test Results..."];
    [exportButton setButtonType:NSMomentaryPushInButton];
    [exportButton setBezelStyle:NSRoundedBezelStyle];
    [exportButton setTarget:windowController];
    [exportButton setAction:@selector(exportTestResults:)];
    [containerView addSubview:exportButton];
    [exportButton release];
    currentY += (buttonHeight + spacing + 10);
    
    // Library section (only on platforms that support dynamic loading)
#if !TARGET_OS_IPHONE && !TARGET_OS_WIN32
    NSTextField *libraryLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, 20)];
    [libraryLabel setStringValue:@"Library"];
    [libraryLabel setEditable:NO];
    [libraryLabel setBordered:NO];
    [libraryLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [libraryLabel setFont:[NSFont boldSystemFontOfSize:12]];
    [containerView addSubview:libraryLabel];
    [libraryLabel release];
    currentY += 25;
    
    NSButton *loadLibraryButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, currentY, buttonWidth, buttonHeight)];
    [loadLibraryButton setTitle:@"Load Library..."];
    [loadLibraryButton setButtonType:NSMomentaryPushInButton];
    [loadLibraryButton setBezelStyle:NSRoundedBezelStyle];
    [loadLibraryButton setTarget:windowController];
    [loadLibraryButton setAction:@selector(loadLibrary:)];
    [containerView addSubview:loadLibraryButton];
    [loadLibraryButton release];
    currentY += (buttonHeight + spacing + 10);
#endif
    
    // Update container view height
    [containerView setFrame:NSMakeRect(0, 0, bounds.size.width - 20, currentY)];
    
    [scrollView setDocumentView:containerView];
    [containerView release];
    
    [contentView addSubview:scrollView];
    [scrollView release];
}

- (void)updateMenuStates {
    // Update menu item states based on window controller state
    if (!windowController) {
        return;
    }
    
    // Update file menu
    NSMenuItem *saveItem = [[fileMenu itemArray] objectAtIndex:1];
    if (saveItem) {
        [saveItem setEnabled:[windowController.saveButton isEnabled]];
    }
    
    // Update decode menu
    NSMenuItem *decodeItem = [[decodeMenu itemArray] objectAtIndex:0];
    if (decodeItem) {
        [decodeItem setEnabled:[windowController.decodeButton isEnabled]];
    }
    
    // Update encode menu
    NSMenuItem *encodeItem = [[encodeMenu itemArray] objectAtIndex:0];
    if (encodeItem) {
        [encodeItem setEnabled:[windowController.encodeButton isEnabled]];
    }
    
    // Update distortion menu
    NSMenuItem *applyItem = [[distortionMenu itemArray] objectAtIndex:0];
    if (applyItem) {
        [applyItem setEnabled:[windowController.applyDistortionButton isEnabled]];
    }
    
    NSMenuItem *previewItem = [[distortionMenu itemArray] objectAtIndex:1];
    if (previewItem) {
        [previewItem setEnabled:[windowController.previewDistortionButton isEnabled]];
    }
    
    NSMenuItem *clearItem = [[distortionMenu itemArray] objectAtIndex:2];
    if (clearItem) {
        [clearItem setEnabled:[windowController.clearDistortionButton isEnabled]];
    }
    
    // Update testing menu
    NSMenuItem *testItem = [[testingMenu itemArray] objectAtIndex:0];
    if (testItem) {
        [testItem setEnabled:[windowController.testDecodabilityButton isEnabled]];
    }
    
    NSMenuItem *progressiveItem = [[testingMenu itemArray] objectAtIndex:1];
    if (progressiveItem) {
        [progressiveItem setEnabled:[windowController.runProgressiveTestButton isEnabled]];
    }
    
    NSMenuItem *exportItem = [[testingMenu itemArray] objectAtIndex:2];
    if (exportItem) {
        [exportItem setEnabled:[windowController.exportTestResultsButton isEnabled]];
    }
}

- (void)showPanel {
    [self orderFront:nil];
    [self updateMenuStates];
}

- (void)hidePanel {
    [self orderOut:nil];
}

- (void)togglePanel {
    if ([self isVisible]) {
        [self hidePanel];
    } else {
        [self showPanel];
    }
}

- (void)dealloc {
    [mainMenu release];
    [fileMenu release];
    [encodeMenu release];
    [decodeMenu release];
    [distortionMenu release];
    [testingMenu release];
    [libraryMenu release];
    [super dealloc];
}

@end
