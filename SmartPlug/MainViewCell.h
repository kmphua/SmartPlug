//
//  MainViewCell.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgCellBg;
@property (weak, nonatomic) IBOutlet UIImageView *imgDeviceIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UIButton *btnWarn;
@property (weak, nonatomic) IBOutlet UIButton *btnTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnPower;

@end
