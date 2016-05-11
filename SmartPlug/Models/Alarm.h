//
//  Alarm.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Alarm : NSObject

@property (nonatomic, assign) int alarm_id;
@property (nonatomic, copy) NSString *device_id;
@property (nonatomic, assign) int service_id;
@property (nonatomic, assign) int dow;
@property (nonatomic, assign) int initial_hour;
@property (nonatomic, assign) int initial_minute;
@property (nonatomic, assign) int end_hour;
@property (nonatomic, assign) int end_minute;
@property (nonatomic, assign) int snooze;
@property (nonatomic, assign) int init_ir;
@property (nonatomic, assign) int end_ir;

@end
