//
//  ScheduleActionViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"

@interface ScheduleActionViewController : BaseViewController

@property (nonatomic, assign) NSString *deviceId;
@property (nonatomic) int serviceId;
@property (nonatomic) int alarmId;
@property (nonatomic, assign) NSString *deviceName;

@end
