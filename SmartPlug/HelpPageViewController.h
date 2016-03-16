//
//  HelpPageViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 03/16/16.
//  Copyright © 2016 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HelpViewController.h"

@interface HelpPageViewController : UIViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic) NSUInteger startIndex;

@end
