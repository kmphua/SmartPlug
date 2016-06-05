//
//  IRRecordViewController.h
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "BaseViewController.h"

@protocol IRRecordDelegate <NSObject>

- (void)onSaveIRRecord;

@end

@interface IRRecordViewController : BaseViewController<WebServiceDelegate>

@property (nonatomic, assign) int groupId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) UIImage *customIcon;
@property (nonatomic, assign) BOOL isCustomIcon;
@property (nonatomic, assign) id<IRRecordDelegate> delegate;

@end
