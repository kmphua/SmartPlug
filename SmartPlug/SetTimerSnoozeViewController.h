//
//  SetTimerSnoozeViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetSnoozeTimerDelegate <NSObject>

- (void)modifySnoozeTimer:(int)alarmId serviceId:(int)serviceId;
- (void)snooze5MoreMins:(int)alarmId serviceId:(int)serviceId;
- (void)snooze10MoreMins:(int)alarmId serviceId:(int)serviceId;
- (void)snooze30MoreMins:(int)alarmId serviceId:(int)serviceId;
- (void)snooze1MoreHour:(int)alarmId serviceId:(int)serviceId;
- (void)cancelSnooze:(int)alarmId serviceId:(int)serviceId;

@end

@interface SetTimerSnoozeViewController : UIViewController

@property (nonatomic, assign) id<SetSnoozeTimerDelegate> delegate;

@property (nonatomic, assign) NSString *devId;
@property (nonatomic, assign) int serviceId;
@property (nonatomic, assign) int alarmId;

@end
