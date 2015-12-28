//
//  UDPCommunication.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/25/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UDPCommunication : NSObject

- (BOOL)runUdpServer;
- (void)runUdpClient:(NSString *)ip msg:(NSString *)msg;

@end
