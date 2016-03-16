//
//  DeviceItemSettingsViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"
#import "JSmartPlug.h"

@interface DeviceItemSettingsViewController : BaseViewController<WebServiceDelegate>

@property (nonatomic, assign) JSmartPlug *device;

@end
