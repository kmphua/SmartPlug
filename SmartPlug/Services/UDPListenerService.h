//
//  UDPListenerService.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/30/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UDPListenerService : NSObject

@property (nonatomic, strong) JSmartPlug *js;

+ (UDPListenerService *)getInstance;
- (BOOL)startUdpBroadcastListener;
- (void)stopUdpBroadcastListener;
- (BOOL)isRunning;
- (BOOL)setDeviceStatusProcess:(NSString *)ip serviceId:(int)serviceId action:(uint8_t)action;

@end
