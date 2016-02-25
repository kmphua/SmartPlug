//
//  ScheduleMainViewCell.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScheduleMainViewCellDelegate <NSObject>

- (void)onClickBtnEdit;
- (void)onClickBtnDelete;

@end

@interface ScheduleMainViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lblScheduleTime;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UIImageView *imgDeviceIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgDeviceAction;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;

@property (nonatomic, assign) id<ScheduleMainViewCellDelegate> delegate;

@end
