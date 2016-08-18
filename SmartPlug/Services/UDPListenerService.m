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
    uint32_t previous_msgid;
    short code;
    BOOL shouldRestartSocketListen;
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
    NSLog(@"Received data %ld from address %@", data.length, ipAddress);
    
    memcpy(lMsg, [data bytes], data.length);
    
    [self process_headers:ipAddress];
}

//==================================================================
#pragma mark - Private methods
//==================================================================

- (BOOL)listenForIRFileName
{
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
    return true;
}

- (void)process_headers:(NSString *)ipAddress
{
    code = 1;
    /**********************************************/
    int header = abs([Global process_long:lMsg[0] b:lMsg[1] c:lMsg[2] d:lMsg[3]]);
    
    BOOL isCommand;
    
    if (header == 0x534D5253) {
        // reply
        isCommand = false;
    } else if( header== 0x534D5254 ) {
        // command
        isCommand = true;
    } else {
        // failed
        NSLog(@"UDPListenerService: ignoring header = %d", header);
        return;
    }
    
    // process header
    uint32_t msgid = abs([Global process_long:lMsg[4] b:lMsg[5] c:lMsg[6] d:lMsg[7]]);
    int seq = abs([Global process_long:lMsg[8] b:lMsg[9] c:lMsg[10] d:lMsg[11]]);
    int size = [Global process_long:lMsg[12] b:lMsg[13] c:lMsg[14] d:lMsg[15]];
    code = [Global process_short:lMsg[16] b:lMsg[17]];

    NSString *mac = [[SQLHelper getInstance] getPlugMacFromIP:ipAddress];
    NSMutableDictionary *userInfo = (mac!=nil) ? [NSMutableDictionary dictionaryWithObject:mac forKey:@"macId"]:nil;

    if (isCommand) {

        if (code == 0x1000 && msgid != previous_msgid){
            code = 1;
            NSLog(@"UDPListenerService: command = BROADCAST");
            NSLog(@"msid: %d - previous_msgid: %d", msgid, previous_msgid);
            
            [self process_broadcast_info:ipAddress];
        } else if (code == 0x001F) {
            code = 1;
            NSLog(@"UDPListenerService: command = OTA firmware OK" );
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OTA_FINISHED
                                                                object:self
                                                              userInfo:userInfo];
        } else if(code == 0x0F0F){
            int mac = 0;
            for (int i = 18; i < 24; i++) {
                mac += lMsg[i] & 0xff;
            }
            
            NSMutableString *macStr = [NSMutableString new];
            for (int i = 18; i < 24; i++) {
                [macStr appendString:[NSString stringWithFormat:@"%02x", lMsg[i]]];
            }
            _js.sid = macStr;
            NSLog(@"MAC: %@", macStr);
            [[SQLHelper getInstance] updatePlugID:macStr ip:ipAddress];
            
            code = 1;
            NSLog(@"DEVICE IS ALIVE");
            
            if (!userInfo) {
                userInfo = [NSMutableDictionary new];
            }
            [userInfo setObject:ipAddress forKey:@"ip"];
            [userInfo setObject:macStr forKey:@"macId"];
            [userInfo setObject:[NSString stringWithFormat:@"JSPlug%d", mac] forKey:@"name"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_BROADCASTED_PRESENCE
                                                                object:self
                                                              userInfo:userInfo];
        } else {
            NSLog(@"UDPListenerService: unknown command %d", code);
        }
        
    } else {
        
        //if (msgid == previous_msgid) {
        //    NSLog(@"UDPListenerService: ignoring duplicate msg#%d", msgid);
        //    return; // ignore repeated command
        //}
        
        NSLog(@"UDPListenerService: Received header=%d msg#%d seq#%d size=%d code=%d", header, msgid, seq, size, code);
        
        previous_msgid = msgid;
        
        Command *currentCommand = [[UDPCommunication getInstance] dequeueCommandByIp:ipAddress msgID:msgid];
        if( !currentCommand ) {
            return;
        }
        
        switch ( currentCommand.command ) {
        
            case UDP_CMD_ADV_DEVICE_SETTINGS:
                NSLog(@"Entering IR Mode");
                if(code == 0) {
                    [self listenForIRFileName];
                    code = 1;
                }
                break;
        
            case UDP_CMD_DEVICE_QUERY:
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
                }
                break;
        
            case UDP_CMD_WIFI_SCAN:
                NSLog(@"I got a broadcast yeah.....");
                break;
        
            case UDP_CMD_DELAY_TIMER:
                if(code == 0){
                    code = 1;
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:code] forKey:@"code"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SET_TIMER_DELAY
                                                                        object:self
                                                                      userInfo:userInfo];
                    code = 1;
                }
                break;

            case UDP_CMD_SET_DEVICE_STATUS:
                if(code == 0){
                    code = 1;
                    [[UDPCommunication getInstance] finishDeviceStatus:currentCommand.msgID];
                    NSLog(@"DEVICE STATUS CHANGED");
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_STATUS_CHANGED
                                                                        object:self
                                                                      userInfo:userInfo];
                }
                break;

            case UDP_CMD_GET_DEVICE_STATUS:
                if(code == 0){
                    code = 1;
                    [self process_get_device_status:currentCommand];
                    [[SQLHelper getInstance] updatePlugServices:_js];
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI
                                                                        object:self
                                                                      userInfo:userInfo];
                }
                break;
                
            case UDP_CMD_SET_DEVICE_TIMERS:
                if(code == 0){
                    NSLog(@"TIMERS SENT SUCCESSFULLY");
                    code = 1;
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TIMERS_SENT_SUCCESS
                                                                        object:self
                                                                      userInfo:userInfo];
                }
                break;

            case 0x000F:
                if(code == 0){
                    NSLog(@"OTA SENT SUCCESSFULLY");
                    code = 1;
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OTA_SENT
                                                                        object:self
                                                                      userInfo:userInfo];
                }
                break;
                
            case 0x010F:
                if(code == 0){
                    NSLog(@"DELETE SEND SUCCESSFULLY");
                    code = 1;
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DELETE_SENT
                                                                        object:self
                                                                      userInfo:userInfo];
                }
                break;
                
            case 0x0F0F:
                if(code == 0){
                    //do nothing if we already receive this command
                    code = 1;
                }
                break;
        }
    }
}

- (void)updateRelayFlags:(int)flags sid:(NSString *)sid
{
    if ((flags & SERVICE_FLAGS_WARNING) == SERVICE_FLAGS_WARNING) {
        _js.hall_sensor = 1;
        NSLog(@"Relay warning");
        [[SQLHelper getInstance] updatePlugHallSensorService:_js.hall_sensor sid:sid];
    } else {
        NSLog(@"Relay normal condition");
        _js.hall_sensor = 0;
        [[SQLHelper getInstance] updatePlugHallSensorService:_js.hall_sensor sid:sid];
    }
}

- (void)updateCOSensorFlags:(int)flags sid:(NSString *)sid {
    int costatus = 0;
    if((flags & SERVICE_FLAGS_WARNING) == SERVICE_FLAGS_WARNING) {
        NSLog(@"CO SENSOR WARNING");
        costatus = 1;
        _js.co_sensor = costatus;
    } else if ((flags & SERVICE_FLAGS_DISABLED) == SERVICE_FLAGS_DISABLED){
        costatus = 3;
        NSLog(@"CO SENSOR NOT PLUGGED IN");
        _js.co_sensor = costatus;                                             //NOT PLUGGED
    } else {
        NSLog(@"CO SENSOR NORMAL CONDITION = %d", flags);
        _js.co_sensor = costatus;                                             //NORMAL
    }
    
    [[SQLHelper getInstance] updatePlugCoSensorService:costatus sid:sid];
}

- (void)process_broadcast_info:(NSString *)ipAddress {
    NSString *sid = [[SQLHelper getInstance] getPlugMacFromIP:ipAddress];
    if (!sid) {
        [[UDPCommunication getInstance] queryDevicesByIp:ipAddress command:UDP_CMD_DEVICE_QUERY];
        sid = @"";
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:sid forKey:@"macId"];
    
    // TODO
    //HTTPHelper.mPollingDevices.remove(id);
    
    /**********************************************/
    
    int pos = 18;
    int serviceID;
    while( (serviceID = [Global process_long:lMsg[pos] b:lMsg[pos+1] c:lMsg[pos+2] d:lMsg[pos+3]]) !=0 ) {
        pos+=4;
        int flags = [Global process_long:lMsg[pos] b:lMsg[pos+1] c:lMsg[pos+2] d:lMsg[pos+3]];
        pos+=4;
        uint8_t serviceFormat = lMsg[pos];
        pos++;
        uint8_t serviceData = lMsg[pos];   // NOTE: currently only need 1 byte, but in future, make sure
        // this data size is based on serviceFormat!
        pos++;
        
        if( serviceFormat!=0x11 )
            break;  // unhandled service format (This will need to be updated for future devices!)
        
        if( serviceID == RELAY_SERVICE) {
            [[SQLHelper getInstance] updatePlugRelayService:serviceData sid:sid];
            [self updateRelayFlags:flags sid:sid];
        } else if( serviceID == NIGHTLED_SERVICE) {
            [[SQLHelper getInstance] updatePlugNightlightService:serviceData sid:sid];
        } else if( serviceID == CO_SERVICE ) {
            [self updateCOSensorFlags:flags sid:sid];
        } else {
            break; // stop processing when unknown services are reached
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_M1_UPDATE_UI object:self userInfo:userInfo];
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

- (void)process_get_device_status:(Command *)currentCommand
{
    [self get_relay_status:currentCommand];
    [self get_nightlight_status:currentCommand];
    [self get_co_status:currentCommand];
    /**************TERMINATOR**************/
    int terminator = [Global process_long:lMsg[48] b:lMsg[49] c:lMsg[50] d:lMsg[51]];
    NSLog(@"TERMINATOR: %d", terminator);
}

//==================================================================
#pragma mark - Private methods
//==================================================================
- (void)get_relay_status:(Command *)currentCommand
{
    int service_id = [Global process_long:lMsg[18] b:lMsg[19] c:lMsg[20] d:lMsg[21]];
    if (service_id == RELAY_SERVICE) {
        NSLog(@"IS OUTLET SERVICE");
        int flag = [Global process_long:lMsg[22] b:lMsg[23] c:lMsg[24] d:lMsg[25]];
        [self updateRelayFlags:flag sid:currentCommand.macID];
        uint8_t datatype = lMsg[26];
        uint8_t data = lMsg[27];
        if (data == 0x01){
            _js.relay = 1;
            NSLog(@"Relay is on");
        } else {
            _js.relay = 0;
            NSLog(@"Relay is off");
        }
        
        NSLog(@"MAC: %@", currentCommand.macID);
        [[SQLHelper getInstance] updatePlugRelayService:_js.relay sid:currentCommand.macID];
        [[SQLHelper getInstance] updatePlugHallSensorService:_js.hall_sensor sid:currentCommand.macID];
    }
}

- (void)get_nightlight_status:(Command *)currentCommand
{
    int service_id = [Global process_long:lMsg[28] b:lMsg[29] c:lMsg[30] d:lMsg[31]];
    if(service_id == NIGHTLED_SERVICE) {
        NSLog(@"NIGHT LIGHT SERVICE");
        int flag = [Global process_long:lMsg[32] b:lMsg[33] c:lMsg[34] d:lMsg[35]];             //not used for this service
        uint8_t datatype = lMsg[36];                                  //always the same 0x01
        uint8_t data = lMsg[37];
        if (data == 0x01){
            _js.nightlight = 1;
            NSLog(@"Nighlight is on");
        } else {
            _js.nightlight = 0;
            NSLog(@"Nighlight is off");
        }
        
        [[SQLHelper getInstance] updatePlugNightlightService:data sid:currentCommand.macID];
    }
}

- (void)get_co_status:(Command *)currentCommand
{
    int service_id = [Global process_long:lMsg[38] b:lMsg[39] c:lMsg[40] d:lMsg[41]];
    int costatus = 0;
    if (service_id == CO_SERVICE) {
        int flag = [Global process_long:lMsg[42] b:lMsg[43] c:lMsg[44] d:lMsg[45]];
        [self updateCOSensorFlags:flag sid:currentCommand.macID];
        [[SQLHelper getInstance] updatePlugCoSensorService:costatus sid:currentCommand.macID];
        uint8_t datatype = lMsg[46];
        uint8_t data = lMsg[47];
    }
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
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Devctrl failed: %@", message);
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName  webservice:(WebService *)ws{
    NSLog(@"Connect fail for %@", resultName);
}

@end
