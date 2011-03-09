//
//  ScrollingInverterEventTap.h
//
//  Created by Jim Correia on 3/4/11.
//  Copyright 2011 Jim Correia. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ScrollingInverterEventTap : NSObject {
  @private
    BOOL _enabled;
    CFMachPortRef _eventTapMachPort;
    CFRunLoopSourceRef _eventTapRunLoopSource;
}

- (id)init;

- (void)invalidate;

@property (nonatomic, getter=isEnabled) BOOL enabled;

@end
