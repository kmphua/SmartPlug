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
@property (weak, nonatomic) IBOutlet UIButton *btnAddTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnShowModifyTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze5Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze10Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze30Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze1Hour;

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
    [self.btnAddTimer setTitle:NSLocalizedString(@"AddNewTimer", nil) forState:UIControlStateNormal];
    [self.btnShowModifyTimer setTitle:NSLocalizedString(@"ShowModifyTimer", nil) forState:UIControlStateNormal];
    [self.btnSnooze5Mins setTitle:NSLocalizedString(@"Snooze5Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze10Mins setTitle:NSLocalizedString(@"Snooze10Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze30Mins setTitle:NSLocalizedString(@"Snooze30Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze1Hour setTitle:NSLocalizedString(@"Snooze1Hour", nil) forState:UIControlStateNormal];
    
    self.lblTimer.text = @"10:30 - 12:00 TWM\n12:30 - 20:00 FS";
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSetTimerDelay:) name:NOTIFICATION_SET_TIMER_DELAY object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_SET_TIMER_DELAY object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleSetTimerDelay:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        int code = [[userInfo objectForKey:@"code"] intValue];
        if (code == 0) {
            [self.view makeToast:NSLocalizedString(@"SnoozeSentSuccess", nil)
                        duration:3.0
                        position:CSToastPositionCenter];
        } else {
            [self.view makeToast:NSLocalizedString(@"ErrorPleaseTryAgain", nil)
                        duration:3.0
                        position:CSToastPositionCenter];
        }
    }
}

- (void)onTapView:(UITapGestureRecognizer *)tapGesture
{
    // Dismiss view
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnAddTimer:(id)sender {
    [self.delegate addTimer:self.alarmId serviceId:self.serviceId];
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
