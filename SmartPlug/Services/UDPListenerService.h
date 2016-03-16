//
//  UDPListenerService.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/30/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UDPListenerService : NSObject

+ (UDPListenerService *)getInstance;
- (BOOL)startUdpBroadcastListener;
- (void)stopUdpBroadcastListener;
- (BOOL)isRunning;

@end
