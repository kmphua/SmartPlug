//
//  SetTimerViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetTimerDelegate <NSObject>

- (void)modifyTimer;
- (void)snooze5Mins;
- (void)snooze10Mins;
- (void)snooze30Mins;
- (void)snooze1Hour;

@end

@interface SetTimerViewController : UIViewController

@property (nonatomic, assign) id<SetTimerDelegate> delegate;

@end
