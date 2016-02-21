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
#import "JSmartPlug.h"

#define MAX_UDP_DATAGRAM_LEN        128
#define UDP_SERVER_PORT             20004
#define UDP_TESTING_PORT            20005

@interface UDPCommunication()<GCDAsyncUdpSocketDelegate>
{
    uint8_t lMsg[MAX_UDP_DATAGRAM_LEN];
    uint8_t hMsg[14];
    uint8_t irHeader[15];
    uint8_t timerHeader[20];
    uint8_t timer[12];
    uint8_t rMsg[14];
    uint8_t sMsg[24];
    uint8_t iMsg[22];
    uint8_t ir[128];
    uint8_t ir2[1];
    NSMutableArray *IRCodes;
    JSmartPlug *js;
    short command;
    int previous_msgid;
    BOOL process_data;
    short code;
    //MySQLHelper sql;
    int IRFlag;
    int IRSendFlag;
    int irCode;
    
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
        IRCodes = [NSMutableArray new];
        previous_msgid = 0;
        process_data = false;
        code = 1;
        IRFlag = 0;
        IRSendFlag = 0;
        irCode = 0;
    }
    return self;
}

- (BOOL)runUdpServer {
    if (isRunning) {
        NSLog(@"Server already running!");
        return NO;
    }
    
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    NSError *error = nil;
    if (![udpSocket bindToPort:UDP_SERVER_PORT error:&error]) {
        NSLog(@"Error starting server (bind): %@", error);
        return NO;
    }
    if (![udpSocket beginReceiving:&error]) {
        [udpSocket close];
        NSLog(@"Error starting server (recv): %@", error);
        return NO;
    }
    
    NSLog(@"UDP server started on %@:%i",[udpSocket localHost_IPv4],[udpSocket localPort]);
    isRunning = YES;
    return YES;
}

- (void)runUdpClient:(NSString *)ip msg:(NSString *)msg {
    if (!udpSocket) {
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:0];
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

- (BOOL)delayTimer:(int)seconds
{
    command = 0x000B;
    NSString *ip = M1.ip;
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
        
        DatagramSocket ds = null;
        try {
            ds = new DatagramSocket();
            InetAddress serverAddr = InetAddress.getByName(ip);
            DatagramPacket dp;
            dp = new DatagramPacket(delay, delay.length, serverAddr, UDP_SERVER_PORT);
            ds.send(dp);
        } catch (SocketException e) {
            e.printStackTrace();
            return false;
        } catch (UnknownHostException e) {
            e.printStackTrace();
            return false;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            if (ds != null) {
                ds.close();
                //runUdpServer();
            }
        }
        return true;
    } else {
        return false;
    }
}

- (BOOL)listenForIRCodes
{
    DatagramPacket dp = new DatagramPacket(ir, ir.length);
    DatagramSocket ds = null;
    
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
    return true;
}

- (BOOL)queryDevices:(NSString *)ip udpMsg_param:(short)udpMsg_param
{
    command = udpMsg_param;
    DatagramSocket ds = null;
    try {
        ds = new DatagramSocket();
        InetAddress serverAddr = InetAddress.getByName(ip);
        DatagramPacket dp;
        generate_header();
        for(int i=0; i<14;i++){
            rMsg[i] = hMsg[i];
        }
        dp = new DatagramPacket(rMsg, rMsg.length, serverAddr, UDP_SERVER_PORT);
        ds.send(dp);
    } catch (SocketException e) {
        e.printStackTrace();
        return false;
    }catch (UnknownHostException e) {
        e.printStackTrace();
        return false;
    } catch (IOException e) {
        e.printStackTrace();
        return false;
    } catch (Exception e) {
        e.printStackTrace();
        return false;
    } finally {
        if (ds != null) {
            ds.close();
            //runUdpServer();
        }
    }
    return true;
}

- (BOOL)sendIRMode
{
    NSString * ip = M1.ip;
    command = 0x000C;
    DatagramSocket ds = null;
    try {
        ds = new DatagramSocket();
        InetAddress serverAddr = InetAddress.getByName(ip);
        DatagramPacket dp;
        generate_header();
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
        dp = new DatagramPacket(iMsg, iMsg.length, serverAddr, UDP_SERVER_PORT);
        ds.send(dp);
    } catch (SocketException e) {
        e.printStackTrace();
    }catch (UnknownHostException e) {
        e.printStackTrace();
    } catch (IOException e) {
        e.printStackTrace();
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (ds != null) {
            ds.close();
            //runUdpServer();
        }
    }
    return YES;
}

- (BOOL)sendIRFileName:(int)filename
{
    [self sendIRHeader:filename];
    return YES;
}

- (void)sendIRHeader:(int)filename
{
    NSString * ip = M1.ip;
    command = 0x000A;
    generate_header();
    for(int i = 0; i < hMsg.length; i++){
        irHeader[i] = hMsg[i];
    }
    irHeader[14] = (uint8_t)filename;
    DatagramSocket ds = null;
    try {
        ds = new DatagramSocket();
        InetAddress serverAddr = InetAddress.getByName(ip);
        DatagramPacket dp;
        dp = new DatagramPacket(irHeader, irHeader.length, serverAddr, UDP_SERVER_PORT);
        ds.send(dp);
        System.out.println("IR HEADERS SENT");
    } catch (Exception e){
        e.printStackTrace();
    }
    ds.close();
    //runUdpServer();
}

- (BOOL)setDeviceTimers:(NSString *)ip Context a
{
    sendTimerHeaders(ip);
    sendTimers(ip, a);
    DatagramSocket ds = null;
    //FINALLY SEND TERMINATOR
    try {
        int terminator = 0x00000000;
        uint8_t[] end = new uint8_t[4];
        end[0] = (uint8_t)(terminator & 0xff);
        end[1] = (uint8_t)((terminator >> 8) & 0xff);
        end[2] = (uint8_t)((terminator >> 16) & 0xff);
        end[3] = (uint8_t)((terminator >> 24) & 0xff);
        ds = new DatagramSocket();
        InetAddress serverAddr = InetAddress.getByName(ip);
        DatagramPacket dp;
        dp = new DatagramPacket(end, end.length, serverAddr, UDP_SERVER_PORT);
        ds.send(dp);
        System.out.println("TIMERS TERMINATOR SENT");
    } catch (Exception e){
        e.printStackTrace();
    }
    return true;
}

- (void)sendTimerHeaders:(NSString *)ip
{
    command = 0x0009;
    generate_header();
    for(int i = 0; i < hMsg.length; i++){
        timerHeader[i] = hMsg[i];
    }
    int time = (int)(System.currentTimeMillis()/1000);
    timerHeader[14] = (uint8_t)(time & 0xff);
    timerHeader[15] = (uint8_t)((time >> 8) & 0xff);
    timerHeader[16] = (uint8_t)((time >> 16) & 0xff);
    timerHeader[17] = (uint8_t)((time >> 24) & 0xff);
    DatagramSocket ds = null;
    try {
        ds = new DatagramSocket();
        InetAddress serverAddr = InetAddress.getByName(ip);
        DatagramPacket dp;
        dp = new DatagramPacket(timerHeader, timerHeader.length, serverAddr, UDP_SERVER_PORT);
        ds.send(dp);
        System.out.println("TIMERS HEADERS SENT");
    } catch (Exception e){
        e.printStackTrace();
    }
    ds.close();
}

- (void)sendTimers:(NSString *)ip  Context a ){
    sql = new MySQLHelper(a);
    Cursor c = sql.getAlarmData(ip);
    if(c.getCount() > 0){
        c.moveToFirst();
        for(int j = 0; j < c.getCount(); j++){
            int serviceId = c.getInt(2);
            timer[0] = (uint8_t)(serviceId & 0xff);
            timer[1] = (uint8_t)((serviceId >> 8) & 0xff);
            timer[2] = (uint8_t)((serviceId >> 16) & 0xff);
            timer[3] = (uint8_t)((serviceId >> 24) & 0xff);
            timer[4] = 0x01;
            timer[5] = 0x01;
            timer[6] = 0x00;
            int dow = c.getInt(3);
            timer[7] = (uint8_t)(dow & 0xff);
            int initHour = c.getInt(4);
            timer[8] = (uint8_t)(initHour & 0xff);
            int initMin = c.getInt(5);
            timer[9] = (uint8_t)(initMin & 0xff);
            int endHour = c.getInt(6);
            timer[10] = (uint8_t)(endHour & 0xff);
            int endMinu = c.getInt(7);
            timer[11] = (uint8_t)(endMinu & 0xff);
            
            DatagramSocket ds = null;
            try {
                ds = new DatagramSocket();
                InetAddress serverAddr = InetAddress.getByName(ip);
                DatagramPacket dp;
                dp = new DatagramPacket(timer, timer.length, serverAddr, UDP_SERVER_PORT);
                ds.send(dp);
                System.out.println("TIMER "+j+" SENT");
                ds.close();
            } catch (Exception e){
                e.printStackTrace();
            }
            
            if(!c.isLast()) {
                c.moveToNext();
            }
        }
        c.close();
    }
}

- (BOOL)setDeviceStatus:(NSString *)ip serviceId:(int)serviceId action:(uint8_t)action
{
    command = 0x0008;     //to generate the header
    generate_header();
    DatagramSocket ds = null;
    try {
        ds = new DatagramSocket();
        InetAddress serverAddr = InetAddress.getByName(ip);
        DatagramPacket dp;
        generate_header();
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
        
        dp = new DatagramPacket(sMsg, sMsg.length, serverAddr, UDP_SERVER_PORT);
        ds.send(dp);
    } catch (SocketException e) {
        e.printStackTrace();
        return false;
    }catch (UnknownHostException e) {
        e.printStackTrace();
        return false;
    } catch (IOException e) {
        e.printStackTrace();
        return false;
    } catch (Exception e) {
        e.printStackTrace();
        return false;
    } finally {
        if (ds != null) {
            ds.close();
            //        runUdpServer();
        }
        return true;
    }
}

- (void)process_headers
{
    /**********************************************/
    int header = Math.abs(process_long(lMsg[0],lMsg[1],lMsg[2],lMsg[3]));          //1397576276
    
    if (header != 1397576276) {
        process_data = true;
    }
    System.out.println("HEADER: " + header);
    /**********************************************/
    int msgid = Math.abs(process_long(lMsg[4],lMsg[5],lMsg[6],lMsg[7]));
    if (msgid != previous_msgid){
        previous_msgid = msgid;
        process_data = true;
    } else {
        process_data = false;
    }
    System.out.println("MSGID: " + msgid);
    /**********************************************/
    int seq = Math.abs(process_long(lMsg[8],lMsg[9],lMsg[10],lMsg[11]));
    System.out.println("SEQ: " + seq);
    /**********************************************/
    int size = process_long(lMsg[12], lMsg[13], lMsg[14], lMsg[15]);
    System.out.println("SIZE: " + size);
    /**********************************************/
    code = process_short(lMsg[16], lMsg[17]);
    System.out.println("CODE: " + code);
}

- (void)process_query_device_command
{
    /**********************************************/
    StringBuffer mac = new StringBuffer("");
    for (int i = 18; i < 24; i++) {
        mac.append(String.format("%02x", lMsg[i]));
    }
    js.setId(mac.toString());
    System.out.println("MAC: " + mac);
    /**********************************************/
    StringBuffer model = new StringBuffer("");
    for (int i = 24; i < 40; i++) {
        model.append(String.format("%c", lMsg[i]));
    }
    js.setModel(model.toString());
    System.out.println("MODEL:" + model);
    /**********************************************/
    int buildno = process_long(lMsg[40], lMsg[41], lMsg[42], lMsg[43]);
    js.setBuildno(buildno);
    System.out.println("BUILD NO: " + buildno);
    /**********************************************/
    int prot_ver = process_long(lMsg[44], lMsg[45], lMsg[46], lMsg[47]);
    js.setProt_ver(prot_ver);
    System.out.println("PROTOCOL VER: " + prot_ver);
    /**********************************************/
    StringBuffer hw_ver = new StringBuffer("");
    for (int i = 48; i < 64; i++) {
        hw_ver.append(String.format("%c", lMsg[i]));
    }
    js.setHw_ver(hw_ver.toString());
    System.out.println("HARDWARE VERSION:" + hw_ver);
    /**********************************************/
    StringBuffer fw_ver = new StringBuffer("");
    for (int i = 64; i < 80; i++) {
        fw_ver.append(String.format("%c", lMsg[i]));
    }
    js.setFw_ver(fw_ver.toString());
    System.out.println("FIRMWARE VERSION:" + fw_ver);
    /**********************************************/
    int fw_date = process_long(lMsg[80], lMsg[81], lMsg[82], lMsg[83]);
    js.setFw_date(fw_date);
    System.out.println("FIRMWARE DATE: " + fw_date);
    /**********************************************/
    int flag = process_long(lMsg[84], lMsg[85], lMsg[86], lMsg[87]);
    js.setFlag(flag);
    System.out.println("FLAG: " + flag);
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
            js.setHall_sensor(1);
            NSLog(@"Relay warning");
        } else {
            js.setHall_sensor(0);
        }
        uint8_t datatype = lMsg[26];
        uint8_t data = lMsg[27];
        if(data == 0x01){
            js.setRelay(1);
            NSLog(@"Relay is on");
        } else {
            js.setRelay(0);
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
        if(data == 0x01){
            js.setNightlight(1);
            NSLog(@"Nighlight is on");
        } else {
            js.setNightlight(0);
            NSLog(@"Nighlight is off");
        }
    }
}

- (void)get_co_status
{
    int service_id = process_long(lMsg[38], lMsg[39], lMsg[40], lMsg[41]);
    if(service_id == 0xD1000002) {
        int flag = process_long(lMsg[42], lMsg[43], lMsg[44], lMsg[45]);
        if(flag == 0x00000010){
            js.setCo_sensor(1);                                             //WARNING
        } else if (flag == 0x00000100){
            js.setCo_sensor(3);                                             //NOT PLUGGED
        } else {
            js.setCo_sensor(0);                                             //NORMAL
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
    hMsg[12] = (uint8_t) command;
    hMsg[13] = (uint8_t) (command >> 8);
}

@end
