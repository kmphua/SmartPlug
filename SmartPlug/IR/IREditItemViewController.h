//
//  IREditItemViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"

@protocol IREditItemDelegate <NSObject>

- (void)onAddedIRGroup;

@end

@interface IREditItemViewController : BaseViewController<WebServiceDelegate>

@property (nonatomic, assign) id<IREditItemDelegate> delegate;

@end
