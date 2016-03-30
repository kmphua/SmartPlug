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

- (BOOL)insertIcons:(NSString *)url size:(int)size sid:(NSString *)sid;
- (NSArray *)getIcons;
- (NSArray *)getIconByUrl:(NSString *)url;

// IR Groups
- (NSArray *)getIRGroups;
- (NSArray *)getIRGroup:(int)groupId;
- (BOOL)insertIRGroup:(NSString *)name icon:(NSString *)icon position:(int)position;
- (BOOL)updateIRGroup:(IrGroup *)group;

// IR Codes
- (NSArray *)getIRCodes;
- (NSArray *)getIRCodesByGroup:(int)groupid;
- (BOOL)insertIRCodes:(int)groupId name:(NSString *)name filename:(int)filename
                 icon:(NSString *)icon mac:(NSString *)mac;
- (BOOL)updateIRCode:(IrCode *)code;
- (BOOL)deleteIRCodes:(int)groupId;
- (BOOL)deleteIRGroupById:(int)groupId;
- (BOOL)deleteIRCode:(int)groupId;

// Plugs
- (BOOL)insertPlug:(NSString *)name sid:(NSString *)sid ip:(NSString *)ip;
- (BOOL)insertPlug:(JSmartPlug *)js active:(int)active;
- (BOOL)updatePlugID:(NSString *)mac ip:(NSString *)ip;
- (BOOL)updatePlugName:(NSString *)data sid:(NSString *)sid;
- (BOOL)updatePlugIcon:(NSString *)sid icon:(NSString *)icon;
- (BOOL)updatePlugNightlightService:(int)data sid:(NSString *)sid;
- (BOOL)updatePlugCoSensorService:(int)data sid:(NSString *)sid;
- (BOOL)updatePlugHallSensorService:(int)data sid:(NSString *)sid;
- (BOOL)updateSnooze:(int)data sid:(NSString *)sid;
- (BOOL)updatePlugRelayService:(int)data sid:(NSString *)sid;
- (BOOL)updatePlugServices:(JSmartPlug *)js;
- (BOOL)updatePlugIP:(NSString *)name ip:(NSString *)ip;
- (BOOL)updatePlugRelay:(NSString *)id relay:(int)relay;
- (BOOL)updatePlugNightlight:(NSString *)id nl:(int)nl;
- (BOOL)activatePlug:(NSString *)sid;
- (BOOL)insertToken:(NSString *)token;
- (NSArray *)getToken;
- (BOOL)removePlugsIP;
- (BOOL)removePlugIP:(NSString *)serviceName;
- (NSArray *)getPlugData:(NSString *)ip;
- (NSArray *)getPlugDataByID:(NSString *)id;
- (NSArray *)getPlugDataByName:(NSString *)name;
- (NSArray *)getPlugData;
- (NSArray *)getNonActivePlugData;
- (BOOL)deletePlugData:(NSString *)ip;
- (BOOL)deletePlugDataByID:(NSString *)mac;
- (BOOL)updatePlugNameNotify:(NSString *)mac name:(NSString *)name notifyOnPowerOutage:(int)notifyOnPowerOutage notifyOnCoWarning:(int)notifyOnCoWarning notifyOnTimerActivated:(int)notifyOnTimerActivated icon:(NSString *)icon;
- (BOOL)deletePlugs;
- (BOOL)deleteNonActivePlug:(NSString *)name;

// Alarms
- (BOOL)deleteAlarmData:(int)id;
- (BOOL)removeAlarms:(NSString *)mac;
- (BOOL)insertAlarm:(Alarm *)a;
- (BOOL)updateAlarm:(Alarm *)a;
- (NSArray *)getAlarmDataById:(int)alarmId;
- (NSArray *)getAlarmDataByDevice:(NSString *)deviceId;
- (NSArray *)getAlarmDataByDeviceAndService:(NSString *)deviceId serviceId:(int)serviceId;

@end
