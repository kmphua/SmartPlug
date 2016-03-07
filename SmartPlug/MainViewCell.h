//
//  MainViewCell.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MainViewCellDelegate <NSObject>

- (void)onClickBtnWarn:(id)sender;
- (void)onClickBtnTimer:(id)sender;
- (void)onClickBtnPower:(id)sender;

@end

@interface MainViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgCellBg;
@property (weak, nonatomic) IBOutlet UIImageView *imgDeviceIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UIButton *btnWarn;
@property (weak, nonatomic) IBOutlet UIButton *btnTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnPower;

@property (nonatomic, assign) id<MainViewCellDelegate> delegate;

@end
