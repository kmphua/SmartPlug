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

#define MAX_UDP_DATAGRAM_LEN        128
#define UDP_SERVER_PORT             20004
#define UDP_TESTING_PORT            20005

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
    uint8_t delayT[18];
    uint8_t ir2[1];
    int previous_msgid;
    BOOL process_data;
    short code;
    int IRFlag;
    int IRSendFlag;
    int irCode;
    int sendFlag;
    
    GCDAsyncUdpSocket *udpSocket;
    BOOL isRunning;
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
    }
    return self;
}
 
- (void)sendUDP:(NSString *)ip data:(NSData *)data
{
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:0];
    NSLog(@"UDP PACKET SENT");
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
#pragma mark - Public methods
//==================================================================

- (BOOL)delayTimer:(int)seconds protocol:(int)protocol
{
    g_UdpCommand = UDP_CMD_DELAY_TIMER;
    NSString *ip = g_DeviceIp;
    if (ip != nil) {
        if (protocol == PROTOCOL_HTTP) {
            [self generate_header_http];
        } else {
            [self generate_header];
        }
        
        for (int i = 0; i < 14; i++) {
            delayT[i] = hMsg[i];
        }
        
        delayT[17] = (uint8_t) (seconds & 0xff);
        delayT[16] = (uint8_t) ((seconds >> 8) & 0xff);
        delayT[15] = (uint8_t) ((seconds >> 16) & 0xff);
        delayT[14] = (uint8_t) ((seconds >> 24) & 0xff);
        
        if (protocol == PROTOCOL_HTTP) {
            WebService *ws = [WebService new];
            ws.delegate = self;
            NSData *data = [NSData dataWithBytes:delayT length:sizeof(delayT)];
            [ws setTimerDelay:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac data:data];
        } else if (protocol == PROTOCOL_UDP) {
            if (!udpSocket) {
                udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
            }
            NSData *data = [NSData dataWithBytes:delayT length:sizeof(delayT)];
            [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:1];
        }
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

- (BOOL)queryDevices:(NSString *)ip udpMsg_param:(short)udpMsg_param
{
    g_UdpCommand = udpMsg_param;
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    [self generate_header];
    for(int i=0; i<14;i++){
        rMsg[i] = hMsg[i];
    }
    
    NSData *data = [NSData dataWithBytes:rMsg length:sizeof(rMsg)];
    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:1];
    return YES;
}

- (BOOL)sendIRMode
{
    NSString *ip = g_DeviceIp;
    g_UdpCommand = UDP_CMD_ADV_DEVICE_SETTINGS;
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

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
    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:1];
    return YES;
}

- (BOOL)cancelIRMode
{
    NSString *ip = g_DeviceIp;
    g_UdpCommand = UDP_CMD_ADV_DEVICE_SETTINGS;
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    [self generate_header];
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
    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:1];
    return YES;
}

- (BOOL)sendOTACommand:(NSString *)ip
{
    g_UdpCommand = 0x000F;
    [self generate_header];
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    NSData *data = [NSData dataWithBytes:hMsg length:sizeof(hMsg)];
    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:1];
    NSLog(@"OTA COMMAND SENT");
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
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    NSData *data = [NSData dataWithBytes:irHeader length:sizeof(irHeader)];
    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:1];
    NSLog(@"IR HEADERS SENT");
}

- (BOOL)setDeviceTimersHTTP:(NSString *)devId send:(int)send
{
    BOOL result = true;
    sendFlag = send;
    NSString *ip = g_DeviceIp;
    BOOL headerOK = [self sendTimerHeaders:ip protocol:PROTOCOL_HTTP];
    BOOL timerOK = [self sendTimers:devId protocol:PROTOCOL_HTTP];
    BOOL termiOK = [self sendTimerTerminator:ip protocol:PROTOCOL_HTTP];
    
    if (headerOK && timerOK && termiOK) {
        result = true;
    } else {
        result = false;
    }
    return result;
}

- (BOOL)setDeviceTimersUDP:(NSString *)devId
{
    BOOL result = true;
    NSString *ip = g_DeviceIp;
    BOOL headerOK = [self sendTimerHeaders:ip protocol:PROTOCOL_UDP];
    BOOL timerOK = [self sendTimers:devId protocol:PROTOCOL_UDP];
    BOOL termiOK = [self sendTimerTerminator:ip protocol:PROTOCOL_UDP];
    
    if (headerOK && timerOK && termiOK) {
        result = true;
    } else {
        result = false;
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
        [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac send:sendFlag data:data];
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
        [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac send:sendFlag data:data];
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
            
            NSData *data = [NSData dataWithBytes:timer length:sizeof(timer)];
            if(protocol == PROTOCOL_HTTP) {
                WebService *ws = [WebService new];
                ws.delegate = self;
                [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac send:sendFlag data:data];
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
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
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
    uint8_t data = action;
    sMsg[19] = data;
    int terminator = 0x00000000;
    sMsg[20] = (uint8_t)(terminator & 0xff);
    sMsg[21] = (uint8_t)((terminator >> 8 ) & 0xff);
    sMsg[22] = (uint8_t)((terminator >> 16 ) & 0xff);
    sMsg[23] = (uint8_t)((terminator >> 24 ) & 0xff);
    
    NSData *udpData = [NSData dataWithBytes:sMsg length:sizeof(sMsg)];
    [udpSocket sendData:udpData toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:1];
    return YES;
}

- (void)process_headers
{
    /**********************************************/
    int header = abs([Global process_long:lMsg[0] b:lMsg[1] c:lMsg[2] d:lMsg[3]]);          //1397576276
    
    if (header != 1397576276) {
        process_data = true;
    }
    NSLog(@"HEADER: %d", header);
    /**********************************************/
    int msgid = abs([Global process_long:lMsg[4] b:lMsg[5] c:lMsg[6] d:lMsg[7]]);
    if (msgid != previous_msgid){
        previous_msgid = msgid;
        process_data = true;
    } else {
        process_data = false;
    }
    NSLog(@"MSGID: %d", msgid);
    /**********************************************/
    int seq = abs([Global process_long:lMsg[8] b:lMsg[9] c:lMsg[10] d:lMsg[11]]);
    NSLog(@"SEQ: %d", seq);
    /**********************************************/
    int size = [Global process_long:lMsg[12] b:lMsg[13] c:lMsg[14] d:lMsg[15]];
    NSLog(@"SIZE: %d", size);
    /**********************************************/
    code = [Global process_short:lMsg[16] b:lMsg[17]];
    NSLog(@"CODE: %d", code);
}

- (void)process_query_device_command
{
    /**********************************************/
    NSMutableString *mac = [NSMutableString new];
    for (int i = 18; i < 24; i++) {
        [mac appendString:[NSString stringWithFormat:@"%02x", lMsg[i]]];
    }
    _js.sid = mac;
    NSLog(@"MAC: %@", mac);
    /**********************************************/
    NSMutableString *model = [NSMutableString new];
    for (int i = 24; i < 40; i++) {
        [model appendString:[NSString stringWithFormat:@"%c", lMsg[i]]];
    }
    _js.model = model;
    NSLog(@"MODEL: %@", model);
    /**********************************************/
    int buildno = [Global process_long:lMsg[40] b:lMsg[41] c:lMsg[42] d:lMsg[43]];
    _js.buildno = buildno;
    NSLog(@"BUILD NO: %d", buildno);
    /**********************************************/
    int prot_ver = [Global process_long:lMsg[44] b:lMsg[45] c:lMsg[46] d:lMsg[47]];
    _js.prot_ver = prot_ver;
    NSLog(@"PROTOCOL VER: %d", prot_ver);
    /**********************************************/
    NSMutableString *hw_ver = [NSMutableString new];
    for (int i = 48; i < 64; i++) {
        [hw_ver appendString:[NSString stringWithFormat:@"%c", lMsg[i]]];
    }
    _js.hw_ver = hw_ver;
    NSLog(@"HARDWARE VERSION: %@", hw_ver);
    /**********************************************/
    NSMutableString *fw_ver = [NSMutableString new];
    for (int i = 64; i < 80; i++) {
        [fw_ver appendString:[NSString stringWithFormat:@"%c", lMsg[i]]];
    }
    _js.fw_ver = fw_ver;
    NSLog(@"FIRMWARE VERSION: %@", fw_ver);
    /**********************************************/
    int fw_date = [Global process_long:lMsg[80] b:lMsg[81] c:lMsg[82] d:lMsg[83]];
    _js.fw_date = fw_date;
    NSLog(@"FIRMWARE DATE: %d", fw_date);
    /**********************************************/
    int flag = [Global process_long:lMsg[84] b:lMsg[85] c:lMsg[86] d:lMsg[87]];
    _js.flag = flag;
    NSLog(@"FLAG: %d", flag);
}

- (void)process_get_device_status
{
    [self get_relay_status];
    [self get_nightlight_status];
    [self get_co_status];
    /**************TERMINATOR**************/
    int terminator = [Global process_long:lMsg[48] b:lMsg[49] c:lMsg[50] d:lMsg[51]];
    NSLog(@"TERMINATOR: %d", terminator);
}

//==================================================================
#pragma mark - Private methods
//==================================================================
- (void)get_relay_status
{
    int service_id = [Global process_long:lMsg[18] b:lMsg[19] c:lMsg[20] d:lMsg[21]];
    if (service_id == RELAY_SERVICE) {
        NSLog(@"IS OUTLET SERVICE");
        int flag = [Global process_long:lMsg[22] b:lMsg[23] c:lMsg[24] d:lMsg[25]];
        if(flag == 0x00000010){
            _js.hall_sensor = 1;
            NSLog(@"Relay warning");
        } else {
            _js.hall_sensor = 0;
        }
        uint8_t datatype = lMsg[26];
        uint8_t data = lMsg[27];
        if (data == 0x01){
            _js.relay = 1;
            NSLog(@"Relay is on");
        } else {
            _js.relay = 0;
            NSLog(@"Relay is off");
        }
        
    }
}

- (void)get_nightlight_status
{
    int service_id = [Global process_long:lMsg[28] b:lMsg[29] c:lMsg[30] d:lMsg[31]];
    if(service_id == NIGHTLED_SERVICE) {
        NSLog(@"NIGHT LIGHT SERVICE");
        int flag = [Global process_long:lMsg[32] b:lMsg[33] c:lMsg[34] d:lMsg[35]];             //not used for this service
        uint8_t datatype = lMsg[36];                                                    //always the same 0x01
        uint8_t data = lMsg[37];
        if (data == 0x01){
            _js.nightlight = 1;
            NSLog(@"Nighlight is on");
        } else {
            _js.nightlight = 0;
            NSLog(@"Nighlight is off");
        }
    }
}

- (void)get_co_status
{
    int service_id = [Global process_long:lMsg[38] b:lMsg[39] c:lMsg[40] d:lMsg[41]];
    if (service_id == CO_SERVICE) {
        int flag = [Global process_long:lMsg[42] b:lMsg[43] c:lMsg[44] d:lMsg[45]];
        if(flag == 0x00000010){
            _js.co_sensor = 1;                      //WARNING
        } else if (flag == 0x00000100){
            _js.co_sensor = 3;                      //NOT PLUGGED
        } else {
            _js.co_sensor = 0;                      //NORMAL
        }
        uint8_t datatype = lMsg[46];
        uint8_t data = lMsg[47];
    }
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
