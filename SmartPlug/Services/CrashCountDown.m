//
//  CrashCountDown.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/16/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "CrashCountDown.h"

#define CRASH_TIMER_INTERVAL       2

@interface CrashCountDown()

@property (nonatomic, assign) int interval;
@property (nonatomic, strong) NSTimer *crashTimer;

@end

@implementation CrashCountDown

static CrashCountDown *instance;

+ (CrashCountDown *)getInstance
{
    @synchronized(self) {
        if (instance == nil)
            instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)startTimer
{
    _crashTimer = [NSTimer scheduledTimerWithTimeInterval:CRASH_TIMER_INTERVAL
                                                   target:self
                                                 selector:@selector(timerExpired:)
                                                 userInfo:nil
                                                  repeats:NO];
}

- (void)stopTimer
{
    if (_crashTimer) {
        [_crashTimer invalidate];
        _crashTimer = nil;
    }
}

- (void)timerExpired:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TIMER_CRASH_REACHED object:nil];
}

@end
