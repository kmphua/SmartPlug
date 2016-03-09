//
//  NoTimersViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NoTimersDelegate <NSObject>

- (void)addTimer:(int)serviceId;

@end

@interface NoTimersViewController : UIViewController

@property (nonatomic, assign) id<NoTimersDelegate> delegate;

@property (nonatomic, assign) NSString *devId;
@property (nonatomic, assign) int serviceId;

@end
