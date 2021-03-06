//
//  ScheduleMainViewCell.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "ScheduleMainViewCell.h"

@implementation ScheduleMainViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onBtnEdit:(id)sender {
    UITableView *tableView = (UITableView *)self.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:self.center];
    [self.delegate onClickBtnEdit:indexPath];
}

- (IBAction)onBtnDelete:(id)sender {
    UITableView *tableView = (UITableView *)self.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:self.center];
    [self.delegate onClickBtnDelete:indexPath];
}

@end
