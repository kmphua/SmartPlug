//
//  SetTimerViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetTimerDelegate <NSObject>

- (void)modifyTimer:(int)alarmId serviceId:(int)serviceId;
- (void)snooze5Mins:(int)alarmId serviceId:(int)serviceId;
- (void)snooze10Mins:(int)alarmId serviceId:(int)serviceId;
- (void)snooze30Mins:(int)alarmId serviceId:(int)serviceId;
- (void)snooze1Hour:(int)alarmId serviceId:(int)serviceId;

@end

@interface SetTimerViewController : UIViewController

@property (nonatomic, assign) id<SetTimerDelegate> delegate;

@property (nonatomic, assign) NSString *devId;
@property (nonatomic, assign) int serviceId;
@property (nonatomic, assign) int alarmId;

@end
