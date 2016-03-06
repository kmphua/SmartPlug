//
//  UDPListenerService.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/30/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "UDPListenerService.h"
#import "GCDAsyncUdpSocket.h"
#include <arpa/inet.h>
#import "JSmartPlug.h"

#define MAX_UDP_DATAGRAM_LEN        128
#define UDP_SERVER_PORT             20004
#define UDP_TESTING_PORT            20005

#define PROTOCOL_HTTP               0
#define PROTOCOL_UDP                1

@interface UDPListenerService()<GCDAsyncUdpSocketDelegate, WebServiceDelegate>
{
    NSString* broadcastIP;
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
    uint8_t delatT[18];
    uint8_t ir2[2];
    int previous_msgid;
    BOOL process_data;
    short code;
    BOOL shouldRestartSocketListen;
    short command;
    JSmartPlug *js;
    int IRFlag;
    int IRSendFlag;
    int irCode;
    NSMutableArray *IRCodes;
}

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic) BOOL isRunning;

@end

@implementation UDPListenerService

static UDPListenerService *instance;

+ (UDPListenerService *)getInstance
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
        IRCodes = [NSMutableArray new];
        previous_msgid = 0;
        process_data = NO;
        code = 1;
        IRFlag = 0;
        IRSendFlag = 0;
        shouldRestartSocketListen = NO;
        IRFlag = 0;
        js = [JSmartPlug new];
    }
    return self;
}

- (BOOL)startUdpBroadcastListener
{
    if (_isRunning) {
        NSLog(@"Server already running!");
        return NO;
    }
    
    if (!_udpSocket) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    NSError *error = nil;
    if (![_udpSocket bindToPort:UDP_SERVER_PORT error:&error]) {
        NSLog(@"Error starting server (bind): %@", error);
        return NO;
    }
    if (![_udpSocket beginReceiving:&error]) {
        [_udpSocket close];
        NSLog(@"Error starting server (recv): %@", error);
        return NO;
    }
    
    NSLog(@"UDP server started on %@:%i",[_udpSocket localHost_IPv4],[_udpSocket localPort]);
    _isRunning = YES;
    return YES;
}

- (void)stopUdpBroadcastListener
{
    if (_isRunning) {
        [_udpSocket close];
        _udpSocket = nil;
        _isRunning = NO;
    }
}

- (void)sendUDP:(NSString *)ip data:(NSData *)data
{
    if (!_udpSocket) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    [_udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:0];
    NSLog(@"UDP sent %ld bytes to %@", data.length, ip);
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
    // Do something with receive data
    NSString *ipAddress = [Global convertIpAddressToString:address];
    NSLog(@"Received data %ld from address %@", data.length, ipAddress);
    
    // TODO: Use NSNotification to broadcast packets received
    memcpy(lMsg, [data bytes], data.length);
    
    [self process_headers];
    
    if(g_UdpCommand == UDP_CMD_ADV_DEVICE_SETTINGS){
        NSLog(@"Entering IR Mode");
        if(code == 0) {
            [self listenForIRFileName];
            code = 1;
        }
        g_UdpCommand = 0;   // Reset command after processing
    }
    
    if(g_UdpCommand == UDP_CMD_DEVICE_QUERY){
        if(code == 0){
            [self process_query_device_command];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      ipAddress, @"ip",
                                      js.sid, @"id",
                                      js.model, @"model",
                                      nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_INFO
                                                                object:self
                                                              userInfo:userInfo];
            
            code = 1;
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(g_UdpCommand == UDP_CMD_DELAY_TIMER){
        if(code == 0){
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:code] forKey:@"code"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SET_TIMER_DELAY
                                                                object:self
                                                              userInfo:userInfo];
            code = 1;
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(g_UdpCommand == UDP_CMD_SET_DEVICE_STATUS){
        if(code == 0){
            code = 1;
            NSLog(@"DEVICE STATUS CHANGED");
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_STATUS_CHANGED
                                                                object:self
                                                              userInfo:nil];
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(g_UdpCommand == UDP_CMD_GET_DEVICE_STATUS){
        if(code == 0){
            code = 1;
            [self process_get_device_status];
            [[SQLHelper getInstance] updatePlugServices:js];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI
                                                                object:self
                                                              userInfo:nil];
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(code == 0x1000 && process_data == true){
        NSLog(@"I GOT A BROADCAST");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_M1_UPDATE_UI
                                                            object:self
                                                          userInfo:nil];
        code = 1;
    }
}

//==================================================================
#pragma mark - Public methods
//==================================================================

- (BOOL)delayTimer:(int)seconds
{
    g_UdpCommand = UDP_CMD_DELAY_TIMER;
    NSString *ip = g_DeviceIp;
    if (ip != nil) {
        uint8_t delay[18];
        [self generate_header];
        for (int i = 0; i < 14; i++) {
            delay[i] = hMsg[i];
        }
        
        delay[14] = (uint8_t) (seconds & 0xff);
        delay[15] = (uint8_t) ((seconds >> 8) & 0xff);
        delay[16] = (uint8_t) ((seconds >> 16) & 0xff);
        delay[17] = (uint8_t) ((seconds >> 24) & 0xff);
        
        NSData *data = [NSData dataWithBytes:delay length:sizeof(delay)];
        [self sendUDP:ip data:data];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)listenForIRCodes
{
    /*
     NSData *data = [NSData dataWithBytes:ir length:sizeof(ir)];
     
     try {
     ds = new DatagramSocket(UDP_TESTING_PORT);
     ds.receive(dp);
     
     for(int i = 0; i < ir.length; i++){
     IRCodes.add((int)ir[i]);
     if(ir[i] == 0){
     IRFlag = 0;
     }
     }
     } catch (SocketException e) {
     e.printStackTrace();
     } catch (IOException e) {
     e.printStackTrace();
     } finally {
     if (ds != null) {
     ds.close();
     }
     }
     if(IRFlag == 1){
     listenForIRCodes();
     }
     */
    return YES;
}

- (BOOL)listenForIRFileName
{
    if (process_data == true) {
        IRFlag = 0;
        int name = lMsg[18];
        if(name >= 0) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:name] forKey:@"filename"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_IR_FILENAME
                                                                object:self
                                                              userInfo:userInfo];
        }
        
    }
    return true;
}

/*
- (BOOL)queryDevices:(NSString *)ip udpMsg_param:(short)udpMsg_param
{
    g_UdpCommand = udpMsg_param;
    
    [self generate_header];
    for(int i=0; i<14;i++){
        rMsg[i] = hMsg[i];
    }
    
    NSData *data = [NSData dataWithBytes:rMsg length:sizeof(rMsg)];
    [self sendUDP:ip data:data];
    return YES;
}

- (BOOL)sendIRMode
{
    NSString *ip = g_DeviceIp;
    g_UdpCommand = UDP_CMD_ADV_DEVICE_SETTINGS;
    
    [self generate_header];
    for (int i = 0; i < 14; i++){
        iMsg[i] = hMsg[i];
    }
    int service_id = 0x1D000003;
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
    [self sendUDP:ip data:data];
    return YES;
}

- (BOOL)sendIRFileName:(int)filename
{
    [self sendIRHeader:filename];
    return YES;
}

- (void)sendIRHeader:(int)filename
{
    NSString * ip = g_DeviceIp;
    g_UdpCommand = UDP_CMD_GET_DEVICE_TIMERS;
    [self generate_header];
    for(int i = 0; i < sizeof(hMsg); i++){
        irHeader[i] = hMsg[i];
    }
    irHeader[14] = (uint8_t)filename;
    
    NSData *data = [NSData dataWithBytes:irHeader length:sizeof(irHeader)];
    [self sendUDP:ip data:data];
    NSLog(@"IR HEADERS SENT");
}

- (BOOL)setDeviceTimers:(NSString *)devId
{
    BOOL result = true;
    NSString *ip = g_DeviceIp;
    BOOL headerOK = [self sendTimerHeaders:ip protocol:PROTOCOL_HTTP];
    BOOL timerOK = [self sendTimers:devId protocol:PROTOCOL_HTTP];
    BOOL termiOK = [self sendTimerTerminator:ip protocol:PROTOCOL_HTTP];
    if (!headerOK || !timerOK || !termiOK) {
        [self sendTimerHeaders:ip protocol:PROTOCOL_UDP];
        [self sendTimers:devId protocol:PROTOCOL_UDP];
        [self sendTimerTerminator:ip protocol:PROTOCOL_UDP];
    }
    return result;
}

- (BOOL)sendTimerTerminator:(NSString *)ip protocol:(int)protocol
{
    BOOL toReturn = false;
    g_UdpCommand = UDP_CMD_SET_DEVICE_TIMERS;
    
    if (protocol == PROTOCOL_HTTP) {
        [self generate_header_http];
    } else {
        [self generate_header];
    }
    for (int i = 0; i < sizeof(hMsg); i++) {
        timerHeader[i] = hMsg[i];
    }
    
    int end = 0x00000000;
    if (protocol == PROTOCOL_HTTP) {
        timerHeader[14] = (uint8_t) (end & 0xff);
        timerHeader[15] = (uint8_t) ((end >> 8) & 0xff);
        timerHeader[16] = (uint8_t) ((end >> 16) & 0xff);
        timerHeader[17] = (uint8_t) ((end >> 24) & 0xff);
    }
    if (protocol == PROTOCOL_UDP) {
        timerHeader[14] = (uint8_t) (end & 0xff);
        timerHeader[15] = (uint8_t) ((end >> 8) & 0xff);
        timerHeader[16] = (uint8_t) ((end >> 16) & 0xff);
        timerHeader[17] = (uint8_t) ((end >> 24) & 0xff);
    }
    
    NSData *data = [NSData dataWithBytes:timerHeader length:sizeof(timerHeader)];
    if(protocol == PROTOCOL_HTTP) {
        WebService *ws = [WebService new];
        ws.delegate = self;
        [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac data:data];
    } else if(protocol == PROTOCOL_UDP) {
        [self sendUDP:ip data:data];
    }
    return toReturn;
}

- (BOOL)sendTimerHeaders:(NSString *)ip protocol:(int)protocol
{
    BOOL toReturn = false;
    g_UdpCommand = UDP_CMD_SET_DEVICE_TIMERS;
    
    if (protocol == PROTOCOL_HTTP) {
        [self generate_header_http];
    } else {
        [self generate_header];
    }
    
    for(int i = 0; i < sizeof(hMsg); i++){
        timerHeader[i] = hMsg[i];
    }
    
    int time = (int)[[NSDate date] timeIntervalSince1970];
    if (protocol == PROTOCOL_HTTP) {
        timerHeader[17] = (uint8_t) (time & 0xff);
        timerHeader[16] = (uint8_t) ((time >> 8) & 0xff);
        timerHeader[15] = (uint8_t) ((time >> 16) & 0xff);
        timerHeader[14] = (uint8_t) ((time >> 24) & 0xff);
    }
    if (protocol == PROTOCOL_UDP) {
        timerHeader[14] = (uint8_t) (time & 0xff);
        timerHeader[15] = (uint8_t) ((time >> 8) & 0xff);
        timerHeader[16] = (uint8_t) ((time >> 16) & 0xff);
        timerHeader[17] = (uint8_t) ((time >> 24) & 0xff);
    }
    
    NSData *data = [NSData dataWithBytes:timerHeader length:sizeof(timerHeader)];
    if(protocol == PROTOCOL_HTTP) {
        WebService *ws = [WebService new];
        ws.delegate = self;
        [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac data:data];
    } else if(protocol == PROTOCOL_UDP) {
        [self sendUDP:ip data:data];
    }
    return toReturn;
}

- (BOOL)sendTimers:(NSString *)devId protocol:(int)protocol
{
    BOOL toReturn = false;
    g_UdpCommand = UDP_CMD_SET_DEVICE_TIMERS;
    
    if (protocol == PROTOCOL_HTTP) {
        [self generate_header_http];
    } else {
        [self generate_header];
    }
    
    for(int i = 0; i < sizeof(hMsg); i++){
        timer[i] = hMsg[i];
    }
    
    NSString *ip = g_DeviceIp;
    
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDevice:devId];
    if (alarms && alarms.count>0) {
        for (Alarm *alarm in alarms) {
            int serviceId = alarm.service_id;
            if(protocol == PROTOCOL_HTTP){
                timer[14] = (uint8_t) (serviceId & 0xff);
                timer[15] = (uint8_t) ((serviceId >> 8) & 0xff);
                timer[16] = (uint8_t) ((serviceId >> 16) & 0xff);
                timer[17] = (uint8_t) ((serviceId >> 24) & 0xff);
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
                timer[14] = (uint8_t) (serviceId & 0xff);
                timer[15] = (uint8_t) ((serviceId >> 8) & 0xff);
                timer[16] = (uint8_t) ((serviceId >> 16) & 0xff);
                timer[17] = (uint8_t) ((serviceId >> 24) & 0xff);
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
            
            NSData *data = [NSData dataWithBytes:timer length:sizeof(timer)];
            if(protocol == PROTOCOL_HTTP) {
                WebService *ws = [WebService new];
                ws.delegate = self;
                [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac data:data];
            } else if(protocol == PROTOCOL_UDP) {
                [self sendUDP:ip data:data];
            }
        }
    }
    
    return toReturn;
}

- (BOOL)setDeviceStatus:(NSString *)ip serviceId:(int)serviceId action:(uint8_t)action
{
    g_UdpCommand = UDP_CMD_SET_DEVICE_STATUS;     //to generate the header
    [self generate_header];
    
    [self generate_header];
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
    uint8_t actionByte = action;
    sMsg[19] = actionByte;
    int terminator = 0x00000000;
    sMsg[20] = (uint8_t)(terminator & 0xff);
    sMsg[21] = (uint8_t)((terminator >> 8 ) & 0xff);
    sMsg[22] = (uint8_t)((terminator >> 16 ) & 0xff);
    sMsg[23] = (uint8_t)((terminator >> 24 ) & 0xff);
    
    NSData *data = [NSData dataWithBytes:sMsg length:sizeof(sMsg)];
    [self sendUDP:ip data:data];
    return YES;
}
*/

- (void)process_headers
{
    /**********************************************/
    int header = abs([self process_long:lMsg[0] b:lMsg[1] c:lMsg[2] d:lMsg[3]]);          //1397576276
    
    if (header != 1397576276) {
        process_data = true;
    }
    NSLog(@"HEADER: %d", header);
    /**********************************************/
    int msgid = abs([self process_long:lMsg[4] b:lMsg[5] c:lMsg[6] d:lMsg[7]]);
    if (msgid != previous_msgid){
        previous_msgid = msgid;
        process_data = true;
    } else {
        process_data = false;
    }
    NSLog(@"MSGID: %d", msgid);
    /**********************************************/
    int seq = abs([self process_long:lMsg[8] b:lMsg[9] c:lMsg[10] d:lMsg[11]]);
    NSLog(@"SEQ: %d", seq);
    /**********************************************/
    int size = [self process_long:lMsg[12] b:lMsg[13] c:lMsg[14] d:lMsg[15]];
    NSLog(@"SIZE: %d", size);
    /**********************************************/
    code = [self process_short:lMsg[16] b:lMsg[17]];
    NSLog(@"CODE: %d", code);
}

- (void)process_query_device_command
{
    /**********************************************/
    NSMutableString *mac = [NSMutableString new];
    for (int i = 18; i < 24; i++) {
        [mac appendString:[NSString stringWithFormat:@"%02x", lMsg[i]]];
    }
    js.sid = mac;
    NSLog(@"MAC: %@", mac);
    /**********************************************/
    NSMutableString *model = [NSMutableString new];
    for (int i = 24; i < 40; i++) {
        [model appendString:[NSString stringWithFormat:@"%c", lMsg[i]]];
    }
    js.model = model;
    NSLog(@"MODEL: %@", model);
    /**********************************************/
    int buildno = [self process_long:lMsg[40] b:lMsg[41] c:lMsg[42] d:lMsg[43]];
    js.buildno = buildno;
    NSLog(@"BUILD NO: %d", buildno);
    /**********************************************/
    int prot_ver = [self process_long:lMsg[44] b:lMsg[45] c:lMsg[46] d:lMsg[47]];
    js.prot_ver = prot_ver;
    NSLog(@"PROTOCOL VER: %d", prot_ver);
    /**********************************************/
    NSMutableString *hw_ver = [NSMutableString new];
    for (int i = 48; i < 64; i++) {
        [hw_ver appendString:[NSString stringWithFormat:@"%c", lMsg[i]]];
    }
    js.hw_ver = hw_ver;
    NSLog(@"HARDWARE VERSION: %@", hw_ver);
    /**********************************************/
    NSMutableString *fw_ver = [NSMutableString new];
    for (int i = 64; i < 80; i++) {
        [fw_ver appendString:[NSString stringWithFormat:@"%c", lMsg[i]]];
    }
    js.fw_ver = fw_ver;
    NSLog(@"FIRMWARE VERSION: %@", fw_ver);
    /**********************************************/
    int fw_date = [self process_long:lMsg[80] b:lMsg[81] c:lMsg[82] d:lMsg[83]];
    js.fw_date = fw_date;
    NSLog(@"FIRMWARE DATE: %d", fw_date);
    /**********************************************/
    int flag = [self process_long:lMsg[84] b:lMsg[85] c:lMsg[86] d:lMsg[87]];
    js.flag = flag;
    NSLog(@"FLAG: %d", flag);
}

- (void)process_get_device_status
{
    [self get_relay_status];
    [self get_nightlight_status];
    [self get_co_status];
    /**************TERMINATOR**************/
    int terminator = [self process_long:lMsg[48] b:lMsg[49] c:lMsg[50] d:lMsg[51]];
    NSLog(@"TERMINATOR: %d", terminator);
}

//==================================================================
#pragma mark - Private methods
//==================================================================
- (void)get_relay_status
{
    int service_id = [self process_long:lMsg[18] b:lMsg[19] c:lMsg[20] d:lMsg[21]];
    if (service_id == 0xD1000000) {
        NSLog(@"IS OUTLET SERVICE");
        int flag = [self process_long:lMsg[22] b:lMsg[23] c:lMsg[24] d:lMsg[25]];
        if(flag == 0x00000010){
            js.hall_sensor = 1;
            NSLog(@"Relay warning");
        } else {
            js.hall_sensor = 0;
        }
        uint8_t datatype = lMsg[26];
        uint8_t data = lMsg[27];
        if (data == 0x01){
            js.relay = 1;
            NSLog(@"Relay is on");
        } else {
            js.relay = 0;
            NSLog(@"Relay is off");
        }
        
    }
}

- (void)get_nightlight_status
{
    int service_id = [self process_long:lMsg[28] b:lMsg[29] c:lMsg[30] d:lMsg[31]];
    if(service_id == 0xD1000001) {
        NSLog(@"NIGHT LIGHT SERVICE");
        int flag = [self process_long:lMsg[32] b:lMsg[33] c:lMsg[34] d:lMsg[35]];             //not used for this service
        uint8_t datatype = lMsg[36];                                                    //always the same 0x01
        uint8_t data = lMsg[37];
        if (data == 0x01){
            js.nightlight = 1;
            NSLog(@"Nighlight is on");
        } else {
            js.nightlight = 0;
            NSLog(@"Nighlight is off");
        }
    }
}

- (void)get_co_status
{
    int service_id = [self process_long:lMsg[38] b:lMsg[39] c:lMsg[40] d:lMsg[41]];
    if (service_id == 0xD1000002) {
        int flag = [self process_long:lMsg[42] b:lMsg[43] c:lMsg[44] d:lMsg[45]];
        if(flag == 0x00000010){
            js.co_sensor = 1;                      //WARNING
        } else if (flag == 0x00000100){
            js.co_sensor = 3;                      //NOT PLUGGED
        } else {
            js.co_sensor = 0;                      //NORMAL
        }
        uint8_t datatype = lMsg[46];
        uint8_t data = lMsg[47];
    }
}

- (int)process_long:(uint8_t)a b:(uint8_t)b c:(uint8_t)c d:(uint8_t)d
{
    NSMutableData *buffer = [NSMutableData dataWithCapacity:4];
    [buffer appendBytes:&d length:1];
    [buffer appendBytes:&c length:1];
    [buffer appendBytes:&b length:1];
    [buffer appendBytes:&a length:1];
    
    int result;
    [buffer getBytes:&result length:sizeof(result)];
    return result;
}

- (short)process_short:(uint8_t)a b:(uint8_t)b
{
    NSMutableData *buffer = [NSMutableData dataWithCapacity:2];
    [buffer appendBytes:&b length:1];
    [buffer appendBytes:&a length:1];
    
    short result;
    [buffer getBytes:&result length:sizeof(result)];
    return result;
}

- (void)generate_header
{
    int header = 0x534D5254;
    int msgid = (int)(random() * 429496729) + 1;
    int seq = 0x80000000;
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
    hMsg[12] = (uint8_t) g_UdpCommand;
    hMsg[13] = (uint8_t) (g_UdpCommand >> 8);
}

- (void)generate_header_http
{
    int header = 0x534D5254;
    hMsg[3] = (uint8_t)(header);
    hMsg[2] = (uint8_t)((header >> 8 ));
    hMsg[1] = (uint8_t)((header >> 16 ));
    hMsg[0] = (uint8_t)((header >> 24 ));
    int msid = (int)(random()*4294967+1);
    hMsg[7] = (uint8_t)(msid);
    hMsg[6] = (uint8_t)((msid >> 8 ));
    hMsg[5] = (uint8_t)((msid >> 16 ));
    hMsg[4] = (uint8_t)((msid >> 24 ));
    int seq = 0x80000000;
    hMsg[11] = (uint8_t)(seq);
    hMsg[10] = (uint8_t)((seq >> 8 ));
    hMsg[9] = (uint8_t)((seq >> 16 ));
    hMsg[8] = (uint8_t)((seq >> 24 ));
    short command = g_UdpCommand;
    hMsg[13] = (uint8_t)(command);
    hMsg[12] = (uint8_t)((command >> 8 ));
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName {
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
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Devctrl failed: %@", message);
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}

@end
