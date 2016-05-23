//
//  DeviceIconViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/28/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DeviceIconDelegate <NSObject>

- (void)selectedIcon:(NSString *)icon;
- (void)selectedImage:(UIImage *)image;

@end

@interface DeviceIconViewController : UIViewController

@property (nonatomic, assign) id<DeviceIconDelegate> delegate;

@end
