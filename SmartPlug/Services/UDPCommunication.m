//
//  UDPCommunication.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/25/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "UDPCommunication.h"
#import "GCDAsyncUdpSocket.h"
#include <arpa/inet.h>
#import "SQLHelper.h"
#import "NSMutableArray+QueueStack.h"

#define MAX_UDP_DATAGRAM_LEN        128
#define UDP_SERVER_PORT             20004
#define UDP_TESTING_PORT            20005

@interface QueueItem : NSObject  {
}

@property unsigned int msgID;
@property int serviceID;
@property int action;
@property NSString *macID;
@property bool shouldRun;

@end

@implementation QueueItem {
    
}
@end


@implementation Command

@end

@interface UDPCommunication()<GCDAsyncUdpSocketDelegate, WebServiceDelegate>
{
    uint8_t lMsg[MAX_UDP_DATAGRAM_LEN];
    uint8_t hMsg[14];
    uint8_t irHeader[15];
    uint8_t timerHeader[20];
    uint8_t timer[26];
    uint8_t rMsg[14];
    uint8_t sMsg[24];
    uint8_t iMsg[22];
    uint8_t kMsg[46];
    uint8_t ir[128];
    uint8_t ir2[1];
    uint8_t timers[512];
    uint32_t previous_msgid;
    BOOL process_data;
    short code;
    int IRFlag;
    int IRSendFlag;
    int irCode;
    int sendFlag;
    
    GCDAsyncUdpSocket *udpSocket;
    BOOL isRunning;
    
    uint32_t mLastMsgID;
    NSMutableDictionary *mQueuedCommands;
    
    NSMutableDictionary *mSetStatusQueue;
}

@end

@implementation UDPCommunication

static UDPCommunication *instance;

+ (UDPCommunication *)getInstance
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
        previous_msgid = 0;
        process_data = false;
        code = 1;
        IRFlag = 0;
        IRSendFlag = 0;
        irCode = 0;
        _IRCodes = [NSMutableArray new];
        _js = [JSmartPlug new];
        mLastMsgID = arc4random();
        mQueuedCommands = [NSMutableDictionary new];
        mSetStatusQueue = [NSMutableDictionary new];
    }
    return self;
}
 
- (void)sendUDP:(Command *)cmd data:(NSData *)data
{
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    if (!cmd) {
        NSLog(@"sendUDP: null command!");
        return;
    }
    if (!data) {
        NSLog(@"sendUDP: null data!");
        return;
    }

    NSLog(@"sendUDP: MAC = %@, msgID = %d", cmd.macID, cmd.msgID);
    NSString *ip = [[SQLHelper getInstance] getPlugIP:cmd.macID];
    if (ip && ip.length>0) {
        [self addCommand:cmd];
        [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:0];
        NSLog(@"UDP PACKET SENT");
    } else {
        NSLog(@"sendUDP: NULL IP!!!");
    }
}

//==================================================================
#pragma mark - GCDAsyncUdpSocketDelegate
//==================================================================

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSLog(@"Connected to UDP address %@", address);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"Sent UDP data with tag %ld", tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    //Do something with receive data
    NSString *ipAddress = [Global convertIpAddressToString:address];
    if (self.delegate) {
        [self.delegate didReceiveData:data fromAddress:ipAddress];
    }
}

//==================================================================
#pragma mark - Private methods
//==================================================================

- (void)addCommand:(Command *)command
{
    /*
    // Check to see if command queue exists for key
    NSMutableArray *commandQueue = [mQueuedCommands objectForKey:command.macID];
    if (commandQueue) {
        // Add command to queue
        [commandQueue queuePush:command];
    } else {
        // Does not exist, create one
        commandQueue = [NSMutableArray new];
        [commandQueue queuePush:command];
    }
     */
    
    [mQueuedCommands setObject:command forKey:command.macID];
}

- (Command *)dequeueCommandByIp:(NSString *)ip msgID:(uint32_t)msgID
{
    NSString *mac = [[SQLHelper getInstance] getPlugMacFromIP:ip];
    if (!mac) {
        NSLog(@"dequeueCommandByIp: NULL MAC!!!");
        return nil;
    }
    
    // convert ia to string
    return [self dequeueCommand:mac msgID:msgID];
}

- (Command *)dequeueCommand:(NSString *)macID msgID:(uint32_t)msgID
{
    if (!macID) {
        NSLog(@"dequeueCommand: NULL macID!!!");
        return nil;
    }

    Command *cmd = [mQueuedCommands objectForKey:macID];
    if (!cmd) {
        NSLog(@"dequeueCommand: No commands!");
        return nil;
    }
    
    if( cmd.msgID != msgID ) {
        NSLog(@"dequeueCommand: No matching msgID! (Expected %d, but queued ID=%d)", msgID, cmd.msgID);
        return nil;
    }

    /*
    NSMutableArray *commandQueue = [mQueuedCommands objectForKey:macID];
    if (!commandQueue) {
        NSLog(@"dequeueCommand: No commands!");
        return nil;
    }
    
    Command *cmd = [commandQueue queuePop];
    if( cmd.msgID != msgID ) {
        NSLog(@"dequeueCommand: No matching msgID!");
        return nil;
    }
     */
    
    return cmd;
}

//==================================================================
#pragma mark - Public methods
//==================================================================

- (BOOL)delayTimer:(NSString *)macId snooze:(int)snooze protocol:(int)protocol serviceId:(int)serviceId send:(int)send
{
    Command *cmd = nil;
    if (protocol == PROTOCOL_HTTP) {
        [self generate_header_http:UDP_CMD_DELAY_TIMER];
    } else {
        cmd = [self generate_header:macId command:UDP_CMD_DELAY_TIMER];
    }
    
    uint8_t delayT[22];
    memset(delayT, 0, sizeof(delayT));
    for (int i = 0; i < 14; i++) {
        delayT[i] = hMsg[i];
    }
    
    delayT[17] = (uint8_t) (serviceId & 0xff);
    delayT[16] = (uint8_t) ((serviceId >> 8) & 0xff);
    delayT[15] = (uint8_t) ((serviceId >> 16) & 0xff);
    delayT[14] = (uint8_t) ((serviceId >> 24) & 0xff);
    
    delayT[21] = (uint8_t) (snooze & 0xff);
    delayT[20] = (uint8_t) ((snooze >> 8) & 0xff);
    delayT[19] = (uint8_t) ((snooze >> 16) & 0xff);
    delayT[18] = (uint8_t) ((snooze >> 24) & 0xff);
    
    if (protocol == PROTOCOL_HTTP) {
        WebService *ws = [WebService new];
        ws.delegate = self;
        NSData *data = [NSData dataWithBytes:delayT length:sizeof(delayT)];
        [ws setTimerDelay:g_UserToken lang:[Global getCurrentLang] devId:macId send:send data:data];
    } else if (protocol == PROTOCOL_UDP) {
        NSData *data = [NSData dataWithBytes:delayT length:sizeof(delayT)];
        [self sendUDP:cmd data:data];
    }
    return YES;
}

- (BOOL)queryDevices:(NSString *)macId command:(short)command
{
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    Command *cmd = [self generate_header:macId command:command];
    
    memset(rMsg, 0, sizeof(rMsg));
    for(int i=0; i<14;i++){
        rMsg[i] = hMsg[i];
    }
    
    NSData *data = [NSData dataWithBytes:rMsg length:sizeof(rMsg)];
    [self sendUDP:cmd data:data];
    return YES;
}

- (BOOL)queryDevicesByIp:(NSString *)ip command:(short)command
{
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    Command *cmd = [self generate_header:ip command:command];
    
    memset(rMsg, 0, sizeof(rMsg));
    for(int i=0; i<14;i++){
        rMsg[i] = hMsg[i];
    }
    
    NSData *data = [NSData dataWithBytes:rMsg length:sizeof(rMsg)];
    
    [self addCommand:cmd];
    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:0];
    NSLog(@"UDP PACKET SENT");
    return YES;
}

- (BOOL)sendIRMode:(NSString *)macId
{
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    Command *cmd = [self generate_header:macId command:UDP_CMD_ADV_DEVICE_SETTINGS];
    
    memset(iMsg, 0, sizeof(iMsg));
    for (int i = 0; i < 14; i++){
        iMsg[i] = hMsg[i];
    }
    int service_id = 0xD1000003;
    iMsg[14] = (uint8_t)(service_id & 0xff);
    iMsg[15] = (uint8_t)((service_id >> 8) & 0xff);
    iMsg[16] = (uint8_t)((service_id >> 16) & 0xff);
    iMsg[17] = (uint8_t)((service_id >> 24) & 0xff);
    int flag = 0x00000000;
    iMsg[18] = (uint8_t)(flag & 0xff);
    iMsg[19] = (uint8_t)((flag >> 8) & 0xff);
    iMsg[20] = (uint8_t)((flag >> 16) & 0xff);
    iMsg[21] = (uint8_t)((flag >> 24) & 0xff);
    
    NSData *data = [NSData dataWithBytes:iMsg length:sizeof(iMsg)];
    [self sendUDP:cmd data:data];
    return YES;
}

- (BOOL)cancelIRMode:(NSString *)macId
{
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    Command *cmd = [self generate_header:macId command:UDP_CMD_ADV_DEVICE_SETTINGS];
    
    memset(iMsg, 0, sizeof(iMsg));
    for (int i = 0; i < 14; i++){
        iMsg[i] = hMsg[i];
    }
    int service_id = 0xD1000004;
    iMsg[14] = (uint8_t)(service_id & 0xff);
    iMsg[15] = (uint8_t)((service_id >> 8) & 0xff);
    iMsg[16] = (uint8_t)((service_id >> 16) & 0xff);
    iMsg[17] = (uint8_t)((service_id >> 24) & 0xff);
    int flag = 0x00000000;
    iMsg[18] = (uint8_t)(flag & 0xff);
    iMsg[19] = (uint8_t)((flag >> 8) & 0xff);
    iMsg[20] = (uint8_t)((flag >> 16) & 0xff);
    iMsg[21] = (uint8_t)((flag >> 24) & 0xff);
    
    NSData *data = [NSData dataWithBytes:iMsg length:sizeof(iMsg)];
    [self sendUDP:cmd data:data];
    return YES;
}

- (BOOL)sendOTACommand:(NSString *)macId
{
    Command *cmd = [self generate_header:macId command:0x000F];
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    NSData *data = [NSData dataWithBytes:hMsg length:sizeof(hMsg)];
    [self sendUDP:cmd data:data];
    NSLog(@"OTA COMMAND SENT");
    return YES;
}

- (BOOL)sendReformatCommand:(NSString *)macId
{
    Command *cmd = [self generate_header:macId command:0x010F];
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    NSData *data = [NSData dataWithBytes:hMsg length:sizeof(hMsg)];
    [self sendUDP:cmd data:data];
    NSLog(@"REFORMAT COMMAND SENT");
    return YES;
}

- (BOOL)sendResetCommand:(NSString *)macId
{
    Command *cmd = [self generate_header:macId command:0x0FFF];
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    NSData *data = [NSData dataWithBytes:hMsg length:sizeof(hMsg)];
    [self sendUDP:cmd data:data];
    NSLog(@"RESET COMMAND SENT");
    return YES;
}

- (BOOL)sendIRFileName:(NSString *)macId filename:(int)filename
{
    [self sendIRHeader:macId filename:filename];
    return YES;
}

- (void)sendIRHeader:(NSString *)macId filename:(int)filename
{
    Command *cmd = [self generate_header:macId command:UDP_CMD_GET_DEVICE_TIMERS];
    
    memset(irHeader, 0, sizeof(irHeader));
    for(int i = 0; i < sizeof(hMsg); i++){
        irHeader[i] = hMsg[i];
    }
    irHeader[14] = (uint8_t)filename;
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    NSData *data = [NSData dataWithBytes:irHeader length:sizeof(irHeader)];
    [self sendUDP:cmd data:data];
    NSLog(@"IR HEADERS SENT");
}

- (BOOL)sendTimers:(NSString *)macId
{
    Command *cmd = [self generate_header:macId command:(short)UDP_CMD_SET_DEVICE_TIMERS];
    
    int i;
    memset(timers, 0, sizeof(timers));
    for(i = 0; i < sizeof(hMsg); i++){
        timers[i] = hMsg[i];
    }
    
    long time = (long)[[NSDate date] timeIntervalSince1970];
    
    timers[i++] = (uint8_t) ((time >> 24) & 0xff);
    timers[i++] = (uint8_t) ((time >> 16) & 0xff);
    timers[i++] = (uint8_t) ((time >> 8) & 0xff);
    timers[i++] = (uint8_t) (time & 0xff);

    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDevice:macId];
    if(alarms && alarms.count > 0) {
        for (Alarm *alarm in alarms) {
            int serviceId = alarm.service_id;
            if(serviceId == RELAY_SERVICE || serviceId == NIGHTLED_SERVICE || serviceId == IR_SERVICE) {
                timers[i++] = (uint8_t) ((serviceId >> 24) & 0xff);
                timers[i++] = (uint8_t) ((serviceId >> 16) & 0xff);
                timers[i++] = (uint8_t) ((serviceId >> 8) & 0xff);
                timers[i++] = (uint8_t) (serviceId & 0xff);
                timers[i++] = 0x01;
                int init_ir = alarm.init_ir;
                timers[i++] = (uint8_t)init_ir;
                int end_ir = alarm.end_ir;
                timers[i++] = (uint8_t)end_ir;
                int dow = alarm.dow;
                timers[i++] = (uint8_t) (dow & 0xff);
                int initHour = alarm.initial_hour;
                timers[i++] = (uint8_t) (initHour & 0xff);
                int initMin = alarm.initial_minute;
                timers[i++] = (uint8_t) (initMin & 0xff);
                int endHour = alarm.end_hour;
                timers[i++] = (uint8_t) (endHour & 0xff);
                int endMinu = alarm.end_minute;
                timers[i++] = (uint8_t) (endMinu & 0xff);
            }
        }
    } else {
        for (int ix = 0; ix < 11; ix++) {
            timers[i++] = 0;
        }
    }

    NSData *data = [NSData dataWithBytes:timers length:sizeof(timers)];
    [self sendUDP:cmd data:data];
    return true;
}

- (BOOL)sendTimersHTTP:(NSString *)macId send:(int)send
{
    BOOL toReturn = false;
    [self generate_header_http:UDP_CMD_SET_DEVICE_TIMERS];
    
    int i = 0;
    memset(timers, 0, sizeof(timers));
    for(i = 0; i < sizeof(hMsg); i++){
        timers[i] = hMsg[i];
    }
    
    long time = (long)[[NSDate date] timeIntervalSince1970];
    
    timers[i++] = (uint8_t) (time & 0xff);
    timers[i++] = (uint8_t) ((time >> 8) & 0xff);
    timers[i++] = (uint8_t) ((time >> 16) & 0xff);
    timers[i++] = (uint8_t) ((time >> 24) & 0xff);
    
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDevice:macId];
    if(alarms && alarms.count > 0) {
        for (Alarm *alarm in alarms) {
            int serviceId = alarm.service_id;
            if(serviceId == RELAY_SERVICE || serviceId == NIGHTLED_SERVICE || serviceId == IR_SERVICE) {
                
                timers[i++] = (uint8_t) ((serviceId >> 24) & 0xff);
                timers[i++] = (uint8_t) ((serviceId >> 16) & 0xff);
                timers[i++] = (uint8_t) ((serviceId >> 8) & 0xff);
                timers[i++] = (uint8_t) (serviceId & 0xff);
                timers[i++] = 0x01;
                int init_ir = alarm.init_ir;
                timers[i++] = (uint8_t)init_ir;
                int end_ir = alarm.end_ir;
                timers[i++] = (uint8_t)end_ir;                
                int dow = alarm.dow;
                timers[i++] = (uint8_t) (dow & 0xff);
                int initHour = alarm.initial_hour;
                timers[i++] = (uint8_t) (initHour & 0xff);
                int initMin = alarm.initial_minute;
                timers[i++] = (uint8_t) (initMin & 0xff);
                int endHour = alarm.end_hour;
                timers[i++] = (uint8_t) (endHour & 0xff);
                int endMinu = alarm.end_minute;
                timers[i++] = (uint8_t) (endMinu & 0xff);
            }
        }
    } else {
        NSLog(@"SENDING ALL ZERO TIMER");
        for(int x = 0; x < 12; x++){
            timers[i++] = 0;
        }
    }
    
    NSData *timerData = [NSData dataWithBytes:timers length:sizeof(timers)];
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:macId send:send data:timerData];
    
    return toReturn;
}

- (BOOL)sendTimers:(NSString *)macId protocol:(int)protocol
{
    BOOL toReturn = false;
    
    Command *cmd = nil;
    if (protocol == PROTOCOL_HTTP) {
        [self generate_header_http:UDP_CMD_SET_DEVICE_TIMERS];
    } else {
        cmd = [self generate_header:macId command:(short)UDP_CMD_SET_DEVICE_TIMERS];
    }

    memset(timer, 0, sizeof(timer));
    for(int i = 0; i < sizeof(hMsg); i++){
        timer[i] = hMsg[i];
    }
    
    //NSString *ip = g_DeviceIp;
    
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDevice:macId];
    if (alarms && alarms.count>0) {
        for (Alarm *alarm in alarms) {
            int serviceId = alarm.service_id;
            if (serviceId == RELAY_SERVICE || serviceId == NIGHTLED_SERVICE) {
                if(protocol == PROTOCOL_HTTP){
                    timer[17] = (uint8_t) (serviceId & 0xff);
                    timer[16] = (uint8_t) ((serviceId >> 8) & 0xff);
                    timer[15] = (uint8_t) ((serviceId >> 16) & 0xff);
                    timer[14] = (uint8_t) ((serviceId >> 24) & 0xff);
                    timer[18] = 0x01;
                    timer[19] = 0x01;
                    timer[20] = 0x00;
                    int dow = alarm.dow;
                    timer[21] = (uint8_t) (dow & 0xff);
                    int initHour = alarm.initial_hour;
                    timer[22] = (uint8_t) (initHour & 0xff);
                    int initMin = alarm.initial_minute;
                    timer[23] = (uint8_t) (initMin & 0xff);
                    int endHour = alarm.end_hour;
                    timer[24] = (uint8_t) (endHour & 0xff);
                    int endMinu = alarm.end_minute;
                    timer[25] = (uint8_t) (endMinu & 0xff);
                }
                
                if(protocol == PROTOCOL_UDP) {
                    timer[17] = (uint8_t) (serviceId & 0xff);
                    timer[16] = (uint8_t) ((serviceId >> 8) & 0xff);
                    timer[15] = (uint8_t) ((serviceId >> 16) & 0xff);
                    timer[14] = (uint8_t) ((serviceId >> 24) & 0xff);
                    timer[18] = 0x01;
                    timer[19] = 0x01;
                    timer[20] = 0x00;
                    int dow = alarm.dow;
                    timer[21] = (uint8_t) (dow & 0xff);
                    int initHour = alarm.initial_hour;
                    timer[22] = (uint8_t) (initHour & 0xff);
                    int initMin = alarm.initial_minute;
                    timer[23] = (uint8_t) (initMin & 0xff);
                    int endHour = alarm.end_hour;
                    timer[24] = (uint8_t) (endHour & 0xff);
                    int endMinu = alarm.end_minute;
                    timer[25] = (uint8_t) (endMinu & 0xff);
                }
            }
            
            NSData *data = [NSData dataWithBytes:timer length:sizeof(timer)];
            if(protocol == PROTOCOL_HTTP) {
                WebService *ws = [WebService new];
                ws.delegate = self;
                [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:macId send:sendFlag data:data];
            } else if(protocol == PROTOCOL_UDP) {
                //[self sendUDP:ip data:data];
            }
        }
    }

    return toReturn;
}

- (void) finishDeviceStatus : (uint32_t)msgID {
    
    NSNumber *key = [NSNumber numberWithUnsignedInt:msgID];
    
    QueueItem *item2 = [mSetStatusQueue objectForKey:key];
    if( item2==nil )
        return;
    
    item2.shouldRun = false;
    
    [mSetStatusQueue removeObjectForKey:key];

    if (item2.serviceID == RELAY_SERVICE) {
        [[SQLHelper getInstance] updatePlugRelayService:item2.action sid:item2.macID];
    }
    if (item2.serviceID == NIGHTLED_SERVICE) {
        [[SQLHelper getInstance] updatePlugNightlightService:item2.action sid:item2.macID];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil userInfo:nil];
}

- (BOOL)setDeviceStatus:(NSString *)macID serviceId:(int)serviceId action:(uint8_t)action
{
    Command *cmd = [self generate_header:macID command:(short)UDP_CMD_SET_DEVICE_STATUS];
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    memset(sMsg, 0, sizeof(sMsg));
    for(int i=0; i<14;i++){
        sMsg[i] = hMsg[i];
    }
    
    int service_id = serviceId;
    sMsg[14] = (uint8_t)(service_id & 0xff);
    sMsg[15] = (uint8_t)((service_id >> 8 ) & 0xff);
    sMsg[16] = (uint8_t)((service_id >> 16 ) & 0xff);
    sMsg[17] = (uint8_t)((service_id >> 24 ) & 0xff);
    uint8_t datatype = 0x01;
    sMsg[18] = datatype;
    uint8_t data = action;
    sMsg[19] = data;
    int terminator = 0x00000000;
    sMsg[20] = (uint8_t)(terminator & 0xff);
    sMsg[21] = (uint8_t)((terminator >> 8 ) & 0xff);
    sMsg[22] = (uint8_t)((terminator >> 16 ) & 0xff);
    sMsg[23] = (uint8_t)((terminator >> 24 ) & 0xff);
    
    QueueItem *item = [[QueueItem alloc] init];
    item.msgID = cmd.msgID;
    item.serviceID = serviceId;
    item.action = action;
    item.macID = macID;
    item.shouldRun = true;
    
    NSNumber *key = [NSNumber numberWithUnsignedInt:item.msgID];
    
    NSArray *queuedItems = [mSetStatusQueue allValues];
    for( QueueItem *queuedItem in queuedItems ) {
        if( [queuedItem.macID isEqualToString:macID] && queuedItem.serviceID==serviceId ) {
            queuedItem.shouldRun = false;
            [mSetStatusQueue removeObjectForKey:[NSNumber numberWithUnsignedInt:queuedItem.msgID]];
        }
    }
    
    [mSetStatusQueue setObject:item forKey:key];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if( !item.shouldRun )
            return;
        
        QueueItem *item2 = [mSetStatusQueue objectForKey:key];
        if( item2==nil )
            return;
        
        [mSetStatusQueue removeObjectForKey:key];
        
        // Set device status
        WebService *ws = [WebService new];
        ws.delegate = self;
        ws.serviceId = serviceId;
        ws.action = action;
        
        int header = 0x534D5254;
        uint8_t sMsg2[24];
        sMsg2[3] = (uint8_t)(header);
        sMsg2[2] = (uint8_t)((header >> 8 ));
        sMsg2[1] = (uint8_t)((header >> 16 ));
        sMsg2[0] = (uint8_t)((header >> 24 ));
        
        int msid = (int)(random()*4294967+1);
        sMsg2[7] = (uint8_t)(msid);
        sMsg2[6] = (uint8_t)((msid >> 8 ));
        sMsg2[5] = (uint8_t)((msid >> 16 ));
        sMsg2[4] = (uint8_t)((msid >> 24 ));
        int seq = 0x80000000;
        sMsg2[11] = (uint8_t)(seq);
        sMsg2[10] = (uint8_t)((seq >> 8 ));
        sMsg2[9] = (uint8_t)((seq >> 16 ));
        sMsg2[8] = (uint8_t)((seq >> 24 ));
        short command = 0x0008;
        sMsg2[13] = (uint8_t)(command);
        sMsg2[12] = (uint8_t)((command >> 8 ));
        //int serviceId = 0xD1000000;
        sMsg2[17] = (uint8_t)(serviceId);
        sMsg2[16] = (uint8_t)((serviceId >> 8 ));
        sMsg2[15] = (uint8_t)((serviceId >> 16 ));
        sMsg2[14] = (uint8_t)((serviceId >> 24 ));
        
        uint8_t datatype = 0x01;
        sMsg2[18] = datatype;
        uint8_t data = action;
        sMsg2[19] = data;
        int terminator = 0x00000000;
        sMsg2[23] = (uint8_t)(terminator & 0xff);
        sMsg2[22] = (uint8_t)((terminator >> 8 ) & 0xff);
        sMsg2[21] = (uint8_t)((terminator >> 16 ) & 0xff);
        sMsg2[20] = (uint8_t)((terminator >> 24 ) & 0xff);
        
        NSLog(@"Data length = %ld", sizeof(sMsg2));
        
        NSData *deviceData = [NSData dataWithBytes:sMsg2 length:sizeof(sMsg2)];
        
        [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:item2.macID send:0 data:deviceData];

    });
    
    NSData *udpData = [NSData dataWithBytes:sMsg length:sizeof(sMsg)];
    [self sendUDP:cmd data:udpData];
    return YES;
}

- (Command *)generate_header:(NSString *)macID command:(short)command
{
    Command *c = [Command new];
    c.macID = macID;
    c.command = command;
    
    int header = 0x534D5254;
    uint32_t msgid = c.msgID = (mLastMsgID++);
    int seq = 0x80000000;
    memset(hMsg, 0, sizeof(hMsg));
    hMsg[0] = (uint8_t) header;
    hMsg[1] = (uint8_t) (header >> 8);
    hMsg[2] = (uint8_t) (header >> 16);
    hMsg[3] = (uint8_t) (header >> 24);
    hMsg[4] = (uint8_t) msgid;
    hMsg[5] = (uint8_t) (msgid >> 8);
    hMsg[6] = (uint8_t) (msgid >> 16);
    hMsg[7] = (uint8_t) (msgid >> 24);
    hMsg[8] = (uint8_t) seq;
    hMsg[9] = (uint8_t) (seq >> 8);
    hMsg[10] = (uint8_t) (seq >> 16);
    hMsg[11] = (uint8_t) (seq >> 24);
    hMsg[12] = (uint8_t) c.command;
    hMsg[13] = (uint8_t) (c.command >> 8);
    
    return c;
}
         
- (void)generate_header_http:(short)command
{
    int header = 0x534D5254;
    memset(hMsg, 0, sizeof(hMsg));
    hMsg[3] = (uint8_t)(header);
    hMsg[2] = (uint8_t)((header >> 8 ));
    hMsg[1] = (uint8_t)((header >> 16 ));
    hMsg[0] = (uint8_t)((header >> 24 ));
    int msid = (mLastMsgID++);
    hMsg[7] = (uint8_t)(msid);
    hMsg[6] = (uint8_t)((msid >> 8 ));
    hMsg[5] = (uint8_t)((msid >> 16 ));
    hMsg[4] = (uint8_t)((msid >> 24 ));
    int seq = 0x80000000;
    hMsg[11] = (uint8_t)(seq);
    hMsg[10] = (uint8_t)((seq >> 8 ));
    hMsg[9] = (uint8_t)((seq >> 16 ));
    hMsg[8] = (uint8_t)((seq >> 24 ));
    hMsg[13] = (uint8_t)(command);
    hMsg[12] = (uint8_t)((command >> 8 ));
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName webservice:(WebService *)ws {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received data for %@: %@", resultName, dataString);
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *jsonArray = (NSArray *)jsonObject;
        NSLog(@"jsonArray - %@", jsonArray);
    } else {
        NSDictionary *jsonDict = (NSDictionary *)jsonObject;
        NSLog(@"jsonDict - %@", jsonDict);
        
        if ([resultName compare:WS_DEV_CTRL] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSLog(@"Devctrl success!");
                
                if (ws.serviceId == RELAY_SERVICE) {
                    [[SQLHelper getInstance] updatePlugRelayService:ws.action sid:ws.devId];
                }
                if (ws.serviceId == NIGHTLED_SERVICE) {
                    [[SQLHelper getInstance] updatePlugNightlightService:ws.action sid:ws.devId];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil userInfo:nil];
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Devctrl failed: %@", message);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVCTRL_ERROR object:nil userInfo:nil];
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName  webservice:(WebService *)ws{
    NSLog(@"Connect fail for %@", resultName);
}

@end
