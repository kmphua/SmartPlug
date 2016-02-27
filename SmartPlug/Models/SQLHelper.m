//
//  SQLHelper.m
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "SQLHelper.h"

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

@implementation SQLHelper
{
    sqlite3 *database;
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
        
        if (sqlite3_open([dbPath UTF8String], &database) != SQLITE_OK) {
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

- (bool)executeQuery:(NSString *)sql statement:(sqlite3_stmt **)statement
{
    const char *sql_stmt = [sql UTF8String];
    return sqlite3_prepare_v2(database, sql_stmt,
                              -1, statement, NULL) == SQLITE_OK;
}

- (bool)executeCommand:(NSString *)sql
{
    sqlite3_stmt *statement;
    const char *sql_stmt = [sql UTF8String];
    if(sqlite3_prepare_v2(database, sql_stmt,
                          -1, &statement, NULL) == SQLITE_OK) {
        bool done = sqlite3_step(statement) == SQLITE_DONE;
        sqlite3_finalize(statement);
        return done;
    }
    return false;
}


public MySQLHelper(Context context) {
    super(context, DATABASE_NAME, null, DATABASE_VERSION);
}

@Override
public void onCreate(SQLiteDatabase database) {
    database.execSQL(TABLE_CREATE_SMARTPLUG);
    database.execSQL(TABLE_CREATE_ALARM);
    database.execSQL(TABLE_CREATE_PARAMS);
    database.execSQL(TABLE_CREATE_IRCODE);
    database.execSQL(TABLE_CREATE_IRGROUPS);
    database.execSQL(TABLE_CREATE_ICONS);
}

@Override
public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
    Log.w(MySQLHelper.class.getName(),
          "Upgrading database from version " + oldVersion + " to "
          + newVersion + ", which will destroy all old data");
    db.execSQL("DROP TABLE IF EXISTS " + TABLE_SMARTPLUGS);
    onCreate(db);
}

public boolean insertIcons(String url, int size){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_URL, url);
    cv.put(COLUMN_SIZE, size);
    try {
        db.insert(TABLE_ICONS, null, cv);
    } catch (Exception e){
        Log.v("MySQLHelper", "DUPLICATED FIELD");
    }
    return true;
}

public Cursor getIcons(){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res = db.rawQuery("select * from "+ TABLE_ICONS, null);
    return res;
}

public boolean insertIRGroup(String desc, String icon, int position){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_NAME, desc);
    cv.put(COLUMN_ICON, icon);
    cv.put(COLUMN_POSITION, position);
    db.insert(TABLE_IRGROUPS, null, cv);
    return true;
}

public Cursor getIRGroups(){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_IRGROUPS, null);
    return res;
}

public boolean deleteIRGroup(int id){
    SQLiteDatabase db = this.getReadableDatabase();
    boolean toreturn = db.delete(TABLE_IRGROUPS, COLUMN_ID+" = "+id, null) > 0;
    if (toreturn){
        if(deleteIRCodes(id)){
            toreturn = true;
        } else {
            toreturn = false;
        }
    }
    return toreturn;
}

public boolean deleteIRCodes(int groupid){
    SQLiteDatabase db = this.getReadableDatabase();
    boolean toreturn = db.delete(TABLE_IRCODES, COLUMN_GROUPID+" = "+groupid, null) > 0;
    return toreturn;
}

public boolean deleteIRCode(int id){
    SQLiteDatabase db = this.getReadableDatabase();
    boolean toreturn = db.delete(TABLE_IRCODES, COLUMN_ID+" = "+id, null) > 0;
    return toreturn;
}

public Cursor getIRGroups(int id){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_IRGROUPS + " where " + COLUMN_ID + " = " + id, null);
    return res;
}

public boolean insertIRCodes(int gid, String name, int filename, String icon, String mac){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_GROUPID, gid);
    cv.put(COLUMN_NAME, name);
    cv.put(COLUMN_FILENAME, filename);
    cv.put(COLUMN_ICON, icon);
    cv.put(COLUMN_MAC, mac);
    db.insert(TABLE_IRCODES, null, cv);
    return true;
}

public Cursor getIRCodes(){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_IRCODES, null);
    return res;
}

public Cursor getIRCodesByGroup(int id){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_IRCODES +" where "+COLUMN_GROUPID+" = "+id, null);
    return res;
}

public boolean insertPlug (String name, String sid, String ip)
{
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues contentValues = new ContentValues();
    contentValues.put(COLUMN_NAME, name);
    contentValues.put(COLUMN_SID, sid);
    contentValues.put(COLUMN_IP, ip);
    contentValues.put(COLUMN_SERVER, "undefined");
    contentValues.put(COLUMN_ACTIVE, 1);
    db.insert(TABLE_SMARTPLUGS, null, contentValues);
    return true;
}

public boolean insertPlug (JSmartPlug js, int active)
{
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues contentValues = new ContentValues();
    contentValues.put(COLUMN_NAME, js.getName());
    contentValues.put(COLUMN_SID, js.getId());
    contentValues.put(COLUMN_IP, js.getIp());
    contentValues.put(COLUMN_MODEL, js.getModel());
    contentValues.put(COLUMN_BUILD_NO, js.getBuildno());
    contentValues.put(COLUMN_PROT_VER, js.getProt_ver());
    contentValues.put(COLUMN_HW_VER, js.getHw_ver());
    contentValues.put(COLUMN_FW_VER, js.getFw_ver());
    contentValues.put(COLUMN_FW_DATE, js.getFw_date());
    contentValues.put(COLUMN_FLAG, js.getFlag());
    contentValues.put(COLUMN_RELAY, js.getRelay());
    contentValues.put(COLUMN_HSENSOR, js.getHall_sensor());
    contentValues.put(COLUMN_CSENSOR, js.getCo_sensor());
    contentValues.put(COLUMN_NIGHTLIGHT, js.getNightlight());
    contentValues.put(COLUMN_ACTIVE, active);
    db.insert(TABLE_SMARTPLUGS, null, contentValues);
    return true;
}

public boolean updatePlugID(String mac, String ip){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_SID, mac);
    String filter = COLUMN_IP+"='"+ip+"'";
    db.update(TABLE_SMARTPLUGS, cv, filter, null);
    return true;
}

public boolean updatePlugName(String data, String id){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_GIVEN_NAME, data);
    String filter = COLUMN_SID+" = '"+id+"'";
    db.update(TABLE_SMARTPLUGS, cv, filter, null);
    return true;
}

public boolean updatePlugNightlightService(int data, String id){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_NIGHTLIGHT, data);
    String filter = COLUMN_SID+" = '"+id+"'";
    db.update(TABLE_SMARTPLUGS, cv, filter, null);
    return true;
}

public boolean updatePlugCoSensorService(int data, String id){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_CSENSOR, data);
    String filter = COLUMN_SID+" = '"+id+"'";
    db.update(TABLE_SMARTPLUGS, cv, filter, null);
    return true;
}

public boolean updatePlugHallSensorService(int data, String id){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_HSENSOR, data);
    String filter = COLUMN_SID+" = '"+id+"'";
    db.update(TABLE_SMARTPLUGS, cv, filter, null);
    return true;
}

public boolean updatePlugRelayService(int data, String id){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_RELAY, data);
    String filter = COLUMN_SID+" = '"+id+"'";
    db.update(TABLE_SMARTPLUGS, cv, filter, null);
    return true;
}

public boolean updatePlugServicesByIP(JSmartPlug js){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues args = new ContentValues();
    args.put(COLUMN_RELAY, js.getRelay());
    args.put(COLUMN_HSENSOR, js.getHall_sensor());
    args.put(COLUMN_CSENSOR, js.getCo_sensor());
    args.put(COLUMN_NIGHTLIGHT, js.getNightlight());
    args.put(COLUMN_HW_VER, js.getHw_ver());
    args.put(COLUMN_FW_VER, js.getFw_ver());
    String strFilter = COLUMN_IP + " = '" + js.getIp() + "'";
    db.update(TABLE_SMARTPLUGS, args, strFilter, null);
    return true;
}

public boolean updatePlugServicesByID(JSmartPlug js){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues args = new ContentValues();
    args.put(COLUMN_RELAY, js.getRelay());
    args.put(COLUMN_HSENSOR, js.getHall_sensor());
    args.put(COLUMN_CSENSOR, js.getCo_sensor());
    args.put(COLUMN_NIGHTLIGHT, js.getNightlight());
    args.put(COLUMN_HW_VER, js.getHw_ver());
    args.put(COLUMN_FW_VER, js.getFw_ver());
    String strFilter = COLUMN_SID + " = '" + js.getId() + "'";
    if(db.update(TABLE_SMARTPLUGS, args, strFilter, null)==1){
        System.out.println("SERVICE UPDATED SUCCESSFULLY");
    }
    return true;
}

public boolean updatePlugIP(String name, String ip, String mac){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_IP, ip);
    db.update(TABLE_SMARTPLUGS, cv, COLUMN_NAME+"='"+name+"'", null);
    return true;
}

public boolean updatePlugRelay(String id, int relay){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues args = new ContentValues();
    args.put(COLUMN_RELAY, relay);
    String strFilter = COLUMN_SID+" = '" + id +"'";
    db.update(TABLE_SMARTPLUGS, args, strFilter, null);
    return true;
}

public boolean updatePlugNightlight(String id, int nl){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues args = new ContentValues();
    args.put(COLUMN_NIGHTLIGHT, nl);
    String strFilter = COLUMN_SID+" = '" + id +"'";
    db.update(TABLE_SMARTPLUGS, args, strFilter, null);
    return true;
}

public boolean activatePlug(String sid){
    SQLiteDatabase db = this.getWritableDatabase();
    String strFilter = COLUMN_SID+" = '" + sid +"'";
    ContentValues args = new ContentValues();
    args.put(COLUMN_ACTIVE, 1);
    db.update(TABLE_SMARTPLUGS, args, strFilter, null);
    return true;
}

public boolean insertToken (String token){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues contentValues = new ContentValues();
    contentValues.put(COLUMN_TOKEN, token);
    if(db.insert(TABLE_PARAMS, null, contentValues) == 1){
        return true;
    } else {
        return false;
    }
}

public Cursor getToken(){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_PARAMS, null);
    return res;
}

public boolean removePlugsIP(){
    SQLiteDatabase db = this.getReadableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_IP, "");
    db.update(TABLE_SMARTPLUGS, cv , null, null);
    return true;
}

public boolean removePlugIP(String serviceName){
    SQLiteDatabase db = this.getReadableDatabase();
    db.rawQuery("update " + TABLE_SMARTPLUGS + " set " + COLUMN_IP + " = '0'", null);
    return true;
}

public boolean updatePlugIP(String name, String ip){
    SQLiteDatabase db = this.getReadableDatabase();
    String whereclause = COLUMN_NAME+"='"+name+"'";
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_IP, ip);
    db.update(TABLE_SMARTPLUGS, cv, whereclause, null);
    return true;
}

public Cursor getPlugData(String ip){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_SMARTPLUGS + " where " + COLUMN_IP + " = '" + ip + "' and active = 1", null);
    return res;
}

public Cursor getPlugDataByID(String id){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_SMARTPLUGS + " where " + COLUMN_SID + " = '" + id + "' and active = 1", null);
    return res;
}

public Cursor getPlugDataByName(String name){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_SMARTPLUGS + " where "+COLUMN_NAME+" = '" + name + "' and active = 1", null);
    return res;
}

public Cursor getPlugData(){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_SMARTPLUGS + " where active = 1", null);
    return res;
}

public Cursor getNonActivePlugData(){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_SMARTPLUGS + " where active = 0", null);
    return res;
}

public boolean deletePlugData(String ip){
    SQLiteDatabase db = this.getWritableDatabase();
    boolean toreturn = db.delete(TABLE_SMARTPLUGS, COLUMN_IP+"='"+ip+"'", null) > 0;
    return toreturn;
}

public boolean deletePlugDataByID(String mac){
    SQLiteDatabase db = this.getWritableDatabase();
    boolean toreturn = db.delete(TABLE_SMARTPLUGS, COLUMN_SID+"='"+mac+"'", null) > 0;
    return toreturn;
}

public boolean updatePlugNameNotify(String mac, String name, int notify_on_power_outage, int notify_on_co_warning, int notify_on_timer_activated, String icon){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues cv = new ContentValues();
    cv.put(COLUMN_NOTIFY_POWER, notify_on_power_outage);
    cv.put(COLUMN_NOTIFY_CO, notify_on_co_warning);
    cv.put(COLUMN_NOTIFY_TIMER, notify_on_timer_activated);
    cv.put(COLUMN_GIVEN_NAME, name);
    cv.put(COLUMN_ICON, icon);
    if(mac != null) {
        db.update(TABLE_SMARTPLUGS, cv, COLUMN_SID + "='" + mac + "'", null);
        return true;
    } else {
        return false;
    }
}

public boolean deleteNonActivePlug(String name){
    SQLiteDatabase db = this.getWritableDatabase();
    if(name.equals("all")){
        db.delete(TABLE_SMARTPLUGS, COLUMN_ACTIVE + " = 0", null);
    } else {
        db.delete(TABLE_SMARTPLUGS, COLUMN_NAME + " = '" + name + "' AND " + COLUMN_ACTIVE + " = 0", null);
    }
    return true;
}

public boolean deleteAlarmData(int id){
    SQLiteDatabase db = this.getReadableDatabase();
    boolean toreturn = db.delete(TABLE_ALARMS, COLUMN_ID+" = "+id, null) > 0;
    return toreturn;
}

public boolean insertAlarm (Alarm a)
{
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues contentValues = new ContentValues();
    contentValues.put(COLUMN_DEVICE_ID, a.getDevice_id());
    contentValues.put(COLUMN_SERVICE_ID, a.getService_id());
    contentValues.put(COLUMN_DOW, a.getDow());
    contentValues.put(COLUMN_INIT_HOUR, a.getInit_hour());
    contentValues.put(COLUMN_INIT_MINUTES, a.getInit_minute());
    contentValues.put(COLUMN_END_HOUR, a.getEnd_hour());
    contentValues.put(COLUMN_END_MINUTES, a.getEnd_minute());
    contentValues.put(COLUMN_SNOOZE, a.getSnooze());
    db.insert(TABLE_ALARMS, null, contentValues);
    return true;
}

public boolean updateAlarm(Alarm a){
    SQLiteDatabase db = this.getWritableDatabase();
    ContentValues contentValues = new ContentValues();
    contentValues.put(COLUMN_DEVICE_ID, a.getDevice_id());
    contentValues.put(COLUMN_SERVICE_ID, a.getService_id());
    contentValues.put(COLUMN_DOW, a.getDow());
    contentValues.put(COLUMN_INIT_HOUR, a.getInit_hour());
    contentValues.put(COLUMN_INIT_MINUTES, a.getInit_minute());
    contentValues.put(COLUMN_END_HOUR, a.getEnd_hour());
    contentValues.put(COLUMN_END_MINUTES, a.getEnd_minute());
    contentValues.put(COLUMN_SNOOZE, a.getSnooze());
    db.update(TABLE_ALARMS, contentValues, COLUMN_ID + " = "+ a.getAlarm_id(), null);
    return true;
}

public Cursor getAlarmData(int alarm_id){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_ALARMS + " where "+COLUMN_ID+" ='" + alarm_id + "'", null);
    return res;
}

public Cursor getAlarmData(String device_id){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_ALARMS + " where "+COLUMN_DEVICE_ID+" ='" + device_id + "'", null);
    return res;
}

public Cursor getAlarmData(String device_id, int service_id){
    SQLiteDatabase db = this.getReadableDatabase();
    Cursor res =  db.rawQuery("select * from " + TABLE_ALARMS + " where "+COLUMN_DEVICE_ID+" = '" + device_id + "' and "+COLUMN_SERVICE_ID+" = "+service_id, null);
    return res;
}





@end
