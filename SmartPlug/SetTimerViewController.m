//
//  SetTimerViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "SetTimerViewController.h"

@interface SetTimerViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIImageView *imgBackground;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnShowModifyTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze5Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze10Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze30Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze1Hour;

@end

@implementation SetTimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    
    UIImage *originalImage = [UIImage imageNamed:@"dialog_bkgnd"];
    UIEdgeInsets insets = UIEdgeInsetsMake(65, 20, 20, 20);
    UIImage *stretchableImage = [originalImage resizableImageWithCapInsets:insets];
    self.imgBackground.image = stretchableImage;
    
    self.lblTitle.text = NSLocalizedString(@"NoTimersSet", nil);
    [self.btnShowModifyTimer setTitle:NSLocalizedString(@"ShowModifyTimer", nil) forState:UIControlStateNormal];
    [self.btnSnooze5Mins setTitle:NSLocalizedString(@"Snooze5Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze10Mins setTitle:NSLocalizedString(@"Snooze10Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze30Mins setTitle:NSLocalizedString(@"Snooze30Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze1Hour setTitle:NSLocalizedString(@"Snooze1Hour", nil) forState:UIControlStateNormal];
    
    self.lblTimer.text = @"10:30 - 12:00 TWM\n12:30 - 20:00 FS";
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onTapView:(UITapGestureRecognizer *)tapGesture
{
    // Dismiss view
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnShowModifyTimer:(id)sender {
    [self.delegate modifyTimer:self.alarmId serviceId:self.serviceId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze5Mins:(id)sender {
    [self.delegate snooze5Mins:self.alarmId serviceId:self.serviceId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze10Mins:(id)sender {
    [self.delegate snooze10Mins:self.alarmId serviceId:self.serviceId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze30Mins:(id)sender {
    [self.delegate snooze30Mins:self.alarmId serviceId:self.serviceId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze1Hour:(id)sender {
    [self.delegate snooze1Hour:self.alarmId serviceId:self.serviceId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
