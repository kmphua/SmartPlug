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
#define COLUMN_INIT_IR          @"init_ir";
#define COLUMN_END_IR           @"end_ir";

// alarm table
#define TABLE_ALARMS            @"alarms"
#define COLUMN_DEVICE_ID        @"device_id"
#define COLUMN_SERVICE_ID       @"service_id"               // 1 = relay, 2 nightled
#define COLUMN_DOW              @"dow"
#define COLUMN_INIT_HOUR        @"init_hour"
#define COLUMN_INIT_MINUTES     @"init_minutes"
#define COLUMN_END_HOUR         @"end_hour"
#define COLUMN_END_MINUTES      @"end_minutes"

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

//SNOOZE
#define COLUMN_RELAY_SNOOZE     @"relay_snooze"
#define COLUMN_LED_SNOOZE       @"led_snooze"
#define COLUMN_IR_SNOOZE        @"ir_snooze"

#define DATABASE_NAME           @"jsplugs"
#define DATABASE_FILE           @"jsplugs.db"
#define DATABASE_VERSION        1

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
        NSString *documentsDir = [NSSearchPathForDirectoriesInDomains
                              (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dbPath = [documentsDir stringByAppendingPathComponent:DATABASE_FILE];
        
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
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains
                          (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [documentsDir stringByAppendingPathComponent:DATABASE_FILE];

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
- (BOOL)updateDeviceSnooze:(NSString *)sid serviceId:(int)serviceId snooze:(int)snooze
{
    BOOL result = false;
    [db open];
    if (serviceId == RELAY_SERVICE) {
        result = [db executeUpdate:@"UPDATE smartplugs SET snooze = ? WHERE sid = ?", [NSNumber numberWithInt:snooze], sid];
    }
    if (serviceId == NIGHTLED_SERVICE){
        result = [db executeUpdate:@"UPDATE smartplugs SET led_snooze = ? WHERE sid = ?", [NSNumber numberWithInt:snooze], sid];
    }
    if (serviceId == IR_SERVICE){
        result = [db executeUpdate:@"UPDATE smartplugs SET ir_snooze = ? WHERE sid = ?", [NSNumber numberWithInt:snooze], sid];
    }
    [db close];
    return result;
}

- (int)getRelaySnooze:(NSString *)sid
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE sid = ?", sid];
    int snooze = 0;
    if ([results next]) {
        snooze = [results intForColumn:COLUMN_SNOOZE];
    }
    [db close];
    return snooze;
}

- (int)getLedSnooze:(NSString *)sid
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE sid = ?", sid];
    int snooze = 0;
    if ([results next]) {
        snooze = [results intForColumn:COLUMN_LED_SNOOZE];
    }
    [db close];
    return snooze;
}

- (int)getIRSnooze:(NSString *)sid
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE sid = ?", sid];
    int snooze = 0;
    if ([results next]) {
        snooze = [results intForColumn:COLUMN_IR_SNOOZE];
    }
    [db close];
    return snooze;
}

- (BOOL)insertIcons:(NSString *)url size:(int)size sid:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"INSERT INTO icons (sid, url, size) VALUES (?, ?, ?)",
                   sid, url, [NSNumber numberWithInt:size]];
    [db close];
    return result;
}

- (NSArray *)getIcons
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM icons"];
    NSMutableArray *icons = [NSMutableArray new];
    while ([results next]) {
        Icon *icon = [Icon new];
        icon.sid = [results stringForColumn:COLUMN_SID];
        icon.url = [results stringForColumn:COLUMN_URL];
        icon.size = [results intForColumn:COLUMN_SIZE];
        [icons addObject:icon];
    }
    [db close];
    return icons;
}

- (NSArray *)getIconByUrl:(NSString *)url
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM icons WHERE url = ?", url];
    NSMutableArray *icons = [NSMutableArray new];
    while ([results next]) {
        Icon *icon = [Icon new];
        icon.sid = [results stringForColumn:COLUMN_SID];
        icon.url = [results stringForColumn:COLUMN_URL];
        icon.size = [results intForColumn:COLUMN_SIZE];
        [icons addObject:icon];
    }
    [db close];
    return icons;
}

- (BOOL)insertIRGroup:(NSString *)name devId:(NSString *)devId icon:(NSString *)icon position:(int)position sid:(int)sid
{
    [db open];
    BOOL result = NO;
    FMResultSet *results = [db executeQuery:@"SELECT * FROM irgroups WHERE sid = ?", [NSNumber numberWithInt:sid]];
    if (!results || !results.next) {
        result = [db executeUpdate:@"INSERT INTO irgroups (name, icon, position, sid, mac) VALUES (?, ?, ?, ?, ?)",
                       name, icon, [NSNumber numberWithInt:position], [NSNumber numberWithInt:sid], devId];
    } else {
        NSLog(@"RECORD EXIST - IR GROUP NOT ADDED");
    }
    [db close];
    return result;
}

- (BOOL)updateIRGroup:(IrGroup *)group
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE irgroups SET name = ?, icon = ?, position = ? WHERE _id = ?",
                   group.name,
                   group.icon,
                   [NSNumber numberWithInt:group.position],
                   [NSNumber numberWithInt:group.group_id]];
    [db close];
    return result;
}

- (NSArray *)getIRGroups
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM irgroups"];
    NSMutableArray *irGroups = [NSMutableArray new];
    while ([results next]) {
        IrGroup *irGroup = [IrGroup new];
        irGroup.group_id = [results intForColumn:COLUMN_ID];
        irGroup.name = [results stringForColumn:COLUMN_NAME];
        irGroup.icon = [results stringForColumn:COLUMN_ICON];
        irGroup.position = [results intForColumn:COLUMN_POSITION];
        irGroup.sid = [results intForColumn:COLUMN_SID];
        irGroup.mac = [results stringForColumn:COLUMN_MAC];
        [irGroups addObject:irGroup];
    }
    [db close];
    return irGroups;
}

- (BOOL)deleteIRGroups
{
    [db open];
    BOOL toReturn = [db executeUpdate:@"DELETE FROM irgroups"];
    if (toReturn){
        if ([self deleteAllIRCodes]){
            toReturn = true;
        } else {
            toReturn = false;
        }
    }
    [db close];
    return toReturn;
}

- (IrGroup *)getIRGroupBySID:(int)sid
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM irgroups WHERE sid = ?", [NSNumber numberWithInt:sid]];
    IrGroup *irGroup;
    while ([results next]) {
        irGroup = [IrGroup new];
        irGroup.group_id = [results intForColumn:COLUMN_ID];
        irGroup.name = [results stringForColumn:COLUMN_NAME];
        irGroup.icon = [results stringForColumn:COLUMN_ICON];
        irGroup.position = [results intForColumn:COLUMN_POSITION];
        irGroup.sid = [results intForColumn:COLUMN_SID];
        irGroup.mac = [results stringForColumn:COLUMN_MAC];
    }
    [db close];
    return irGroup;
}

- (NSArray *)getIRGroupByMac:(NSString *)mac
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM irgroups WHERE mac = ?", mac];
    NSMutableArray *irGroups = [NSMutableArray new];
    while ([results next]) {
        IrGroup *irGroup = [IrGroup new];
        irGroup.group_id = [results intForColumn:COLUMN_ID];
        irGroup.name = [results stringForColumn:COLUMN_NAME];
        irGroup.icon = [results stringForColumn:COLUMN_ICON];
        irGroup.position = [results intForColumn:COLUMN_POSITION];
        irGroup.sid = [results intForColumn:COLUMN_SID];
        irGroup.mac = [results stringForColumn:COLUMN_MAC];
        [irGroups addObject:irGroup];
    }
    [db close];
    return irGroups;
}

- (NSArray *)getIRGroupByName:(NSString *)groupName
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM irgroups WHERE name = ?", groupName];
    NSMutableArray *irGroups = [NSMutableArray new];
    while ([results next]) {
        IrGroup * irGroup = [IrGroup new];
        irGroup.group_id = [results intForColumn:COLUMN_ID];
        irGroup.name = [results stringForColumn:COLUMN_NAME];
        irGroup.icon = [results stringForColumn:COLUMN_ICON];
        irGroup.position = [results intForColumn:COLUMN_POSITION];
        irGroup.sid = [results intForColumn:COLUMN_SID];
        irGroup.mac = [results stringForColumn:COLUMN_MAC];
        [irGroups addObject:irGroup];
    }
    [db close];
    return irGroups;
}

- (BOOL)deleteIRGroupById:(int)groupId
{
    [db open];
    BOOL toReturn = [db executeUpdate:@"DELETE FROM irgroups WHERE sid = ?", [NSNumber numberWithInt:groupId]];
    if (toReturn){
        if ([self deleteIRCodes:groupId]){
            toReturn = true;
        } else {
            toReturn = false;
        }
    }
    [db close];
    return toReturn;
}

- (BOOL)deleteAllIRCodes
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM ircodes"];
    [db close];
    return result;
}

- (BOOL)deleteIRCodes:(int)groupId
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM ircodes WHERE group_id = ?", [NSNumber numberWithInt:groupId]];
    [db close];
    return result;
}

- (BOOL)deleteIRGroupBySID:(int)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM irgroups WHERE sid = ?", [NSNumber numberWithInt:sid]];
    if (result) {
        result = [self deleteIRCodesBySID:sid];
    }
    [db close];
    return result;
}

- (BOOL)deleteIRCodesBySID:(int)groupId
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM ircodes WHERE group_id = ?", [NSNumber numberWithInt:groupId]];
    [db close];
    return result;
}

- (BOOL)deleteIRCode:(int)sid
{
    BOOL result;
    [db open];
    result = [db executeUpdate:@"DELETE FROM ircodes WHERE sid = ?", [NSNumber numberWithInt:sid]];
    [db close];
    return result;
}

- (NSArray *)getIRGroup:(int)groupId
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM irgroups WHERE sid = ?", [NSNumber numberWithInt:groupId]];
    NSMutableArray *irGroups = [NSMutableArray new];
    while ([results next]) {
        IrGroup *irGroup = [IrGroup new];
        irGroup.group_id = [results intForColumn:COLUMN_ID];
        irGroup.name = [results stringForColumn:COLUMN_NAME];
        irGroup.icon = [results stringForColumn:COLUMN_ICON];
        irGroup.position = [results intForColumn:COLUMN_POSITION];
        irGroup.sid = [results intForColumn:COLUMN_SID];
        irGroup.mac = [results stringForColumn:COLUMN_MAC];
        [irGroups addObject:irGroup];
    }
    [db close];
    return irGroups;
}

- (BOOL)insertIRCodes:(int)groupId name:(NSString *)name filename:(int)filename
                 icon:(NSString *)icon mac:(NSString *)mac sid:(int)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"INSERT INTO ircodes (group_id, name, filename, icon, mac, sid) VALUES (?, ?, ?, ?, ?, ?)",
                   [NSNumber numberWithInt:groupId], name, [NSNumber numberWithInt:filename], icon, mac, [NSNumber numberWithInt:sid]];
    [db close];
    return result;
}

- (BOOL)updateIRCodeSID:(int)filename sid:(int)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE ircodes SET sid = ? WHERE filename = ?",
                   [NSNumber numberWithInt:sid],
                   [NSNumber numberWithInt:filename]];
    [db close];
    return result;
}

- (BOOL)updateIRGroupID:(int)groupId sid:(int)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE irgroups SET sid = ? WHERE _id = ?",
                   [NSNumber numberWithInt:sid],
                   [NSNumber numberWithInt:groupId]];
    [db close];
    return result;
}

- (BOOL)updateIRCode:(IrCode *)code
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE ircodes SET group_id = ?, name = ?, filename = ?, icon = ?, mac = ?, position = ?, brand = ?, model = ? WHERE _id = ?",
                   [NSNumber numberWithInt:code.group_id],
                   code.name,
                   [NSNumber numberWithInt:code.filename],
                   code.icon,
                   code.mac,
                   [NSNumber numberWithInt:code.position],
                   code.brand,
                   code.model,
                   [NSNumber numberWithInt:code.code_id]];
    [db close];
    return result;
}

- (NSArray *)getIRCodes
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ircodes"];
    NSMutableArray *irCodes = [NSMutableArray new];
    while ([results next]) {
        IrCode *irCode = [IrCode new];
        irCode.code_id = [results intForColumn:COLUMN_ID];
        irCode.group_id = [results intForColumn:COLUMN_GROUPID];
        irCode.name = [results stringForColumn:COLUMN_NAME];
        irCode.filename = [results intForColumn:COLUMN_FILENAME];
        irCode.icon = [results stringForColumn:COLUMN_ICON];
        irCode.mac = [results stringForColumn:COLUMN_MAC];
        irCode.position = [results intForColumn:COLUMN_POSITION];
        irCode.brand = [results stringForColumn:COLUMN_IRBRAND];
        irCode.model = [results stringForColumn:COLUMN_IRMODEL];
        irCode.sid = [results intForColumn:COLUMN_SID];
        [irCodes addObject:irCode];
    }
    [db close];
    return irCodes;
}

- (NSArray *)getIRCodesByGroup:(int)groupId
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ircodes WHERE group_id = ?", [NSNumber numberWithInt:groupId]];
    NSMutableArray *irCodes = [NSMutableArray new];
    while ([results next]) {
        IrCode *irCode = [IrCode new];
        irCode.code_id = [results intForColumn:COLUMN_ID];
        irCode.group_id = [results intForColumn:COLUMN_GROUPID];
        irCode.name = [results stringForColumn:COLUMN_NAME];
        irCode.filename = [results intForColumn:COLUMN_FILENAME];
        irCode.icon = [results stringForColumn:COLUMN_ICON];
        irCode.mac = [results stringForColumn:COLUMN_MAC];
        irCode.position = [results intForColumn:COLUMN_POSITION];
        irCode.brand = [results stringForColumn:COLUMN_IRBRAND];
        irCode.model = [results stringForColumn:COLUMN_IRMODEL];
        irCode.sid = [results intForColumn:COLUMN_SID];
        [irCodes addObject:irCode];
    }
    [db close];
    return irCodes;
}

- (NSArray *)getIRCodeById:(int)filename
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM ircodes WHERE filename = ?", [NSNumber numberWithInt:filename]];
    NSMutableArray *irCodes = [NSMutableArray new];
    while ([results next]) {
        IrCode *irCode = [IrCode new];
        irCode.code_id = [results intForColumn:COLUMN_ID];
        irCode.group_id = [results intForColumn:COLUMN_GROUPID];
        irCode.name = [results stringForColumn:COLUMN_NAME];
        irCode.filename = [results intForColumn:COLUMN_FILENAME];
        irCode.icon = [results stringForColumn:COLUMN_ICON];
        irCode.mac = [results stringForColumn:COLUMN_MAC];
        irCode.position = [results intForColumn:COLUMN_POSITION];
        irCode.brand = [results stringForColumn:COLUMN_IRBRAND];
        irCode.model = [results stringForColumn:COLUMN_IRMODEL];
        irCode.sid = [results intForColumn:COLUMN_SID];
        [irCodes addObject:irCode];
    }
    [db close];
    return irCodes;
}

- (BOOL)insertPlug:(JSmartPlug *)js active:(int)active
{
    [db open];
    BOOL result = false;
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE name = ?", js.name];
    if (!results || !results.next) {
        // Plug doesn't exist, can insert
        result = [db executeUpdate:@"INSERT INTO smartplugs (name, given_name, ip, icon, sid, model, build_no, prot_ver, hw_ver, fw_ver, fw_date, flag, relay, hsensor, csensor, nightlight, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                js.name, js.givenName, js.ip, js.icon, js.sid, js.model, [NSNumber numberWithInt:js.buildno], [NSNumber numberWithInt:js.prot_ver], js.hw_ver, js.fw_ver, [NSNumber numberWithInt:js.fw_date], [NSNumber numberWithInt:js.flag], [NSNumber numberWithInt:js.relay], [NSNumber numberWithInt:js.hall_sensor], [NSNumber numberWithInt:js.co_sensor], [NSNumber numberWithInt:js.nightlight], [NSNumber numberWithInt:active]];
    }
    [db close];
    return result;
}

- (BOOL)updatePlugID:(NSString *)mac ip:(NSString *)ip
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET sid = ? WHERE ip = ?", mac, ip];
    [db close];
    return result;
}

- (BOOL)updatePlugName:(NSString *)data sid:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET given_name = ? WHERE sid = ?", data, sid];
    [db close];
    return result;
}

- (BOOL)updatePlugNightlightService:(int)data sid:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET nightlight = ? WHERE sid = ?",
                   [NSNumber numberWithInt:data], sid];
    [db close];
    return result;
}

- (BOOL)updatePlugCoSensorService:(int)data sid:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET csensor = ? WHERE sid = ?",
                   [NSNumber numberWithInt:data], sid];
    [db close];
    return result;
}

- (BOOL)updatePlugHallSensorService:(int)data sid:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET hsensor = ? WHERE sid = ?",
                   [NSNumber numberWithInt:data], sid];
    [db close];
    return result;
}

- (BOOL)updateSnooze:(int)data sid:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET snooze = ? WHERE sid = ?",
                   [NSNumber numberWithInt:data], sid];
    [db close];
    return result;
}

- (BOOL)updatePlugRelayService:(int)data sid:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET relay = ? WHERE sid = ?",
                   [NSNumber numberWithInt:data], sid];
    [db close];
    return result;
}

- (BOOL)updatePlugServices:(JSmartPlug *)js
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET relay = ?, hsensor = ?, csensor = ?, nightlight = ?, hw_ver = ?, fw_ver = ? WHERE ip = ?",
            [NSNumber numberWithInt:js.relay],
            [NSNumber numberWithInt:js.hall_sensor],
            [NSNumber numberWithInt:js.co_sensor],
            [NSNumber numberWithInt:js.nightlight],
            js.hw_ver,
            js.fw_ver,
            js.ip];
    [db close];
    return result;
}

- (BOOL)updateDeviceVersions:(NSString *)idLocal model:(NSString *)model build_no:(int)build_no
 prot_ver:(int)prot_ver hw_ver:(NSString *)hw_ver fw_ver:(NSString *)fw_ver fw_date:(int)fw_date
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET model = ?, build_no = ?, prot_ver = ?, hw_ver = ?, fw_ver = ?, fw_date = ? WHERE sid = ?",
                   model,
                   [NSNumber numberWithInt:build_no],
                   [NSNumber numberWithInt:prot_ver],
                   hw_ver,
                   fw_ver,
                   [NSNumber numberWithInt:fw_date],
                   idLocal];
    [db close];
    return result;
}

- (BOOL)updatePlugIP:(NSString *)name ip:(NSString *)ip
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET ip = ? WHERE name = ?",
                   ip, name];
    [db close];
    return result;
}

- (BOOL)updatePlugIcon:(NSString *)sid icon:(NSString *)icon
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET icon = ? WHERE sid = ?", icon, sid];
    [db close];
    return result;
}

- (BOOL)deActivatePlug:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET active = ? WHERE sid = ?",
                   [NSNumber numberWithInt:0], sid];
    [db close];
    return result;
}

- (BOOL)insertToken:(NSString *)token
{
    [db open];
    BOOL result = [db executeUpdate:@"INSERT INTO params (token) VALUES (?)", token];
    [db close];
    return result;
}

- (NSArray *)getToken
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM params"];
    NSMutableArray *tokens = [NSMutableArray new];
    while ([results next]) {
        NSString *token = [results stringForColumn:COLUMN_TOKEN];
        [tokens addObject:token];
    }
    [db close];
    return tokens;
}

- (NSArray *)getPlugData:(NSString *)ip
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE ip = ? AND active = 1", ip];
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
        plug.icon = [results stringForColumn:COLUMN_ICON];
        plug.givenName = [results stringForColumn:COLUMN_GIVEN_NAME];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        plug.snooze = [results intForColumn:COLUMN_SNOOZE];
        plug.led_snooze = [results intForColumn:COLUMN_LED_SNOOZE];
        plug.ir_snooze = [results intForColumn:COLUMN_IR_SNOOZE];
        [plugs addObject:plug];
    }
    [db close];
    return plugs;
}

- (NSArray *)getPlugDataByID:(NSString *)sid
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE sid = ?", sid];
    NSMutableArray *plugs = [NSMutableArray new];
    while ([results next]) {
        JSmartPlug *plug = [JSmartPlug new];
        plug.dbid = [results intForColumn:COLUMN_ID];
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
        plug.icon = [results stringForColumn:COLUMN_ICON];
        plug.givenName = [results stringForColumn:COLUMN_GIVEN_NAME];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        plug.snooze = [results intForColumn:COLUMN_SNOOZE];
        plug.led_snooze = [results intForColumn:COLUMN_LED_SNOOZE];
        plug.ir_snooze = [results intForColumn:COLUMN_IR_SNOOZE];
        [plugs addObject:plug];
    }
    [db close];
    return plugs;
}

- (NSArray *)getPlugDataByName:(NSString *)name
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE name = ?", name];
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
        plug.icon = [results stringForColumn:COLUMN_ICON];
        plug.givenName = [results stringForColumn:COLUMN_GIVEN_NAME];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        plug.snooze = [results intForColumn:COLUMN_SNOOZE];
        plug.led_snooze = [results intForColumn:COLUMN_LED_SNOOZE];
        plug.ir_snooze = [results intForColumn:COLUMN_IR_SNOOZE];
        [plugs addObject:plug];
    }
    [db close];
    return plugs;
}

- (NSArray *)getPlugData
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE active = 1"];
    NSMutableArray *plugs = [NSMutableArray new];
    while ([results next]) {
        JSmartPlug *plug = [JSmartPlug new];
        plug.dbid = [results intForColumn:COLUMN_ID];
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
        plug.icon = [results stringForColumn:COLUMN_ICON];
        plug.givenName = [results stringForColumn:COLUMN_GIVEN_NAME];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        plug.snooze = [results intForColumn:COLUMN_SNOOZE];
        plug.led_snooze = [results intForColumn:COLUMN_LED_SNOOZE];
        plug.ir_snooze = [results intForColumn:COLUMN_IR_SNOOZE];
        [plugs addObject:plug];
    }
    [db close];
    return plugs;
}

- (NSArray *)getNonActivePlugData
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM smartplugs WHERE active = 0"];
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
        plug.icon = [results stringForColumn:COLUMN_ICON];
        plug.givenName = [results stringForColumn:COLUMN_GIVEN_NAME];
        plug.active = [results intForColumn:COLUMN_ACTIVE];
        plug.notify_co = [results intForColumn:COLUMN_NOTIFY_CO];
        plug.notify_power = [results intForColumn:COLUMN_NOTIFY_POWER];
        plug.notify_timer = [results intForColumn:COLUMN_NOTIFY_TIMER];
        plug.snooze = [results intForColumn:COLUMN_SNOOZE];
        plug.led_snooze = [results intForColumn:COLUMN_LED_SNOOZE];
        plug.ir_snooze = [results intForColumn:COLUMN_IR_SNOOZE];
        [plugs addObject:plug];
    }
    [db close];
    return plugs;
}

- (BOOL)deletePlugData:(NSString *)sid
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM smartplugs WHERE sid = ?", sid];
    [db close];
    return result;
}

- (BOOL)deletePlugDataByID:(NSString *)mac
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM smartplugs WHERE sid = ?", mac];
    [db close];
    return result;
}

- (BOOL)updatePlugNameNotify:(NSString *)mac name:(NSString *)name notifyOnPowerOutage:(int)notifyOnPowerOutage notifyOnCoWarning:(int)notifyOnCoWarning notifyOnTimerActivated:(int)notifyOnTimerActivated icon:(NSString *)icon
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE smartplugs SET notify_power = ?, notify_co = ?, notify_timer = ?, given_name = ?, icon = ? WHERE sid = ?",
            [NSNumber numberWithInt:notifyOnPowerOutage],
            [NSNumber numberWithInt:notifyOnCoWarning],
            [NSNumber numberWithInt:notifyOnTimerActivated],
            name,
            icon,
            mac];
    [db close];
    return result;
}

- (BOOL)deletePlugs
{
    BOOL result;
    [db open];
    result = [db executeUpdate:@"DELETE FROM smartplugs WHERE active = 1"];
    [db close];
    return result;
}

- (BOOL)deleteNonActivePlug:(NSString *)name
{
    BOOL result;
    [db open];
    if ([name isEqualToString:@"all"]) {
        result = [db executeUpdate:@"DELETE FROM smartplugs WHERE active = ?", [NSNumber numberWithInt:0]];
    } else {
        result = [db executeUpdate:@"DELETE FROM smartplugs WHERE name = ? AND active = ?", name, [NSNumber numberWithInt:0]];
    }
    [db close];
    return result;
}

- (BOOL)deleteAlarmData:(int)id
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM alarms WHERE _id = ?", [NSNumber numberWithInt:id]];
    [db close];
    return result;
}

- (BOOL)removeAlarms:(NSString *)mac
{
    [db open];
    BOOL result = [db executeUpdate:@"DELETE FROM alarms WHERE device_id = ?", mac];
    [db close];
    return result;
}

- (BOOL)insertAlarm:(Alarm *)a
{
    [db open];
    BOOL result = [db executeUpdate:@"INSERT INTO alarms (device_id, service_id, dow, init_hour, init_minutes, end_hour, end_minutes, snooze, init_ir, end_ir) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            a.device_id, [NSNumber numberWithInt:a.service_id], [NSNumber numberWithInt:a.dow], [NSNumber numberWithInt:a.initial_hour], [NSNumber numberWithInt:a.initial_minute], [NSNumber numberWithInt:a.end_hour], [NSNumber numberWithInt:a.end_minute], [NSNumber numberWithInt:a.snooze], [NSNumber numberWithInt:a.init_ir], [NSNumber numberWithInt:a.end_ir]];
    [db close];
    return result;
}

- (BOOL)updateAlarm:(Alarm *)a
{
    [db open];
    BOOL result = [db executeUpdate:@"UPDATE alarms SET device_id = ?, service_id = ?, dow = ?, init_hour = ?, init_minutes = ?, end_hour = ?, end_minutes = ?, snooze = ?, init_ir = ?, end_ir = ? WHERE _id = ?",
            a.device_id,
            [NSNumber numberWithInt:a.service_id],
            [NSNumber numberWithInt:a.dow],
            [NSNumber numberWithInt:a.initial_hour],
            [NSNumber numberWithInt:a.initial_minute],
            [NSNumber numberWithInt:a.end_hour],
            [NSNumber numberWithInt:a.end_minute],
            [NSNumber numberWithInt:a.snooze],
            [NSNumber numberWithInt:a.init_ir],
            [NSNumber numberWithInt:a.end_ir],
            [NSNumber numberWithInt:a.alarm_id]];
    [db close];
    return result;
}

- (NSArray *)getAlarmDataById:(int)alarmId
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM alarms WHERE _id = ?", [NSNumber numberWithInt:alarmId]];
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
    [db close];
    return alarms;
}

- (NSArray *)getAlarmDataByDevice:(NSString *)deviceId
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM alarms WHERE device_id = ?", deviceId];
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
    [db close];
    return alarms;
}

- (NSArray *)getAlarmDataByDeviceAndService:(NSString *)deviceId serviceId:(int)serviceId
{
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT * FROM alarms WHERE device_id = ? AND service_id = ?", deviceId, [NSNumber numberWithInt:serviceId]];
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
    [db close];
    return alarms;
}

@end
