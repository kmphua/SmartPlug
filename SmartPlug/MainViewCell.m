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
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:self.center];
    [self.delegate onClickBtnWarn:indexPath];
}

- (IBAction)onBtnTimer:(id)sender {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:self.center];
    [self.delegate onClickBtnTimer:indexPath];
}

- (IBAction)onBtnPower:(id)sender {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:self.center];
    [self.delegate onClickBtnPower:indexPath];
}

@end
