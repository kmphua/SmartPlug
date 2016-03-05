//
//  IrGroupViewCell.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IrGroupViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgCellBg;
@property (weak, nonatomic) IBOutlet UIImageView *imgDeviceIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;

@end
