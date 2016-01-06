//
//  JSAction.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSAction : NSObject

@property (nonatomic, strong) NSString *device;
@property (nonatomic, strong) NSString *deviceIcon;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *typeIcon;

@end
