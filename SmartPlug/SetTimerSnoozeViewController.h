//
//  SetTimerSnoozeViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetSnoozeTimerDelegate <NSObject>

- (void)modifySnoozeTimer;
- (void)snooze5MoreMins;
- (void)snooze10MoreMins;
- (void)snooze30MoreMins;
- (void)snooze1MoreHour;
- (void)cancelSnooze;

@end

@interface SetTimerSnoozeViewController : UIViewController

@property (nonatomic, assign) id<SetSnoozeTimerDelegate> delegate;

@end
