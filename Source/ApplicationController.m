//
//  ApplicationController.m
//
//  Created by Jim Correia on 3/4/11.
//  Copyright 2011 Jim Correia. All rights reserved.
//

#import "ApplicationController.h"
#import "ScrollingInverterEventTap.h"

static NSString *const kScrollveticaShowStatusItemKey = @"ScrollveticaShowStatusItemKey";

@interface ApplicationController ()

- (BOOL)hasLoginItemWithPath:(NSString *)path;
- (void)addLoginItemWithPath:(NSString *)path;
- (void)removeLoginItemWithPath:(NSString *)path;
- (LSSharedFileListRef)loginItemsFileList;
- (LSSharedFileListItemRef)copyLoginItemWithPath:(NSString *)path;

@end

@implementation ApplicationController

- (id)init;
{
    self = [super init];
    if (!self)
        return nil;

    _eventTap = [[ScrollingInverterEventTap alloc] init];
    [[NSUserDefaults standardUserDefaults] registerDefaults:
        [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kScrollveticaShowStatusItemKey]
     ];
    
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

@synthesize statusItemMenu = _statusItemMenu;
@synthesize showStatusItem;

- (void)awakeFromNib;
{
    NSAssert(!_statusItem, @"");
    NSAssert(_statusItemMenu, @"");
    
    BOOL shouldShowStatusItem = [[NSUserDefaults standardUserDefaults] boolForKey:kScrollveticaShowStatusItemKey];
    self.showStatusItem = shouldShowStatusItem;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
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

- (void)setShowStatusItem:(BOOL)shouldShow
{
    if (showStatusItem != shouldShow) {
        showStatusItem = shouldShow;
        [[NSUserDefaults standardUserDefaults] setBool:shouldShow forKey:kScrollveticaShowStatusItemKey];
        if (shouldShow) {
            _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:32] retain];
            [_statusItem setImage:[NSImage imageNamed:@"StatusMenuIcon"]];
            [_statusItem setAlternateImage:[NSImage imageNamed:@"StatusMenuIcon-Highlighted"]];
            [_statusItem setHighlightMode:YES];
            [_statusItem setMenu:_statusItemMenu];
        }
        else {
            [_statusItem release];
            _statusItem = nil;
        }
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    self.showStatusItem = YES;
    return YES;
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

@end
