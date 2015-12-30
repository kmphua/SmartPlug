//
//  UDPListenerService.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/30/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UDPListenerDelegate <NSObject>

- (void)didReceiveData:(NSData *)data fromAddress:(NSString *)address;

@end

@interface UDPListenerService : NSObject

@property (nonatomic, assign) id<UDPListenerDelegate> delegate;

+ (UDPListenerService *)getInstance;
- (BOOL)startUdpBroadcastListener;
- (void)stopUdpBroadcastListener;

@end
