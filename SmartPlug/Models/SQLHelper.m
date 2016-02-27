//
//  SQLHelper.m
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "SQLHelper.h"
#import "FMDB.h"

// plugs information table
#define TABLE_SMARTPLUGS        @"smartplugs"
#define COLUMN_ID               @"_id"
#define COLUMN_NAME             @"name"
#define COLUMN_GIVEN_NAME       @"given_name"
#define COLUMN_SID              @"sid"
#define COLUMN_IP               @"ip"
#define COLUMN_SERVER           @"server"
#define COLUMN_SNOOZE           @"snooze"
#define COLUMN_MODEL            @"model"
#define COLUMN_BUILD_NO         @"build_no"
#define COLUMN_PROT_VER         @"prot_ver"
#define COLUMN_HW_VER           @"hw_ver"
#define COLUMN_FW_VER           @"fw_ver"
#define COLUMN_FW_DATE          @"fw_date"
#define COLUMN_FLAG             @"flag"
#define COLUMN_RELAY            @"relay"                    // On/Off
#define COLUMN_HSENSOR          @"hsensor"                  // 1 overcurrent, 2 normal
#define COLUMN_CSENSOR          @"csensor"                  // 1 smoke detected, 2 normal, 3 unplugged
#define COLUMN_NIGHTLIGHT       @"nightlight"               // On/Off
#define COLUMN_ACTIVE           @"active"
#define COLUMN_NOTIFY_POWER     @"notify_power"
#define COLUMN_NOTIFY_CO        @"notify_co"
#define COLUMN_NOTIFY_TIMER     @"notify_timer"

// alarm table
#define TABLE_ALARMS            @"alarms"
#define COLUMN_DEVICE_ID        @"device_id"
#define COLUMN_SERVICE_ID       @"service_id"               // 1 = relay, 2 nightled
#define COLUMN_DOW              @"dow"
#define COLUMN_INIT_HOUR        @"init_hour"
#define COLUMN_INIT_MINUTES     @"init_minute"
#define COLUMN_END_HOUR         @"end_hour"
#define COLUMN_END_MINUTES      @"end_minute"

// IR CODES
#define TABLE_IRCODES           @"ircodes"
#define COLUMN_GROUPID          @"group_id"
#define COLUMN_FILENAME         @"filename"
#define COLUMN_MAC              @"mac"
#define COLUMN_ICON             @"icon"
#define COLUMN_IRBRAND          @"brand"
#define COLUMN_IRMODEL          @"model"

//IR GROUPS
#define TABLE_IRGROUPS          @"irgroups"
#define COLUMN_POSITION         @"position"

//PARAMS
#define TABLE_PARAMS            @"params"
#define COLUMN_TOKEN            @"token"

//ICONS
#define TABLE_ICONS             @"icons"
#define COLUMN_URL              @"url"
#define COLUMN_SIZE             @"size"

#define DATABASE_NAME           @"jsplugs"
#define DATABASE_FILE           @"jsplugs.db"
#define DATABASE_VERSION        1

/*
//create table for IR Codes
private static final String TABLE_CREATE_IRCODE = "create table "
+ TABLE_IRCODES + "( "+COLUMN_ID+" integer primary key autoincrement, "
+ COLUMN_GROUPID +" integer not null,"+ COLUMN_NAME + " text, " + COLUMN_FILENAME+" integer, "
+ COLUMN_ICON+" text, "+COLUMN_MAC+" text, "+COLUMN_POSITION+" integer, "+COLUMN_IRBRAND+" text, "+COLUMN_IRMODEL+" text );";

// Database creation sql statement
private static final String TABLE_CREATE_SMARTPLUG = "create table "
+ TABLE_SMARTPLUGS + "(" + COLUMN_ID
+ " integer primary key autoincrement, " + COLUMN_NAME +" text not null, " + COLUMN_SID
+ " text, "+ COLUMN_IP + " text not null unique, "+ COLUMN_SERVER +" text, "
+ COLUMN_MODEL+" text, "+COLUMN_BUILD_NO+" integer, "+COLUMN_PROT_VER+" integer, "
+ COLUMN_HW_VER+" text, "+COLUMN_FW_VER+" text, "+COLUMN_FW_DATE+" integer, "
+ COLUMN_FLAG+" integer, "+COLUMN_RELAY+" integer, "+COLUMN_HSENSOR+" integer, "
+ COLUMN_CSENSOR+" integer, "+COLUMN_NIGHTLIGHT+" integer, "+COLUMN_ACTIVE+" integer, "
+ COLUMN_ICON +" text, "+ COLUMN_NOTIFY_POWER +" integer, "+ COLUMN_NOTIFY_CO +" integer, "
+ COLUMN_NOTIFY_TIMER +" integer, "+ COLUMN_GIVEN_NAME +" text );";

// Database creation sql statement
private static final String TABLE_CREATE_ALARM = "create table "
+ TABLE_ALARMS + "(" + COLUMN_ID
+ " integer primary key autoincrement, " + COLUMN_DEVICE_ID +" text not null, " + COLUMN_SERVICE_ID
+ " integer not null, "+ COLUMN_DOW + " integer not null, "+ COLUMN_INIT_HOUR +" integer not null, "+ COLUMN_INIT_MINUTES
+ " integer not null, "+COLUMN_END_HOUR+" integer not null, "+ COLUMN_END_MINUTES +" integer not null, "+ COLUMN_SNOOZE
+ " integer);";

private static final String TABLE_CREATE_PARAMS = "create table "
+ TABLE_PARAMS + "(" + COLUMN_ID
+ " integer primary key autoincrement, " + COLUMN_TOKEN + " text);";

private static final String TABLE_CREATE_IRGROUPS = "create table "
+ TABLE_IRGROUPS + "(" + COLUMN_ID
+ " integer primary key autoincrement, " + COLUMN_NAME + " text, " + COLUMN_ICON + " text, "+ COLUMN_POSITION + " integer); ";

private static final String TABLE_CREATE_ICONS = "create table "
+ TABLE_ICONS + "(" + COLUMN_ID + " integer primary key autoincrement, "
+ COLUMN_URL + " text unique, " + COLUMN_SIZE + " integer)";
*/

@implementation SQLHelper
{
    FMDatabase *db;
}

static SQLHelper *instance;

+ (SQLHelper *)getInstance
{
    @synchronized(self) {
        if (instance == nil)
            instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *cacheDir = [NSSearchPathForDirectoriesInDomains
                              (NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dbPath = [cacheDir
                            stringByAppendingPathComponent:DATABASE_FILE];
        
        // Copy database from bundle if not found
        if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
            [self copyDbIfNeeded];
        }
        
        db = [FMDatabase databaseWithPath:dbPath];
        if (!db) {
            NSLog(@"Failed to open database!");
        }
    }
    return self;
}

- (void)copyDbIfNeeded
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains
                          (NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [cacheDir stringByAppendingPathComponent:DATABASE_FILE];

    BOOL isDir;
    if(![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        NSString *bundlePath = [[NSBundle mainBundle]
                                pathForResource:DATABASE_NAME
                                ofType:@"db" inDirectory:@""];
        // will subdirectories be created. sometimes, the cache dir gets deleted.
        [fileManager copyItemAtPath:bundlePath  toPath:path error:nil];
    }
}

//==================================================================
#pragma mark - Public methods
//==================================================================
- (BOOL)insertIcons:(NSString *)url size:(int)size
{
    return [db executeUpdate:@"INSERT INTO ? (?, ?) VALUES (?, ?)",
            TABLE_ICONS, COLUMN_URL, COLUMN_SIZE, url, [NSNumber numberWithInt:size], nil];
}

- (NSArray *)getIcons
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ?", TABLE_ICONS];
    NSMutableArray *icons = [NSMutableArray new];
    while ([results next]) {
        Icon *icon = [Icon new];
        icon.url = [results stringForColumn:COLUMN_URL];
        icon.size = [results intForColumn:COLUMN_SIZE];
        [icons addObject:icon];
    }
    return icons;
}

- (BOOL)insertIRGroup:(NSString *)desc icon:(NSString *)icon position:(int)position
{
    return [db executeUpdate:@"INSERT INTO ? (?, ?, ?) VALUES (?, ?, ?)",
            TABLE_IRGROUPS, COLUMN_NAME, COLUMN_ICON, COLUMN_POSITION, desc, icon, [NSNumber numberWithInt:position], nil];
}

- (NSArray *)getIRGroups
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ?", TABLE_IRGROUPS];
    NSMutableArray *irGroups = [NSMutableArray new];
    while ([results next]) {
        IrGroup *irGroup = [IrGroup new];
        irGroup.name = [results stringForColumn:COLUMN_NAME];
        irGroup.icon = [results stringForColumn:COLUMN_ICON];
        irGroup.position = [results intForColumn:COLUMN_POSITION];
        [irGroups addObject:irGroup];
    }
    return irGroups;
}

- (BOOL)deleteIRGroup:(int)id
{
    BOOL toReturn = [db executeUpdate:@"DELETE FROM ? WHERE ? = ?", TABLE_IRGROUPS, COLUMN_ID, id, nil];
    if (toReturn){
        if ([self deleteIRCodes:id]){
            toReturn = true;
        } else {
            toReturn = false;
        }
    }
    return toReturn;
}

- (BOOL)deleteIRCodes:(int)groupid
{
    return [db executeUpdate:@"DELETE FROM ? WHERE ? = ?", TABLE_IRCODES, COLUMN_GROUPID, [NSNumber numberWithInt:groupid], nil];
}

- (BOOL)deleteIRCode:(int)id
{
    return [db executeUpdate:@"DELETE FROM ? WHERE ? = ?", TABLE_IRCODES, COLUMN_ID, [NSNumber numberWithInt:id], nil];
}

- (NSArray *)getIRGroups:(int)id
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ?", TABLE_IRGROUPS, COLUMN_ID, id, nil];
    NSMutableArray *irGroups = [NSMutableArray new];
    while ([results next]) {
        IrGroup *irGroup = [IrGroup new];
        irGroup.name = [results stringForColumn:COLUMN_NAME];
        irGroup.icon = [results stringForColumn:COLUMN_ICON];
        irGroup.position = [results intForColumn:COLUMN_POSITION];
        [irGroups addObject:irGroup];
    }
    return irGroups;
}

- (BOOL)insertIRCodes:(int)gid name:(NSString *)name filename:(int)filename
                 icon:(NSString *)icon mac:(NSString *)mac
{
    return [db executeUpdate:@"INSERT INTO ? (?, ?, ?, ?, ?) VALUES (?, ?, ?, ?, ?)",
            TABLE_IRCODES, COLUMN_GROUPID, COLUMN_NAME, COLUMN_FILENAME, COLUMN_ICON, COLUMN_MAC,
            gid, name, [NSNumber numberWithInt:filename], icon, mac, nil];
}

- (NSArray *)getIRCodes
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ?", TABLE_IRCODES];
    NSMutableArray *irCodes = [NSMutableArray new];
    while ([results next]) {
        IrCode *irCode = [IrCode new];
        irCode.group_id = [results intForColumn:COLUMN_GROUPID];
        irCode.name = [results stringForColumn:COLUMN_NAME];
        irCode.filename = [results intForColumn:COLUMN_FILENAME];
        irCode.icon = [results stringForColumn:COLUMN_ICON];
        irCode.mac = [results stringForColumn:COLUMN_MAC];
        irCode.position = [results intForColumn:COLUMN_POSITION];
        irCode.brand = [results stringForColumn:COLUMN_IRBRAND];
        irCode.model = [results stringForColumn:COLUMN_IRMODEL];
        [irCodes addObject:irCode];
    }
    return irCodes;
}

- (NSArray *)getIRCodesByGroup:(int)id
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ?", TABLE_IRCODES, COLUMN_GROUPID, id];
    NSMutableArray *irCodes = [NSMutableArray new];
    while ([results next]) {
        IrCode *irCode = [IrCode new];
        irCode.group_id = [results intForColumn:COLUMN_GROUPID];
        irCode.name = [results stringForColumn:COLUMN_NAME];
        irCode.filename = [results intForColumn:COLUMN_FILENAME];
        irCode.icon = [results stringForColumn:COLUMN_ICON];
        irCode.mac = [results stringForColumn:COLUMN_MAC];
        irCode.position = [results intForColumn:COLUMN_POSITION];
        irCode.brand = [results stringForColumn:COLUMN_IRBRAND];
        irCode.model = [results stringForColumn:COLUMN_IRMODEL];
        [irCodes addObject:irCode];
    }
    return irCodes;
}

- (BOOL)insertPlug:(NSString *)name sid:(NSString *)sid ip:(NSString *)ip
{
    return [db executeUpdate:@"INSERT INTO ? (?, ?, ?, ?, ?) VALUES (?, ?, ?, ?, ?)",
            TABLE_SMARTPLUGS, COLUMN_NAME, COLUMN_SID, COLUMN_IP, COLUMN_SERVER, COLUMN_ACTIVE,
            name, sid, ip, @"undefined", [NSNumber numberWithInt:1], nil];
}

- (BOOL)insertPlug:(JSmartPlug *)js active:(int)active
{
    return [db executeUpdate:@"INSERT INTO ? (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            TABLE_SMARTPLUGS, COLUMN_NAME, COLUMN_SID, COLUMN_IP, COLUMN_MODEL, COLUMN_BUILD_NO, COLUMN_PROT_VER, COLUMN_HW_VER, COLUMN_FW_VER, COLUMN_FW_DATE, COLUMN_FLAG, COLUMN_RELAY, COLUMN_HSENSOR, COLUMN_CSENSOR, COLUMN_NIGHTLIGHT, COLUMN_ACTIVE,
            js.name, js.sid, js.ip, js.model, [NSNumber numberWithInt:js.buildno], [NSNumber numberWithInt:js.prot_ver], js.hw_ver, js.fw_ver, [NSNumber numberWithInt:js.fw_date], [NSNumber numberWithInt:js.flag], [NSNumber numberWithInt:js.relay], [NSNumber numberWithInt:js.hall_sensor], [NSNumber numberWithInt:js.co_sensor], [NSNumber numberWithInt:js.nightlight], [NSNumber numberWithInt:active], nil];
}

- (BOOL)updatePlugID:(NSString *)mac ip:(NSString *)ip
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_SID, mac, COLUMN_IP, ip, nil];
}

- (BOOL)updatePlugName:(NSString *)data sid:(NSString *)sid
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_GIVEN_NAME, data, COLUMN_SID, sid, nil];
}

- (BOOL)updatePlugNightlightService:(int)data sid:(NSString *)sid
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_NIGHTLIGHT, data, COLUMN_SID, sid, nil];
}

- (BOOL)updatePlugCoSensorService:(int)data sid:(NSString *)sid
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_CSENSOR, data, COLUMN_SID, sid, nil];
}

- (BOOL)updatePlugHallSensorService:(int)data sid:(NSString *)sid
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_HSENSOR, data, COLUMN_SID, sid, nil];
}

- (BOOL)updatePlugRelayService:(int)data sid:(NSString *)sid
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_RELAY, data, COLUMN_SID, sid, nil];
}

- (BOOL)updatePlugServicesByIP:(JSmartPlug *)js
{
    return [db executeUpdate:@"UPDATE ? SET ? = ?, ? = ?, ? = ?, ? = ?, ? = ?, ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS,
            COLUMN_RELAY, [NSNumber numberWithInt:js.relay],
            COLUMN_HSENSOR, [NSNumber numberWithInt:js.hall_sensor],
            COLUMN_CSENSOR, [NSNumber numberWithInt:js.co_sensor],
            COLUMN_NIGHTLIGHT, [NSNumber numberWithInt:js.nightlight],
            COLUMN_HW_VER, js.hw_ver,
            COLUMN_FW_VER, js.fw_ver,
            COLUMN_IP, js.ip, nil];
}

- (BOOL)updatePlugServicesByID:(JSmartPlug *)js
{
    return [db executeUpdate:@"UPDATE ? SET ? = ?, ? = ?, ? = ?, ? = ?, ? = ?, ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS,
            COLUMN_RELAY, [NSNumber numberWithInt:js.relay],
            COLUMN_HSENSOR, [NSNumber numberWithInt:js.hall_sensor],
            COLUMN_CSENSOR, [NSNumber numberWithInt:js.co_sensor],
            COLUMN_NIGHTLIGHT, [NSNumber numberWithInt:js.nightlight],
            COLUMN_HW_VER, js.hw_ver,
            COLUMN_FW_VER, js.fw_ver,
            COLUMN_SID, js.sid, nil];
}

- (BOOL)updatePlugIP:(NSString *)name ip:(NSString *)ip
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_IP, ip, COLUMN_NAME, name, nil];
}

- (BOOL)updatePlugRelay:(NSString *)sid relay:(int)relay
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_RELAY, [NSNumber numberWithInt:relay], COLUMN_SID, sid, nil];
}

- (BOOL)updatePlugNightlight:(NSString *)sid nl:(int)nl
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_NIGHTLIGHT, [NSNumber numberWithInt:nl], COLUMN_SID, sid, nil];
}

- (BOOL)activatePlug:(NSString *)sid
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_ACTIVE, [NSNumber numberWithInt:1], COLUMN_SID, sid, nil];
}

- (BOOL)insertToken:(NSString *)token
{
    return [db executeUpdate:@"INSERT INTO ? (?) VALUES (?)",
            TABLE_PARAMS, COLUMN_TOKEN, token, nil];
}

- (NSArray *)getToken
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ?", TABLE_PARAMS];
    NSMutableArray *tokens = [NSMutableArray new];
    while ([results next]) {
        NSString *token = [results stringForColumn:COLUMN_TOKEN];
        [tokens addObject:token];
    }
    return tokens;
}

- (BOOL)removePlugsIP
{
    return [db executeUpdate:@"UPDATE ? SET ? = ?",
            TABLE_SMARTPLUGS, COLUMN_IP, @"", nil];
}

- (BOOL)removePlugIP:(NSString *)serviceName
{
    return [db executeUpdate:@"UPDATE ? SET ? = ?",
            TABLE_SMARTPLUGS, COLUMN_IP, @"0", nil];
}

- (BOOL)updatePlugIP:(NSString *)name ip:(NSString *)ip
{
    return [db executeUpdate:@"UPDATE ? SET ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS, COLUMN_IP, ip, COLUMN_NAME, name, nil];
}

- (NSArray *)getPlugData:(NSString *)ip
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ? AND active = 1", TABLE_SMARTPLUGS, COLUMN_IP, ip];
    NSMutableArray *plugs = [NSMutableArray new];
    while ([results next]) {
        JSmartPlug *plug = [JSmartPlug new];
        plug.name = [results stringForColumn:COLUMN_NAME];
        plug.sid = [results stringForColumn:COLUMN_SID];
        plug.ip = [results stringForColumn:COLUMN_IP];
        plug.model = [results stringForColumn:COLUMN_MODEL];
        plug.buildno = [results intForColumn:COLUMN_BUILD_NO];
        plug.prot_ver = [results intForColumn:COLUMN_PROT_VER];
        plug.hw_ver = [results stringForColumn:COLUMN_HW_VER];
        plug.fw_ver = [results stringForColumn:COLUMN_FW_VER];
        plug.fw_date = [results intForColumn:COLUMN_FW_DATE];
        plug.flag = [results intForColumn:COLUMN_FLAG];
        plug.relay = [results intForColumn:COLUMN_RELAY];
        plug.hall_sensor = [results intForColumn:COLUMN_HSENSOR];
        plug.co_sensor = [results intForColumn:COLUMN_CSENSOR];
        plug.nightlight = [results intForColumn:COLUMN_NIGHTLIGHT];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        [plugs addObject:plug];
    }
    return plugs;
}

- (NSArray *)getPlugDataByID:(NSString *)sid
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ?xs", TABLE_SMARTPLUGS, COLUMN_SID, sid];
    NSMutableArray *plugs = [NSMutableArray new];
    while ([results next]) {
        JSmartPlug *plug = [JSmartPlug new];
        plug.name = [results stringForColumn:COLUMN_NAME];
        plug.sid = [results stringForColumn:COLUMN_SID];
        plug.ip = [results stringForColumn:COLUMN_IP];
        plug.model = [results stringForColumn:COLUMN_MODEL];
        plug.buildno = [results intForColumn:COLUMN_BUILD_NO];
        plug.prot_ver = [results intForColumn:COLUMN_PROT_VER];
        plug.hw_ver = [results stringForColumn:COLUMN_HW_VER];
        plug.fw_ver = [results stringForColumn:COLUMN_FW_VER];
        plug.fw_date = [results intForColumn:COLUMN_FW_DATE];
        plug.flag = [results intForColumn:COLUMN_FLAG];
        plug.relay = [results intForColumn:COLUMN_RELAY];
        plug.hall_sensor = [results intForColumn:COLUMN_HSENSOR];
        plug.co_sensor = [results intForColumn:COLUMN_CSENSOR];
        plug.nightlight = [results intForColumn:COLUMN_NIGHTLIGHT];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        [plugs addObject:plug];
    }
    return plugs;
}

- (NSArray *)getPlugDataByName:(NSString *)name
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ?", TABLE_SMARTPLUGS, COLUMN_NAME, name];
    NSMutableArray *plugs = [NSMutableArray new];
    while ([results next]) {
        JSmartPlug *plug = [JSmartPlug new];
        plug.name = [results stringForColumn:COLUMN_NAME];
        plug.sid = [results stringForColumn:COLUMN_SID];
        plug.ip = [results stringForColumn:COLUMN_IP];
        plug.model = [results stringForColumn:COLUMN_MODEL];
        plug.buildno = [results intForColumn:COLUMN_BUILD_NO];
        plug.prot_ver = [results intForColumn:COLUMN_PROT_VER];
        plug.hw_ver = [results stringForColumn:COLUMN_HW_VER];
        plug.fw_ver = [results stringForColumn:COLUMN_FW_VER];
        plug.fw_date = [results intForColumn:COLUMN_FW_DATE];
        plug.flag = [results intForColumn:COLUMN_FLAG];
        plug.relay = [results intForColumn:COLUMN_RELAY];
        plug.hall_sensor = [results intForColumn:COLUMN_HSENSOR];
        plug.co_sensor = [results intForColumn:COLUMN_CSENSOR];
        plug.nightlight = [results intForColumn:COLUMN_NIGHTLIGHT];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        [plugs addObject:plug];
    }
    return plugs;
}

- (NSArray *)getPlugData
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE active = 1", TABLE_SMARTPLUGS];
    NSMutableArray *plugs = [NSMutableArray new];
    while ([results next]) {
        JSmartPlug *plug = [JSmartPlug new];
        plug.name = [results stringForColumn:COLUMN_NAME];
        plug.sid = [results stringForColumn:COLUMN_SID];
        plug.ip = [results stringForColumn:COLUMN_IP];
        plug.model = [results stringForColumn:COLUMN_MODEL];
        plug.buildno = [results intForColumn:COLUMN_BUILD_NO];
        plug.prot_ver = [results intForColumn:COLUMN_PROT_VER];
        plug.hw_ver = [results stringForColumn:COLUMN_HW_VER];
        plug.fw_ver = [results stringForColumn:COLUMN_FW_VER];
        plug.fw_date = [results intForColumn:COLUMN_FW_DATE];
        plug.flag = [results intForColumn:COLUMN_FLAG];
        plug.relay = [results intForColumn:COLUMN_RELAY];
        plug.hall_sensor = [results intForColumn:COLUMN_HSENSOR];
        plug.co_sensor = [results intForColumn:COLUMN_CSENSOR];
        plug.nightlight = [results intForColumn:COLUMN_NIGHTLIGHT];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        [plugs addObject:plug];
    }
    return plugs;
}

- (NSArray *)getNonActivePlugData
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE active = 0", TABLE_SMARTPLUGS];
    NSMutableArray *plugs = [NSMutableArray new];
    while ([results next]) {
        JSmartPlug *plug = [JSmartPlug new];
        plug.name = [results stringForColumn:COLUMN_NAME];
        plug.sid = [results stringForColumn:COLUMN_SID];
        plug.ip = [results stringForColumn:COLUMN_IP];
        plug.model = [results stringForColumn:COLUMN_MODEL];
        plug.buildno = [results intForColumn:COLUMN_BUILD_NO];
        plug.prot_ver = [results intForColumn:COLUMN_PROT_VER];
        plug.hw_ver = [results stringForColumn:COLUMN_HW_VER];
        plug.fw_ver = [results stringForColumn:COLUMN_FW_VER];
        plug.fw_date = [results intForColumn:COLUMN_FW_DATE];
        plug.flag = [results intForColumn:COLUMN_FLAG];
        plug.relay = [results intForColumn:COLUMN_RELAY];
        plug.hall_sensor = [results intForColumn:COLUMN_HSENSOR];
        plug.co_sensor = [results intForColumn:COLUMN_CSENSOR];
        plug.nightlight = [results intForColumn:COLUMN_NIGHTLIGHT];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        [plugs addObject:plug];
    }
    return plugs;
}

- (BOOL)deletePlugData:(NSString *)ip
{
    return [db executeUpdate:@"DELETE FROM ? WHERE ? = ?", TABLE_SMARTPLUGS, COLUMN_IP, ip, nil];
}

- (BOOL)deletePlugDataByID:(NSString *)mac
{
    return [db executeUpdate:@"DELETE FROM ? WHERE ? = ?", TABLE_SMARTPLUGS, COLUMN_SID, mac, nil];
}

- (BOOL)updatePlugNameNotify:(NSString *)mac name:(NSString *)name notifyOnPowerOutage:(int)notifyOnPowerOutage notifyOnCoWarning:(int)notifyOnCoWarning notifyOnTimerActivated:(int)notifyOnTimerActivated icon:(NSString *)icon
{
    return [db executeUpdate:@"UPDATE ? SET ? = ?, ? = ?, ? = ?, ? = ?, ? = ? WHERE ? = ?",
            TABLE_SMARTPLUGS,
            COLUMN_NOTIFY_POWER, [NSNumber numberWithInt:notifyOnPowerOutage],
            COLUMN_NOTIFY_CO, [NSNumber numberWithInt:notifyOnCoWarning],
            COLUMN_NOTIFY_TIMER, [NSNumber numberWithInt:notifyOnTimerActivated],
            COLUMN_GIVEN_NAME, name,
            COLUMN_ICON, icon,
            COLUMN_SID, mac, nil];
}

- (BOOL)deleteNonActivePlug:(NSString *)name
{
    if ([name isEqualToString:@"all"]) {
        return [db executeUpdate:@"DELETE FROM ? WHERE ? = ?", TABLE_SMARTPLUGS, COLUMN_ACTIVE, [NSNumber numberWithInt:0], nil];
    } else {
        return [db executeUpdate:@"DELETE FROM ? WHERE ? = ? AND ? = ?", TABLE_SMARTPLUGS, COLUMN_NAME, name,  COLUMN_ACTIVE, [NSNumber numberWithInt:0], nil];
    }
}

- (BOOL)deleteAlarmData:(int)id
{
    return [db executeUpdate:@"DELETE FROM ? WHERE ? = ?", TABLE_ALARMS, COLUMN_ID, [NSNumber numberWithInt:id], nil];
}

- (BOOL)insertAlarm:(Alarm *)a
{
    return [db executeUpdate:@"INSERT INTO ? (?, ?, ?, ?, ?, ?, ?, ?) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            TABLE_ALARMS, COLUMN_DEVICE_ID, COLUMN_SERVICE_ID, COLUMN_DOW, COLUMN_INIT_HOUR,
            COLUMN_INIT_MINUTES, COLUMN_END_HOUR, COLUMN_END_MINUTES, COLUMN_SNOOZE,
            a.device_id, [NSNumber numberWithInt:a.service_id], [NSNumber numberWithInt:a.dow], [NSNumber numberWithInt:a.initial_hour], [NSNumber numberWithInt:a.initial_minute], [NSNumber numberWithInt:a.end_hour], [NSNumber numberWithInt:a.end_minute], [NSNumber numberWithInt:a.snooze], nil];
}

- (BOOL)updateAlarm:(Alarm *)a
{
    return [db executeUpdate:@"UPDATE ? SET ? = ?, ? = ?, ? = ?, ? = ?, ? = ? WHERE ? = ?",
            TABLE_ALARMS,
            COLUMN_DEVICE_ID, a.device_id,
            COLUMN_SERVICE_ID, [NSNumber numberWithInt:a.service_id],
            COLUMN_DOW, [NSNumber numberWithInt:a.dow],
            COLUMN_INIT_HOUR, [NSNumber numberWithInt:a.initial_hour],
            COLUMN_INIT_MINUTES, [NSNumber numberWithInt:a.initial_minute],
            COLUMN_END_HOUR, [NSNumber numberWithInt:a.end_hour],
            COLUMN_END_MINUTES, [NSNumber numberWithInt:a.end_minute],
            COLUMN_SNOOZE, [NSNumber numberWithInt:a.snooze],
            COLUMN_ID, [NSNumber numberWithInt:a.alarm_id], nil];
}

- (NSArray *)getAlarmData:(int)alarmId
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ?", TABLE_ALARMS, COLUMN_ID, alarmId];
    NSMutableArray *alarms = [NSMutableArray new];
    while ([results next]) {
        Alarm *alarm = [Alarm new];
        alarm.alarm_id = [results intForColumn:COLUMN_ID];
        alarm.device_id = [results stringForColumn:COLUMN_DEVICE_ID];
        alarm.service_id = [results intForColumn:COLUMN_SERVICE_ID];
        alarm.dow = [results intForColumn:COLUMN_DOW];
        alarm.initial_hour = [results intForColumn:COLUMN_INIT_HOUR];
        alarm.initial_minute = [results intForColumn:COLUMN_INIT_MINUTES];
        alarm.end_hour = [results intForColumn:COLUMN_END_HOUR];
        alarm.end_minute = [results intForColumn:COLUMN_END_MINUTES];
        alarm.snooze = [results intForColumn:COLUMN_SNOOZE];
        [alarms addObject:alarm];
    }
    return alarms;
}

- (NSArray *)getAlarmDataByData:(NSString *)deviceId
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ?", TABLE_ALARMS, COLUMN_DEVICE_ID, deviceId];
    NSMutableArray *alarms = [NSMutableArray new];
    while ([results next]) {
        Alarm *alarm = [Alarm new];
        alarm.alarm_id = [results intForColumn:COLUMN_ID];
        alarm.device_id = [results stringForColumn:COLUMN_DEVICE_ID];
        alarm.service_id = [results intForColumn:COLUMN_SERVICE_ID];
        alarm.dow = [results intForColumn:COLUMN_DOW];
        alarm.initial_hour = [results intForColumn:COLUMN_INIT_HOUR];
        alarm.initial_minute = [results intForColumn:COLUMN_INIT_MINUTES];
        alarm.end_hour = [results intForColumn:COLUMN_END_HOUR];
        alarm.end_minute = [results intForColumn:COLUMN_END_MINUTES];
        alarm.snooze = [results intForColumn:COLUMN_SNOOZE];
        [alarms addObject:alarm];
    }
    return alarms;
}

- (NSArray *)getAlarmDataByDataAndService:(NSString *)deviceId serviceId:(int)serviceId
{
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ? WHERE ? = ? AND ? = ?", TABLE_ALARMS, COLUMN_DEVICE_ID, deviceId, COLUMN_SERVICE_ID, serviceId];
    NSMutableArray *alarms = [NSMutableArray new];
    while ([results next]) {
        Alarm *alarm = [Alarm new];
        alarm.alarm_id = [results intForColumn:COLUMN_ID];
        alarm.device_id = [results stringForColumn:COLUMN_DEVICE_ID];
        alarm.service_id = [results intForColumn:COLUMN_SERVICE_ID];
        alarm.dow = [results intForColumn:COLUMN_DOW];
        alarm.initial_hour = [results intForColumn:COLUMN_INIT_HOUR];
        alarm.initial_minute = [results intForColumn:COLUMN_INIT_MINUTES];
        alarm.end_hour = [results intForColumn:COLUMN_END_HOUR];
        alarm.end_minute = [results intForColumn:COLUMN_END_MINUTES];
        alarm.snooze = [results intForColumn:COLUMN_SNOOZE];
        [alarms addObject:alarm];
    }
    return alarms;
}

@end
