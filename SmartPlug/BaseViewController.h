//
//  BaseViewController.h
//  Raise
//
//  Created by Kevin Phua on 11/5/15.
//  Copyright © 2015 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

@property (nonatomic, strong) UIView *viewNetworkError;
@property (nonatomic, strong) UIView *viewDownloadError;

- (void)updateNavigationBarButtons;
- (void)clearNavigationBarButtons;

@end
