//
//  JSmartPlug.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/25/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSmartPlug : NSObject

@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *server;
@property (nonatomic) int plugId;

@end
