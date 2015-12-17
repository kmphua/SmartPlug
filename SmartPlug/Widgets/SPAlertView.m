//
//  SPAlertView.m
//  SmartPlug
//
//  Created by Kevin Phua on 11/25/15.
//  Copyright © 2015 hagarsoft. All rights reserved.
//

#import "SPAlertView.h"

@implementation SPAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle {
    
    self = [super initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitle:otherButtonTitle];

    UIImage *originalImage = [UIImage imageNamed:@"dialog_bkgnd"];
    UIEdgeInsets insets = UIEdgeInsetsMake(50, 20, 20, 20);
    UIImage *stretchableImage = [originalImage resizableImageWithCapInsets:insets];

    CGRect bounds = CGRectMake(0, 0, 300, 360);
    UIGraphicsBeginImageContext(CGSizeMake(300, 360));
    [stretchableImage drawInRect:bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.customFrame = CGRectMake(0, 0, 300, 360);
    self.backgroundColor = [UIColor colorWithPatternImage:image];
    self.hideSeperator = YES;
    self.titleHeight = 80;
    self.messageLeftRightPadding = 20;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.messageLabel.font = [UIFont systemFontOfSize:16];
    
    self.center = CGPointMake(([UIScreen mainScreen].bounds.size.width)/2, ([UIScreen mainScreen].bounds.size.height)/2);
    
    return self;
}

@end
