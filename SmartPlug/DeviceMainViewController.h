//
//  DeviceMainViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/18/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"
#import "JSmartPlug.h"

@interface DeviceMainViewController : BaseViewController

@property (nonatomic, strong) JSmartPlug *device;

@end
