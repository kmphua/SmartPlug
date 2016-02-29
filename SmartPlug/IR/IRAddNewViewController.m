//
//  IRAddNewViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 2/29/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRAddNewViewController.h"

@interface IRAddNewViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIView *viewChoose;
@property (weak, nonatomic) IBOutlet UIView *viewDetect;
@property (weak, nonatomic) IBOutlet UIView *viewCreate;

@end

@implementation IRAddNewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"ir_add_new", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    self.viewChoose.layer.cornerRadius = CORNER_RADIUS;
    self.viewDetect.layer.cornerRadius = CORNER_RADIUS;
    self.viewCreate.layer.cornerRadius = CORNER_RADIUS;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
