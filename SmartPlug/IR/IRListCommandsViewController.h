//
//  IRListCommandsViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 5/16/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"

@protocol IRListCommandsDelegate <NSObject>

- (void)onSelectIRCommand:(int)status group:(NSString *)group irName:(NSString *)irName;

@end

@interface IRListCommandsViewController : BaseViewController

@property (nonatomic, assign) int status;
@property (nonatomic, assign) id<IRListCommandsDelegate> delegate;

@end
