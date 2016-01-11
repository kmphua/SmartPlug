//
//  SetTimerSnoozeViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "SetTimerSnoozeViewController.h"

@interface SetTimerSnoozeViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIImageView *imgBackground;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnShowModifyTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze5MoreMins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze10MoreMins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze30MoreMins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze1MoreHour;
@property (weak, nonatomic) IBOutlet UIButton *btnCancelSnooze;

@end

@implementation SetTimerSnoozeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    
    UIImage *originalImage = [UIImage imageNamed:@"dialog_bkgnd"];
    UIEdgeInsets insets = UIEdgeInsetsMake(65, 20, 20, 20);
    UIImage *stretchableImage = [originalImage resizableImageWithCapInsets:insets];
    self.imgBackground.image = stretchableImage;
    
    NSString *title = [NSString stringWithFormat:@"%@ (%@ 01h00m)",NSLocalizedString(@"TimersSet", nil), NSLocalizedString(@"Snoozing", nil)];
    
    self.lblTitle.text = title;
    [self.btnShowModifyTimer setTitle:NSLocalizedString(@"ShowModifyTimer", nil) forState:UIControlStateNormal];
    [self.btnSnooze5MoreMins setTitle:NSLocalizedString(@"Snooze5MoreMinutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze10MoreMins setTitle:NSLocalizedString(@"Snooze10MoreMinutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze30MoreMins setTitle:NSLocalizedString(@"Snooze30MoreMinutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze1MoreHour setTitle:NSLocalizedString(@"Snooze1MoreHour", nil) forState:UIControlStateNormal];
    [self.btnCancelSnooze setTitle:NSLocalizedString(@"CancelSnooze", nil) forState:UIControlStateNormal];
    
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze5MoreMins:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze10MoreMins:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze30MoreMins:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnSnooze1MoreHour:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnCancelSnooze:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
