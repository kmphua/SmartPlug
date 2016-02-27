//
//  SQLHelper.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "JSmartPlug.h"
#import "Alarm.h"
#import "AlarmList.h"
#import "Icon.h"
#import "IrCode.h"
#import "IrGroup.h"

@interface SQLHelper : NSObject

+ (SQLHelper *)getInstance;

- (BOOL)insertIcons:(NSString *)url size:(int)size;
- (NSArray *)getIcons;
- (BOOL)insertIRGroup:(NSString *)desc icon:(NSString *)icon position:(int)position;
- (NSArray *)getIRGroups;
- (BOOL)deleteIRGroup:(int)id;
- (BOOL)deleteIRCodes:(int)groupid;
- (BOOL)deleteIRCode:(int)id;
- (NSArray *)getIRGroups:(int)id;
- (BOOL)insertIRCodes:(int)gid name:(NSString *)name filename:(int)filename
                 icon:(NSString *)icon mac:(NSString *)mac;
- (NSArray *)getIRCodes;
- (NSArray *)getIRCodesByGroup:(int)id;
- (BOOL)insertPlug:(NSString *)name sid:(NSString *)sid ip:(NSString *)ip;
- (BOOL)insertPlug:(JSmartPlug *)js active:(int)active;
- (BOOL)updatePlugID:(NSString *)mac ip:(NSString *)ip;
- (BOOL)updatePlugName:(NSString *)data id:(NSString *)id;
- (BOOL)updatePlugNightlightService:(int)data id:(NSString *)id;
- (BOOL)updatePlugCoSensorService:(int)data id:(NSString *)id;
- (BOOL)updatePlugHallSensorService:(int)data id:(NSString *)id;
- (BOOL)updatePlugRelayService:(int)data id:(NSString *)id;
- (BOOL)updatePlugServicesByIP:(JSmartPlug *)js;
- (BOOL)updatePlugServicesByID:(JSmartPlug *)js;
- (BOOL)updatePlugIP:(NSString *)name ip:(NSString *)ip;
- (BOOL)updatePlugRelay:(NSString *)id relay:(int)relay;
- (BOOL)updatePlugNightlight:(NSString *)id nl:(int)nl;
- (BOOL)activatePlug:(NSString *)sid;
- (BOOL)insertToken:(NSString *)token;
- (NSArray *)getToken;
- (BOOL)removePlugsIP;
- (BOOL)removePlugIP:(NSString *)serviceName;
- (BOOL)updatePlugIP:(NSString *)name ip:(NSString *)ip;
- (NSArray *)getPlugData:(NSString *)ip;
- (NSArray *)getPlugDataByID:(NSString *)id;
- (NSArray *)getPlugDataByName:(NSString *)name;
- (NSArray *)getPlugData;
- (NSArray *)getNonActivePlugData;
- (BOOL)deletePlugData:(NSString *)ip;
- (BOOL)deletePlugDataByID:(NSString *)mac;
- (BOOL)updatePlugNameNotify:(NSString *)mac name:(NSString *)name notifyOnPowerOutage:(int)notifyOnPowerOutage notifyOnCoWarning:(int)notifyOnCoWarning notifyOnTimerActivated:(int)notifyOnTimerActivated icon:(NSString *)icon;
- (BOOL)deleteNonActivePlug:(NSString *)name;
- (BOOL)deleteAlarmData:(int)id;
- (BOOL)insertAlarm:(Alarm *)a;
- (BOOL)updateAlarm:(Alarm *)a;
- (NSArray *)getAlarmData:(int)alarmId;
- (NSArray *)getAlarmDataByDevice:(NSString *)deviceId;
- (NSArray *)getAlarmDataByDeviceAndService:(NSString *)deviceId serviceId:(int)serviceId;

@end
