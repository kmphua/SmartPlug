//
//  UIWaitingView.h
//  FarGlory
//
//  Created by Kevin Phua on 9/4/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWaitingView : UIView

- (id) init;
- (void) show:(UIView*)parentView;
- (void) dismiss;

@end
