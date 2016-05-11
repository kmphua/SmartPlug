//
//  UDPCommunication.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/25/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSmartPlug.h"

@protocol UDPCommunicationDelegate <NSObject>

- (void)didReceiveData:(NSData *)data fromAddress:(NSString *)address;

@end

@interface UDPCommunication : NSObject

@property (nonatomic, strong) NSMutableArray *IRCodes;
@property (nonatomic, strong) JSmartPlug *js;

@property (nonatomic, assign) id<UDPCommunicationDelegate> delegate;

+ (UDPCommunication *)getInstance;

- (BOOL)delayTimer:(int)seconds protocol:(int)protocol serviceId:(int)serviceId send:(int)send;
- (BOOL)listenForIRCodes;
- (BOOL)queryDevices:(NSString *)ip udpMsg_param:(short)udpMsg_param;
- (BOOL)sendIRMode:(NSString *)ip;
- (BOOL)cancelIRMode;
- (BOOL)sendOTACommand:(NSString *)ip;
- (BOOL)sendReformatCommand:(NSString *)ip;
- (BOOL)sendResetCommand:(NSString *)ip;
- (BOOL)sendIRFileName:(int)filename;
- (void)sendIRHeader:(int)filename;
- (BOOL)setDeviceTimersHTTP:(NSString *)devId send:(int)send;
- (BOOL)setDeviceTimersUDP:(NSString *)devId;
- (BOOL)sendTimers:(NSString *)devId ip:(NSString *)ip;
- (BOOL)sendTimersHTTP:(NSString *)devId send:(int)send;
- (BOOL)sendTimerTerminator:(NSString *)ip protocol:(int)protocol;
- (BOOL)sendTimerHeaders:(NSString *)ip protocol:(int)protocol;
- (BOOL)sendTimers:(NSString *)devId protocol:(int)protocol;
- (BOOL)setDeviceStatus:(NSString *)ip serviceId:(int)serviceId action:(uint8_t)action;
- (void)process_headers;
- (void)process_query_device_command;
- (void)process_get_device_status;

@end
