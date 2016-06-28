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

// Snooze
- (BOOL)updateDeviceSnooze:(NSString *)sid serviceId:(int)serviceId snooze:(int)snooze;
- (int)getRelaySnooze:(NSString *)sid;
- (int)getLedSnooze:(NSString *)sid;
- (int)getIRSnooze:(NSString *)sid;

// Icons
- (BOOL)insertIcons:(NSString *)url size:(int)size sid:(NSString *)sid;
- (NSArray *)getIcons;
- (NSArray *)getIconByUrl:(NSString *)url;

// IR Groups
- (NSArray *)getIRGroups: (NSString *)devId;
- (BOOL)deleteIRGroups: (NSString *)devId;
- (NSArray *)getIRGroup:(int)groupId devId:(NSString *)devId;
- (IrGroup *)getIRGroupBySID:(int)sid devId:(NSString *)devId;
- (NSArray *)getIRGroupByMac:(NSString *)mac;
- (NSArray *)getIRGroupByName:(NSString *)groupName devId:(NSString *)devId ;
- (BOOL)deleteIRGroupById:(int)groupId devId:(NSString *)devId;
- (BOOL)deleteIRGroupBySID:(int)sid devId:(NSString *)devId;
- (BOOL)insertIRGroup:(NSString *)name devId:(NSString *)devId icon:(NSString *)icon position:(int)position sid:(int)sid;
- (BOOL)updateIRGroup:(IrGroup *)group devId:(NSString *)devId;

// IR Codes
- (NSArray *)getIRCodes:(NSString *)devId;
- (NSArray *)getIRCodesByGroup:(int)groupid devId:(NSString *)devId;
- (NSArray *)getIRCodeById:(int)filename devId:(NSString *)devId;
- (BOOL)insertIRCodes:(int)groupId name:(NSString *)name filename:(int)filename
                 icon:(NSString *)icon mac:(NSString *)mac sid:(int)sid;
- (BOOL)updateIRCodeSID:(int)filename sid:(int)sid devId:(NSString *)devId;
- (BOOL)updateIRGroupID:(int)groupId sid:(int)sid devId:(NSString *)devId;
- (BOOL)updateIRCode:(IrCode *)code devId:(NSString *)devId ;
- (BOOL)deleteIRCodes:(int)groupId devId:(NSString *)devId ;
- (BOOL)deleteIRCodesBySID:(int)groupId devId:(NSString *)devId ;

- (BOOL)deleteIRCode:(int)sid devId:(NSString *)devId ;
- (BOOL)deleteAllIRCodes: (NSString *)devId;

// Plugs
- (BOOL)insertPlug:(JSmartPlug *)js active:(int)active;
- (BOOL)updateDeviceVersions:(NSString *)idLocal model:(NSString *)model build_no:(int)build_no
                    prot_ver:(int)prot_ver hw_ver:(NSString *)hw_ver fw_ver:(NSString *)fw_ver fw_date:(int)fw_date;
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
- (BOOL)deActivatePlug:(NSString *)sid;
- (BOOL)insertToken:(NSString *)token;
- (NSArray *)getToken;
- (NSArray *)getPlugData:(NSString *)ip;
- (NSArray *)getPlugDataByID:(NSString *)id;
- (NSArray *)getPlugDataByName:(NSString *)name;
- (NSArray *)getPlugData;
- (NSArray *)getNonActivePlugData;
- (BOOL)deletePlugData:(NSString *)sid;
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

- (NSString *)getPlugMacFromIP:(NSString *)ip;
- (NSString *)getPlugIP:(NSString *)mac;

@end
