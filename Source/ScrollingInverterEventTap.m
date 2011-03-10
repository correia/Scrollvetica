//
//  ScrollingInverterEventTap.m
//
//  Created by Jim Correia on 3/4/11.
//  Copyright 2011 Jim Correia. All rights reserved.
//

#import "ScrollingInverterEventTap.h"

@interface ScrollingInverterEventTap ()

static CGEventRef _eventTap(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo);

- (CGEventRef)_eventTapCallbackWithProxy:(CGEventTapProxy)proxy type:(CGEventType)type event:(CGEventRef)event;

@end

@implementation ScrollingInverterEventTap

- (id)init;
{
    self = [super init];
    if (!self)
        return nil;
        
    _enabled = YES;
    _eventTapMachPort = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, CGEventMaskBit(kCGEventScrollWheel), _eventTap, self);
    _eventTapRunLoopSource = CFMachPortCreateRunLoopSource(NULL, _eventTapMachPort, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _eventTapRunLoopSource, kCFRunLoopCommonModes);

    return self;
}

- (void)dealloc;
{
    [self invalidate];
    [super dealloc];
}

- (void)invalidate;
{
    if (_eventTapMachPort) {
        CFMachPortInvalidate(_eventTapMachPort);
        CFRelease(_eventTapMachPort);
        _eventTapMachPort = NULL;
    }

    if (_eventTapRunLoopSource) {
        CFRunLoopSourceInvalidate(_eventTapRunLoopSource);
        CFRelease(_eventTapRunLoopSource);
        _eventTapRunLoopSource = NULL;
    }
}

@synthesize enabled = _enabled;

#pragma mark -
#pragma mark Private

static CGEventRef _eventTap(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo)
{
    ScrollingInverterEventTap *tap = (ScrollingInverterEventTap *)userInfo;
    return [tap _eventTapCallbackWithProxy:proxy type:type event:event];
}

- (CGEventRef)_eventTapCallbackWithProxy:(CGEventTapProxy)proxy type:(CGEventType)type event:(CGEventRef)event;
{
    switch (type) {
        case kCGEventScrollWheel: {
            if ([self isEnabled]) {
                int64_t deltaAxis1 = CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1);;
                int64_t deltaAxis2 = CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2);;
                double fixedPtDeltaAxis1 = CGEventGetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis1);
                double fixedPtDeltaAxis2 = CGEventGetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis2);
                int64_t pointDeltaAxis1 = CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis1);
                int64_t pointDeltaAxis2 = CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis2);

                CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, -1 * deltaAxis1);
                CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2, -1 * deltaAxis2);

                CGEventSetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis1, -1 * fixedPtDeltaAxis1);
                CGEventSetDoubleValueField(event, kCGScrollWheelEventFixedPtDeltaAxis2, -1 * fixedPtDeltaAxis2);

                CGEventSetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis1, -1 * pointDeltaAxis1);
                CGEventSetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis2, -1 * pointDeltaAxis2);
            }        
            break;
        }
        
        case kCGEventTapDisabledByTimeout: {
#if DEBUG            
            NSLog(@"Got kCGEventTapDisabledByTimeout in %s; re-enabling.", __func__);
#endif            
            CGEventTapEnable(_eventTapMachPort, YES);
            break;
        }

        case kCGEventTapDisabledByUserInput: {
#if DEBUG            
            NSLog(@"Got kCGEventTapDisabledByUserInput in %s; re-enabling.", __func__);
#endif            
            CGEventTapEnable(_eventTapMachPort, YES);
            break;
        }
    }

    return event;
}

@end
