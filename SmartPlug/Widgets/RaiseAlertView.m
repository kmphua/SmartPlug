//
//  RaiseAlertView.m
//  Raise
//
//  Created by Kevin Phua on 11/25/15.
//  Copyright © 2015 hagarsoft. All rights reserved.
//

#import "RaiseAlertView.h"

@implementation RaiseAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle {
    
    self = [super initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitle:otherButtonTitle];

    CGRect bounds = CGRectMake(0, 0, 320, 200);
    UIGraphicsBeginImageContext(CGSizeMake(320, 200));
    [[UIImage imageNamed:@"dialog_bkgnd"] drawInRect:bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.backgroundColor = [UIColor colorWithPatternImage:image];
    self.hideSeperator = YES;
    self.customFrame = CGRectMake(0, 0, 320, 180);
    self.titleHeight = 60;
    self.messageLeftRightPadding = 50;
    self.center = CGPointMake(([UIScreen mainScreen].bounds.size.width)/2, ([UIScreen mainScreen].bounds.size.height)/2);
    
    return self;
}

@end
