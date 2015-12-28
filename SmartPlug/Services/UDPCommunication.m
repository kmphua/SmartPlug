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

#define MAX_UDP_DATAGRAM_LEN        64
#define UDP_SERVER_PORT             2390

@interface UDPCommunication()

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic) BOOL isRunning;

@end

@implementation UDPCommunication

- (BOOL)runUdpServer {
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

- (void)runUdpClient:(NSString *)ip msg:(NSString *)msg {
    if (!_udpSocket) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }

    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [_udpSocket sendData:data toHost:ip port:UDP_SERVER_PORT withTimeout:-1 tag:0];
    NSLog(@"sent message %@ to server at %@", msg, ip);
}


@end
