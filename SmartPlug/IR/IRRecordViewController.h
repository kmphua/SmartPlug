//
//  IRRecordViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"

@interface IRRecordViewController : BaseViewController

@property (nonatomic, assign) int groupId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *icon;

@end
