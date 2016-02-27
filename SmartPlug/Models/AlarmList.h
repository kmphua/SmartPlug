//
//  AlarmList.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlarmList : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int alarm_id;
@property (nonatomic, assign) int background;

@end
