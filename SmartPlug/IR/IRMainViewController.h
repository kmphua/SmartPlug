//
//  IRMainViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/18/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"
#import "JSmartPlug.h"

@interface IRMainViewController : BaseViewController

@property (nonatomic, assign) JSmartPlug *device;

@end
