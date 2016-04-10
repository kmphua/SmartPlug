//
//  IrCode.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IrCode : NSObject

@property (nonatomic, assign) int code_id;
@property (nonatomic, assign) int group_id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int filename;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *mac;
@property (nonatomic, assign) int position;
@property (nonatomic, copy) NSString *brand;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, assign) int sid;

@end
