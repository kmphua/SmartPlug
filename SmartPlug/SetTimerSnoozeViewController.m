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
@property (weak, nonatomic) IBOutlet UITextView *txtTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnAddTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnShowModifyTimer;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze5Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze10Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze30Mins;
@property (weak, nonatomic) IBOutlet UIButton *btnSnooze1Hour;
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
    
    UIImage *buttonImage = [UIImage imageNamed:@"btn_bkgnd"];
    UIEdgeInsets btnInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    UIImage *stretchableBtnImage = [buttonImage resizableImageWithCapInsets:btnInsets];
    [self.btnAddTimer setBackgroundImage:stretchableBtnImage forState:UIControlStateNormal];
    [self.btnShowModifyTimer setBackgroundImage:stretchableBtnImage forState:UIControlStateNormal];
    [self.btnSnooze5Mins setBackgroundImage:stretchableBtnImage forState:UIControlStateNormal];
    [self.btnSnooze10Mins setBackgroundImage:stretchableBtnImage forState:UIControlStateNormal];
    [self.btnSnooze30Mins setBackgroundImage:stretchableBtnImage forState:UIControlStateNormal];
    [self.btnSnooze1Hour setBackgroundImage:stretchableBtnImage forState:UIControlStateNormal];
    [self.btnCancelSnooze setBackgroundImage:stretchableBtnImage forState:UIControlStateNormal];
    
    NSString *title = [NSString stringWithFormat:@"%@",NSLocalizedString(@"timer_set", nil)];
    
    self.lblTitle.text = title;
    [self.btnAddTimer setTitle:NSLocalizedString(@"add_new_timer", nil) forState:UIControlStateNormal];
    [self.btnShowModifyTimer setTitle:NSLocalizedString(@"show_modify_timer", nil) forState:UIControlStateNormal];
    [self.btnCancelSnooze setTitle:NSLocalizedString(@"cancel_snooze", nil) forState:UIControlStateNormal];
    
    if (_alarmCount <= 0) {
        self.lblTitle.text = NSLocalizedString(@"no_timer_set", nil);
        [self.btnShowModifyTimer setHidden:YES];
        [self.btnSnooze5Mins setHidden:YES];
        [self.btnSnooze10Mins setHidden:YES];
        [self.btnSnooze30Mins setHidden:YES];
        [self.btnSnooze1Hour setHidden:YES];
        [self.btnCancelSnooze setHidden:YES];
        [self.btnAddTimer setHidden:NO];
    } else {
        [self.btnShowModifyTimer setHidden:NO];
        [self.btnSnooze5Mins setHidden:NO];
        [self.btnSnooze10Mins setHidden:NO];
        [self.btnSnooze30Mins setHidden:NO];
        [self.btnSnooze1Hour setHidden:NO];
        [self.btnCancelSnooze setHidden:NO];
        [self.btnAddTimer setHidden:YES];
        
        if (_snooze > 0) {
            [self.btnSnooze5Mins setTitle:NSLocalizedString(@"delay_plus_five", nil) forState:UIControlStateNormal];
            [self.btnSnooze10Mins setTitle:NSLocalizedString(@"delay_plus_ten", nil) forState:UIControlStateNormal];
            [self.btnSnooze30Mins setTitle:NSLocalizedString(@"delay_plus_thirty", nil) forState:UIControlStateNormal];
            [self.btnSnooze1Hour setTitle:NSLocalizedString(@"delay_plus_sixty", nil) forState:UIControlStateNormal];
            [self.btnCancelSnooze setHidden:NO];
        } else {
            [self.btnSnooze5Mins setTitle:NSLocalizedString(@"Snooze_5_Minutes", nil) forState:UIControlStateNormal];
            [self.btnSnooze10Mins setTitle:NSLocalizedString(@"Snooze_10_Minutes", nil) forState:UIControlStateNormal];
            [self.btnSnooze30Mins setTitle:NSLocalizedString(@"Snooze_30_Minutes", nil) forState:UIControlStateNormal];
            [self.btnSnooze1Hour setTitle:NSLocalizedString(@"Snooze_1_Hour", nil) forState:UIControlStateNormal];
            [self.btnCancelSnooze setHidden:YES];
        }
    }
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self populateAlarmList];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSetTimerDelay:) name:NOTIFICATION_SET_TIMER_DELAY object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.txtTimer scrollRangeToVisible:NSMakeRange(0,0)];
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

- (void)populateAlarmList
{
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_devId serviceId:_serviceId];
    NSMutableString *timerStr = [NSMutableString new];
    
    if (alarms && alarms.count>0) {
        NSLog(@"No. of alarms = %ld", alarms.count);
        for (Alarm *alarm in alarms) {
            NSString *service = @"";
            NSMutableString *dow = [NSMutableString new];
            //int background = 0;
            
            if (alarm.service_id == RELAY_SERVICE) {
                service = NSLocalizedString(@"btn_outlet", nil);
            } else if(alarm.service_id == NIGHTLED_SERVICE) {
                service = NSLocalizedString(@"btn_nightLight", nil);
            }
            
            int intdow = alarm.dow;
            /* returns 1-7. Sun-1, Mon-2 ... Sat-7 */
            if(((intdow >> 0) & 1) == 1){
                [dow appendString:NSLocalizedString(@"sunday", nil)];
            }
            if(((intdow >> 1) & 1) == 1){
                [dow appendString:NSLocalizedString(@"monday", nil)];
            }
            if(((intdow >> 2) & 1) == 1){
                [dow appendString:NSLocalizedString(@"tuesday", nil)];
            }
            if(((intdow >> 3) & 1) == 1){
                [dow appendString:NSLocalizedString(@"wednesday", nil)];
            }
            if(((intdow >> 4) & 1) == 1){
                [dow appendString:NSLocalizedString(@"thursday", nil)];
            }
            if(((intdow >> 5) & 1) == 1){
                [dow appendString:NSLocalizedString(@"friday", nil)];
            }
            if(((intdow >> 6) & 1) == 1){
                [dow appendString:NSLocalizedString(@"saturday", nil)];
            }
            
            [timerStr appendFormat:@"%02d:%02d-%02d:%02d   %@\n", alarm.initial_hour, alarm.initial_minute, alarm.end_hour, alarm.end_minute, dow];
        }
    }
    
    self.txtTimer.text = timerStr;
    [self.txtTimer sizeToFit];
}

- (void)handleSetTimerDelay:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        int code = [[userInfo objectForKey:@"code"] intValue];
        if (code == 0) {
            [self.view makeToast:NSLocalizedString(@"SnoozeSentSuccess", nil)
                        duration:3.0
                        position:CSToastPositionBottom];
        } else {
            [self.view makeToast:NSLocalizedString(@"ErrorPleaseTryAgain", nil)
                        duration:3.0
                        position:CSToastPositionBottom];
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

- (IBAction)onBtnCancelSnooze:(id)sender {
    [self.delegate cancelSnooze:self.alarmId serviceId:self.serviceId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
