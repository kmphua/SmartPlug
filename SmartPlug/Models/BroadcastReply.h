//
//  BroadcastReply.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/16/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BroadcastReply : NSObject

@property (nonatomic) int broadcast_id;
@property (nonatomic) int relay;
@property (nonatomic) int nightled;
@property (nonatomic) int co;
@property (nonatomic) int ha;

@end
