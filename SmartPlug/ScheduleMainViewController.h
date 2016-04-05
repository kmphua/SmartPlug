//
//  ScheduleMainViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"

@interface ScheduleMainViewController : BaseViewController

@property (nonatomic, assign) NSString *devId;
@property (nonatomic, assign) NSString *devName;
@property (nonatomic, assign) int serviceId;
@property (nonatomic, assign) int alarmId;

@end
