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
#import "UDPCommunication.h"

#define MAX_UDP_DATAGRAM_LEN        128
#define UDP_SERVER_PORT             20004
#define UDP_TESTING_PORT            20005

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
        _js = [JSmartPlug new];
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
    NSLog(@"UDP sent %ld bytes to %@", (unsigned long)data.length, ip);
}

- (BOOL)isRunning
{
    return _isRunning;
}

- (BOOL)setDeviceStatusProcess:(NSString *)ip serviceId:(int)serviceId action:(uint8_t)action
{
    code = 1;
    [[UDPCommunication getInstance] setDeviceStatus:ip serviceId:serviceId action:action];
    return YES;
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
    //NSLog(@"Received data %ld from address %@", data.length, ipAddress);
    
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
            //[[SQLHelper getInstance] updatePlugServices:_js];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      ipAddress, @"ip",
                                      _js.sid, @"id",
                                      _js.model, @"model",
                                      [NSNumber numberWithInt:_js.buildno], @"buildno",
                                      [NSNumber numberWithInt:_js.prot_ver], @"prot_ver",
                                      _js.hw_ver, @"hw_ver",
                                      _js.fw_ver, @"fw_ver",
                                      [NSNumber numberWithInt:_js.fw_date], @"fw_date",
                                      [NSNumber numberWithInt:_js.flag], @"flag",
                                      nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_INFO
                                                                object:self
                                                              userInfo:userInfo];
            
            code = 1;
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(g_UdpCommand == UDP_CMD_WIFI_SCAN) {
         NSLog(@"I got a broadcast yeah.....");
    }
    
    if(g_UdpCommand == UDP_CMD_DELAY_TIMER){
        if(code == 0){
            code = 1;
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
            [[SQLHelper getInstance] updatePlugServices:_js];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI
                                                                object:self
                                                              userInfo:nil];
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(g_UdpCommand == UDP_CMD_SET_DEVICE_TIMERS){
        if(code == 0){
            NSLog(@"TIMERS SENT SUCCESSFULLY");
            code = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TIMERS_SENT_SUCCESS
                                                                object:self
                                                              userInfo:nil];
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(g_UdpCommand == 0x000F){
        if(code == 0){
            NSLog(@"OTA SENT SUCCESSFULLY");
            code = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OTA_SENT
                                                                object:self
                                                              userInfo:nil];
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(g_UdpCommand == 0x010F){
        if(code == 0){
            NSLog(@"DELETE SEND SUCCESSFULLY");
            code = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DELETE_SENT
                                                                object:self
                                                              userInfo:nil];
            g_UdpCommand = 0;   // Reset command after processing
        }
    }
    
    if(code == 0x1000 && process_data == false){
        code = 1;
        NSLog(@"I GOT A BROADCAST");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_M1_UPDATE_UI
                                                            object:self
                                                          userInfo:nil];
    }
    
    if(code == 0x001F && process_data == true){
        code = 1;
        NSLog(@"OTA FINISHED");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OTA_FINISHED
                                                            object:self
                                                          userInfo:nil];
        g_UdpCommand = 0;   // Reset command after processing
    }
}

//==================================================================
#pragma mark - Private methods
//==================================================================

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
        if(name == 'x'){
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:-1] forKey:@"filename"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_IR_FILENAME
                                                                object:self
                                                              userInfo:userInfo];
        }
    }
    return true;
}

- (void)process_headers
{
    code = 1;
    /**********************************************/
    int header = abs([Global process_long:lMsg[0] b:lMsg[1] c:lMsg[2] d:lMsg[3]]);
    
    if (header == 0x534D5253) {
        process_data = true;    // Broadcast is 0x534D5254, OTA is 0x534D5254
    } else {
        process_data = false;
    }
    
    //NSLog(@"HEADER: %d", header);
    /**********************************************/
    int msgid = abs([Global process_long:lMsg[4] b:lMsg[5] c:lMsg[6] d:lMsg[7]]);
    if (msgid != previous_msgid){
        previous_msgid = msgid;
        process_data = true;
    } else {
        process_data = false;
    }
    //NSLog(@"MSGID: %d", msgid);
    /**********************************************/
    int seq = abs([Global process_long:lMsg[8] b:lMsg[9] c:lMsg[10] d:lMsg[11]]);
    //NSLog(@"SEQ: %d", seq);
    /**********************************************/
    int size = [Global process_long:lMsg[12] b:lMsg[13] c:lMsg[14] d:lMsg[15]];
    //NSLog(@"SIZE: %d", size);
    /**********************************************/
    code = [Global process_short:lMsg[16] b:lMsg[17]];
    //NSLog(@"CODE: %d", code);
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
    
    // Update to database
    _js.ip = g_DeviceIp;
    [[SQLHelper getInstance] updatePlugServices:_js];
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
            NSLog(@"Relay normal condition");
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
        
        NSLog(@"MAC: %@", g_DeviceMac);
        [[SQLHelper getInstance] updatePlugRelayService:_js.relay sid:g_DeviceMac];
        [[SQLHelper getInstance] updatePlugHallSensorService:_js.hall_sensor sid:g_DeviceMac];
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
        
        [[SQLHelper getInstance] updatePlugNightlightService:data sid:g_DeviceMac];
    }
}

- (void)get_co_status
{
    int service_id = [Global process_long:lMsg[38] b:lMsg[39] c:lMsg[40] d:lMsg[41]];
    int costatus = 0;
    if (service_id == CO_SERVICE) {
        int flag = [Global process_long:lMsg[42] b:lMsg[43] c:lMsg[44] d:lMsg[45]];
        if(flag == 0x00000010){
            NSLog(@"CO SENSOR WARNING");
            costatus = 1;
            _js.co_sensor = costatus;                      //WARNING
        } else if (flag == 0x00000100){
            costatus = 3;
            NSLog(@"CO SENSOR NOT PLUGGED IN");
            _js.co_sensor = costatus;                      //NOT PLUGGED
        } else {
            costatus = 0;
            NSLog(@"CO SENSOR NORMAL CONDITION");
            _js.co_sensor = costatus;                      //NORMAL
        }
        [[SQLHelper getInstance] updatePlugCoSensorService:costatus sid:g_DeviceMac];
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
    short cmd = g_UdpCommand;
    hMsg[13] = (uint8_t)(cmd);
    hMsg[12] = (uint8_t)((cmd >> 8 ));
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
