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

#define MAX_UDP_DATAGRAM_LEN        64
#define UDP_BROADCAST_PORT          20004

@interface UDPListenerService()<GCDAsyncUdpSocketDelegate>
{
    NSString* broadcastIP;
    uint8_t lMsg[512];
    int previous_msgid;
    BOOL process_data;
    short code;
    //NetworkUtil networkUtil;
    //DatagramSocket ds = null;
    //DatagramPacket dp = new DatagramPacket(lMsg, lMsg.length);
    BOOL shouldRestartSocketListen;
    //Thread UDPBroadcastThread;
    short command;
    JSmartPlug *js;
    //UDPCommunication con = new UDPCommunication();
    //private IBinder mBinder = new MyBinder();
    int IRFlag;
    uint8_t ir[2];
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
        previous_msgid = 0;
        process_data = NO;
        code = 1;
        IRFlag = 0;
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
    if (![_udpSocket bindToPort:UDP_BROADCAST_PORT error:&error]) {
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
    
    if(g_UdpCommand == 0x000C){
        NSLog(@"Entering IR Mode");
        if(code == 0) {
            [self listenForIRFileName];
            code = 1;
        }
    }
    
    if(g_UdpCommand == 0x0001){
        if(code == 0){
            [self process_query_device_command];
            
            /*
            NSDictionary *userInfo = NSDictionary dictionaryWithObjects:<#(const id  _Nonnull __unsafe_unretained *)#> forKeys:<#(const id<NSCopying>  _Nonnull __unsafe_unretained *)#> count:<#(NSUInteger)#>
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_INFO
                                                                object:self
                                                              userInfo:userInfo];
            
            Intent i = new Intent("device_info");
            i.putExtra("ip",dp.getAddress().toString().substring(1));
            i.putExtra("id", js.getId());
            i.putExtra("model", js.getModel());
            sendBroadcast(i);
             */
            code = 1;
        }
    }
    
    if(g_UdpCommand == 0x000B){
        if(code == 0){
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:code] forKey:@"code"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SET_TIMER_DELAY
                                                                object:self
                                                              userInfo:userInfo];
            code = 1;
        }
    }
    
    if(g_UdpCommand == 0x0008){
        if(code == 0){
            code = 1;
            NSLog(@"DEVICE STATUS CHANGED");
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_STATUS_CHANGED
                                                                object:self
                                                              userInfo:nil];
        }
    }
    
    if(g_UdpCommand == 0x0007){
        if(code == 0){
            code = 1;
            [self process_get_device_status];
            [[SQLHelper getInstance] updatePlugServicesByID:js];
            //sql.updatePlugServicesByID(js);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI
                                                                object:self
                                                              userInfo:nil];
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

@end
