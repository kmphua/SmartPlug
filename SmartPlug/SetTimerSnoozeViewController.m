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
    
    NSString *title = [NSString stringWithFormat:@"%@",NSLocalizedString(@"TimersSet", nil)];
    
    self.lblTitle.text = title;
    [self.btnAddTimer setTitle:NSLocalizedString(@"AddNewTimer", nil) forState:UIControlStateNormal];
    [self.btnShowModifyTimer setTitle:NSLocalizedString(@"ShowModifyTimer", nil) forState:UIControlStateNormal];
    [self.btnSnooze5Mins setTitle:NSLocalizedString(@"Snooze5Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze10Mins setTitle:NSLocalizedString(@"Snooze10Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze30Mins setTitle:NSLocalizedString(@"Snooze30Minutes", nil) forState:UIControlStateNormal];
    [self.btnSnooze1Hour setTitle:NSLocalizedString(@"Snooze1Hour", nil) forState:UIControlStateNormal];
    
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
        for (Alarm *alarm in alarms) {
            NSString *service = @"";
            NSMutableString *dow = [NSMutableString new];
            int background = 0;
            
            if (alarm.service_id == RELAY_SERVICE) {
                service = @"Plug";
            } else if(alarm.service_id == NIGHTLED_SERVICE) {
                service = @"Nightlight";
            }
            
            int intdow = alarm.dow;
            /* returns 1-7. Sun-1, Mon-2 ... Sat-7 */
            if(((intdow >> 1) & 1) == 1){
                [dow appendString:@"Su"];
            }
            if(((intdow >> 2) & 1) == 1){
                [dow appendString:@"Mo"];
            }
            if(((intdow >> 3) & 1) == 1){
                [dow appendString:@"Tu"];
            }
            if(((intdow >> 4) & 1) == 1){
                [dow appendString:@"We"];
            }
            if(((intdow >> 5) & 1) == 1){
                [dow appendString:@"Th"];
            }
            if(((intdow >> 6) & 1) == 1){
                [dow appendString:@"Fr"];
            }
            if(((intdow >> 7) & 1) == 1){
                [dow appendString:@"Sa"];
            }
            
            [timerStr appendFormat:@"%02d:%02d   %02d:%02d   %@   %@\n", alarm.initial_hour, alarm.initial_minute, alarm.end_hour, alarm.end_minute, service, dow];
        }
    }
    
    self.lblTimer.text = timerStr;
    self.lblTimer.numberOfLines = 0;
    [self.lblTimer sizeToFit];
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
