//
//  ApplicationController.m
//
//  Created by Jim Correia on 3/4/11.
//  Copyright 2011 Jim Correia. All rights reserved.
//

#import "ApplicationController.h"
#import "ScrollingInverterEventTap.h"

static NSString *const ShowStatusItemKey = @"ShowStatusItem";

@interface ApplicationController ()

@property (nonatomic) BOOL wasLaunchedAtLogin;

@property (nonatomic) BOOL showsStatusItem;
- (void)setShowsStatusItem:(BOOL)showsStatusItem updateUserDefaults:(BOOL)updateUserDefaults;

- (BOOL)hasLoginItemWithPath:(NSString *)path;
- (void)addLoginItemWithPath:(NSString *)path;
- (void)removeLoginItemWithPath:(NSString *)path;
- (LSSharedFileListRef)loginItemsFileList;
- (LSSharedFileListItemRef)copyLoginItemWithPath:(NSString *)path;

- (BOOL)_wasLaunchedAtLogin;

@end

@implementation ApplicationController

+ (void)initialize;
{
    if (self != [ApplicationController class])
        return;

    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], ShowStatusItemKey,
        nil
    ];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (id)init;
{
    self = [super init];
    if (!self)
        return nil;

    _eventTap = [[ScrollingInverterEventTap alloc] init];
    _wasLaunchedAtLogin = [self _wasLaunchedAtLogin];

    return self;
}

- (void)dealloc;
{
    NSAssert(_eventTap == nil, @"Missing will terminate notification?");
    
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
    [_statusItem release];
    [_statusItemMenu release];
    
    if (_loginItemsFileList != NULL) {
        CFRelease(_loginItemsFileList);
    }

    [super dealloc];
    
}

- (void)awakeFromNib;
{
    NSAssert(!_statusItem, @"");
    NSAssert(_statusItemMenu, @"");
    
#if !DEBUG    
    // -toggleInvertScrollEvents: is really only useful in debug builds
    NSInteger invertScrollEventsMenuItemIndex = [_statusItemMenu indexOfItemWithTarget:self andAction:@selector(toggleInvertScrollEvents:)];
    [_statusItemMenu removeItemAtIndex:invertScrollEventsMenuItemIndex];
#endif

    [_statusItem setImage:[NSImage imageNamed:@"StatusMenuIcon"]];
    [_statusItem setAlternateImage:[NSImage imageNamed:@"StatusMenuIcon-Highlighted"]];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:_statusItemMenu];
}

@synthesize statusItemMenu = _statusItemMenu;

@synthesize wasLaunchedAtLogin = _wasLaunchedAtLogin;

- (BOOL)showsStatusItem;
{
    return _showsStatusItem;
}

- (void)setShowsStatusItem:(BOOL)showsStatusItem;
{
    [self setShowsStatusItem:showsStatusItem updateUserDefaults:YES];
}

- (void)setShowsStatusItem:(BOOL)showsStatusItem updateUserDefaults:(BOOL)updateUserDefaults;
{
    if (_showsStatusItem != showsStatusItem) {
        _showsStatusItem = showsStatusItem;
        if (_showsStatusItem) {
            NSAssert(!_statusItem, @"Expected _statusItem != nil");
            _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:32] retain];
            [_statusItem setImage:[NSImage imageNamed:@"StatusMenuIcon"]];
            [_statusItem setAlternateImage:[NSImage imageNamed:@"StatusMenuIcon-Highlighted"]];
            [_statusItem setHighlightMode:YES];
            [_statusItem setMenu:_statusItemMenu];
        } else {
            NSAssert(_statusItem, @"Expected _statusItem == nil");
            [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
            [_statusItem release];
            _statusItem = nil;
        }
    }
    
    if (updateUserDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:showsStatusItem forKey:ShowStatusItemKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
#if !DEBUG // Allow building+debugging on Lion
    SInt32 response = 0;
    OSStatus status = Gestalt(gestaltSystemVersion, &response);
    if (status == noErr && response >= 0x1070) {
        [_eventTap invalidate];
        [_eventTap release];
        _eventTap = nil;

        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

        NSAlert *alert = [NSAlert alertWithMessageText:@"10.6 Required" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Scrollvetica requires Mac OS X 10.6. It does not run on later releases.", nil];
        [alert runModal];
        [[NSApplication sharedApplication] terminate:nil];
    }
#endif
    
    BOOL shouldShowStatusItem = (self.wasLaunchedAtLogin ? [[NSUserDefaults standardUserDefaults] boolForKey:ShowStatusItemKey] : YES);
    [self setShowsStatusItem:shouldShowStatusItem updateUserDefaults:NO];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;
{
    if (!self.showsStatusItem) {
        // Review: Post alert stating that we are forcing the item to visible?
        [self setShowsStatusItem:YES updateUserDefaults:YES];
    }
    
    return NO;
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [_eventTap invalidate];
    [_eventTap release];
    _eventTap = nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
    if ([menuItem action] == @selector(toggleLaunchAutomaticallyAtLogIn:)) {
        BOOL isLoginItem = [self hasLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
        [menuItem setState:isLoginItem];
    }

    if ([menuItem action] == @selector(toggleShowsStatusItem:)) {
        NSInteger state = self.showsStatusItem;
        if (state == NSOffState && !self.wasLaunchedAtLogin) {
            state = NSMixedState;
        }
        [menuItem setState:state];
    }
    
    if ([menuItem action] == @selector(toggleInvertScrollEvents:)) {
        [menuItem setState:[_eventTap isEnabled]];
    }

    return YES;
}

- (IBAction)statusItemShowAboutBox:(id)sender;
{
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)toggleLaunchAutomaticallyAtLogIn:(id)sender;
{
    BOOL isLoginItem = [self hasLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
    if (isLoginItem) {
        [self removeLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
    } else {
        [self addLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
    }
}

- (IBAction)toggleInvertScrollEvents:(id)sender;
{
    BOOL enabled = ![_eventTap isEnabled];
    [_eventTap setEnabled:enabled];
}

- (IBAction)toggleShowsStatusItem:(id)sender;
{
    NSString *message = NSLocalizedString(@"Hide status item?", @"alert title");
    NSString *informativeText = NSLocalizedString(@"Choosing “Hide Status Item” will permanently hide the status item. Double-click Scrollvetica in the Finder to make the status item visible again.", @"alert body");
    NSString *defaultButton = NSLocalizedString(@"Hide Status Item", @"button title");
    NSString *cancelButton = NSLocalizedString(@"Cancel", @"button title");
    
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:defaultButton alternateButton:cancelButton otherButton:nil informativeTextWithFormat:@"%@", informativeText];
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    if ([alert runModal] == NSAlertDefaultReturn) {
        BOOL showsStatusItem = !self.showsStatusItem;
        [self setShowsStatusItem:showsStatusItem updateUserDefaults:YES];
    }
}

#pragma mark -
#pragma mark Private

- (BOOL)hasLoginItemWithPath:(NSString *)path;
{
    BOOL hasLoginItemWithPath = NO;
    LSSharedFileListItemRef itemRef = [self copyLoginItemWithPath: path];
    
    if (itemRef != NULL) {
        hasLoginItemWithPath = YES;
        CFRelease(itemRef);
    }
    
    return hasLoginItemWithPath;
}

- (void)addLoginItemWithPath:(NSString *)path;
{
    LSSharedFileListItemRef itemRef = [self copyLoginItemWithPath: path];
    if (itemRef == NULL) {
        NSURL *fileURL = [NSURL fileURLWithPath: path];
        itemRef = LSSharedFileListInsertItemURL([self loginItemsFileList], kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)fileURL, NULL, NULL);	
    }

    if (itemRef != NULL) {
        CFRelease(itemRef);
    }
}

- (void)removeLoginItemWithPath:(NSString *)path;
{
    LSSharedFileListItemRef itemRef = [self copyLoginItemWithPath: path];
    
    if (itemRef != NULL) {
        verify_noerr(LSSharedFileListItemRemove([self loginItemsFileList], itemRef));
        CFRelease(itemRef);
    }
}

- (LSSharedFileListRef)loginItemsFileList;
{
    if (!_loginItemsFileList) {
        _loginItemsFileList = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, NULL);
    }

    return _loginItemsFileList;
}

- (LSSharedFileListItemRef)copyLoginItemWithPath:(NSString *)path;
{
    LSSharedFileListItemRef foundItem = NULL;
    UInt32 seedValue = 0;
    NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot([self loginItemsFileList], &seedValue);

    for (id item in loginItemsArray) {      
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
        NSURL *itemURL = nil;
        OSStatus status = LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *)&itemURL, NULL);
        check_noerr(status);
        if (status == noErr && [path isEqualToString: [itemURL path]]) {
            foundItem = itemRef;
            CFRetain(foundItem);
            break;
        }
    }
    
    CFRelease((CFArrayRef)loginItemsArray);
    
    return foundItem;
}

- (BOOL)_wasLaunchedAtLogin;
{
    OSType processLauncher = 0;
    OSStatus status = noErr;
    ProcessSerialNumber psn;
    ProcessInfoRec processInfo;
    
    status = GetCurrentProcess(&psn);
    require_noerr(status, EXIT);

    memset(&processInfo, 0, sizeof(processInfo));
    processInfo.processInfoLength = sizeof(processInfo);		
    status = GetProcessInformation(&psn, &processInfo);
    require_noerr(status, EXIT);

    status = GetProcessInformation(&psn, &processInfo);
    require_noerr(status, EXIT);

    psn = processInfo.processLauncher;
    status = GetProcessInformation(&psn, &processInfo);
    require_noerr(status, EXIT);

    memset(&processInfo, 0, sizeof(processInfo));
    processInfo.processInfoLength = sizeof(processInfo);		
    status = GetProcessInformation(&psn, &processInfo);
    require_noerr(status, EXIT);

    processLauncher = processInfo.processSignature;

EXIT:
    return (processLauncher == 'lgnw');
}

@end
