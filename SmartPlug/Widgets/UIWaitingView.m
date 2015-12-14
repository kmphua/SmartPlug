//
//  UIWaitingView.m
//  FarGlory
//
//  Created by Kevin Phua on 9/4/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "UIWaitingView.h"
#import "AppDelegate.h"

@interface UIWaitingView ()

@property(nonatomic, retain) UIActivityIndicatorView* aiView;

@end

@implementation UIWaitingView

#pragma mark -
#pragma mark View create and destroy

- (id)init {
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
		self.aiView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 37, 37)];
		self.aiView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
		self.aiView.hidesWhenStopped = YES;
        [self.aiView setTranslatesAutoresizingMaskIntoConstraints:NO];
		[self addSubview:self.aiView];
        
        NSLayoutConstraint *xConstraint = [NSLayoutConstraint
                                           constraintWithItem:self.aiView
                                           attribute:NSLayoutAttributeCenterX
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self
                                           attribute:NSLayoutAttributeCenterX
                                           multiplier:1.0
                                           constant:0];
        
        NSLayoutConstraint *yConstraint = [NSLayoutConstraint
                                           constraintWithItem:self.aiView
                                           attribute:NSLayoutAttributeCenterY
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self
                                           attribute:NSLayoutAttributeCenterY
                                           multiplier:1.0
                                           constant:0];
        
        [self addConstraint:xConstraint];
        [self addConstraint:yConstraint];
    }
    return self;
}


#pragma mark -
#pragma mark View show and dismiss

- (void)show:(UIView*)parentView {
	[self.aiView startAnimating];
	[parentView addSubview:self];
}

- (void)dismiss {
	[self.aiView stopAnimating];
	[self removeFromSuperview];
}

@end
