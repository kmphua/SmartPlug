//
//  BroadcastReply.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/16/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BroadcastReply : NSObject

@property (nonatomic, assign) int broadcast_id;
@property (nonatomic, assign) int relay;
@property (nonatomic, assign) int nightled;
@property (nonatomic, assign) int co;
@property (nonatomic, assign) int ha;

@end
