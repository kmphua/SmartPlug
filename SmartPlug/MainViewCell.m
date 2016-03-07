//
//  MainViewCell.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "MainViewCell.h"

@implementation MainViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onBtnWarn:(id)sender {
    [self.delegate onClickBtnWarn:sender];
}

- (IBAction)onBtnTimer:(id)sender {
    [self.delegate onClickBtnTimer:sender];
}

- (IBAction)onBtnPower:(id)sender {
    [self.delegate onClickBtnPower:sender];
}

@end
