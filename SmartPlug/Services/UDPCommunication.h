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
@property (nonatomic) short command;

@property (nonatomic, assign) id<UDPCommunicationDelegate> delegate;


+ (UDPCommunication *)getInstance;
- (BOOL)runUdpServer;
- (void)runUdpClient:(NSString *)ip msg:(NSString *)msg;

@end
