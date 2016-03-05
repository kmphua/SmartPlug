//
//  IRRecordViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRRecordViewController.h"

@interface IRRecordViewController ()

@property (nonatomic, weak) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UIImageView *imgWait;
@property (nonatomic, weak) IBOutlet UIButton *btnRecordAgain;
@property (nonatomic, weak) IBOutlet UIButton *btnTestCommand;
@property (nonatomic, weak) IBOutlet UIButton *btnAddNow;

@property (nonatomic) BOOL searching;

@end

@implementation IRRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.lblMessage.text = NSLocalizedString(@"msg_recordIr", nil);
    [self.btnRecordAgain setTitle:NSLocalizedString(@"btn_recordAgain", nil) forState:UIControlStateNormal];
    [self.btnTestCommand setTitle:NSLocalizedString(@"btn_testCommand", nil) forState:UIControlStateNormal];
    [self.btnAddNow setTitle:NSLocalizedString(@"btn_addNow", nil) forState:UIControlStateNormal];
        
    // Load animation images
    NSArray *waitImageNames = @[@"wait_0.png", @"wait_1.png", @"wait_2.png",
                                @"wait_3.png", @"wait_4.png", @"wait_5.png",
                                @"wait_6.png", @"wait_7.png"];
    NSMutableArray *waitImages = [[NSMutableArray alloc] init];
    for (int i = 0; i < waitImageNames.count; i++) {
        [waitImages addObject:[UIImage imageNamed:[waitImageNames objectAtIndex:i]]];
    }
    self.imgWait.animationImages = waitImages;
    self.imgWait.animationDuration = 0.5;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateUI {
    if (self.searching) {
        [self.imgWait startAnimating];
    }
    else {
        [self.imgWait stopAnimating];
    }
}

- (IBAction)onBtnRecordAgain:(id)sender {
    self.searching = YES;
    [self updateUI];
}

- (IBAction)onBtnTestCommand:(id)sender {
    
}

- (IBAction)onBtnAddNow:(id)sender {
    self.searching = YES;
    [self updateUI];
}

@end
