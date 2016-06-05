//
//  UDPCommunication.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/25/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSmartPlug.h"

@interface Command : NSObject

@property (nonatomic, strong) NSString *macID;
@property (nonatomic, assign) short command;
@property (nonatomic, assign) int msgID;

@end

@protocol UDPCommunicationDelegate <NSObject>

- (void)didReceiveData:(NSData *)data fromAddress:(NSString *)address;

@end

@interface UDPCommunication : NSObject

@property (nonatomic, strong) NSMutableArray *IRCodes;
@property (nonatomic, strong) JSmartPlug *js;

@property (nonatomic, assign) id<UDPCommunicationDelegate> delegate;

+ (UDPCommunication *)getInstance;

- (Command *)dequeueCommandByIp:(NSString *)ip msgID:(int)msgID;
- (Command *)dequeueCommand:(NSString *)macID msgID:(int)msgID;

- (BOOL)delayTimer:(NSString *)macId snooze:(int)snooze protocol:(int)protocol serviceId:(int)serviceId send:(int)send;
- (BOOL)queryDevices:(NSString *)macId command:(short)command;
- (BOOL)sendIRMode:(NSString *)macId;
- (BOOL)cancelIRMode:(NSString *)macId;
- (BOOL)sendOTACommand:(NSString *)macId;
- (BOOL)sendReformatCommand:(NSString *)macId;
- (BOOL)sendResetCommand:(NSString *)macId;
- (BOOL)sendIRFileName:(NSString *)macId filename:(int)filename;
- (void)sendIRHeader:(NSString *)macId filename:(int)filename;
- (BOOL)sendTimers:(NSString *)macId;
- (BOOL)sendTimersHTTP:(NSString *)macId send:(int)send;
- (BOOL)sendTimers:(NSString *)macId protocol:(int)protocol;
- (BOOL)setDeviceStatus:(NSString *)macID serviceId:(int)serviceId action:(uint8_t)action;

@end
