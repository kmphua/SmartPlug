//
//  InitDevicesViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InitDevicesDelegate <NSObject>

- (void)ssidPassword:(NSString *)password;

@end

@interface InitDevicesViewController : UIViewController

@property (nonatomic, assign) NSString *ssid;
@property (nonatomic, assign) id<InitDevicesDelegate> delegate;

@end
