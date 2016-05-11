//
//  IrGroup.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IrGroup : NSObject

@property (nonatomic, assign) int group_id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, assign) int position;
@property (nonatomic, assign) int sid;
@property (nonatomic, copy) NSString *mac;

@end
