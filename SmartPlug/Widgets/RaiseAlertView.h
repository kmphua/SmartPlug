//
//  RaiseAlertView.h
//  Raise
//
//  Created by Kevin Phua on 11/25/15.
//  Copyright © 2015 hagarsoft. All rights reserved.
//

#import "DQAlertView.h"

@interface RaiseAlertView : DQAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle;

@end
