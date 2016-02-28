//
//  SelectActionViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"
//#import "JSAction.h"

@protocol SelectActionDelegate <NSObject>


//- (void)didSelectAction:(JSAction *)action;

@end

@interface SelectActionViewController : BaseViewController

@property (nonatomic, assign) id<SelectActionDelegate> delegate;

@end
