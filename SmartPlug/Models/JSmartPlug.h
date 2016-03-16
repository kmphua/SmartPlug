//
//  JSmartPlug.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSmartPlug : NSObject

@property (nonatomic, assign) int dbid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy) NSString *sid;
@property (nonatomic, copy) NSString *ip;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, assign) int buildno;
@property (nonatomic, assign) int prot_ver;
@property (nonatomic, copy) NSString *hw_ver;
@property (nonatomic, copy) NSString *fw_ver;
@property (nonatomic, assign) int fw_date;
@property (nonatomic, assign) int flag;
@property (nonatomic, assign) int relay;
@property (nonatomic, assign) int hall_sensor;
@property (nonatomic, assign) int nightlight;
@property (nonatomic, assign) int co_sensor;
@property (nonatomic, copy) NSString *givenName;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, assign) int active;
@property (nonatomic, assign) int notify_power;
@property (nonatomic, assign) int notify_co;
@property (nonatomic, assign) int notify_timer;
@property (nonatomic, assign) int snooze;

@end