//
//  DeviceMainViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/18/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "DeviceMainViewController.h"
#import "DeviceItemSettingsViewController.h"
#import "NoTimersViewController.h"
#import "SetTimerViewController.h"
#import "SetTimerSnoozeViewController.h"
#import "ScheduleMainViewController.h"
#import "IRMainViewController.h"

@interface DeviceMainViewController ()<NoTimersDelegate, SetTimerDelegate, SetSnoozeTimerDelegate, WebServiceDelegate>

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (nonatomic, weak) IBOutlet UIImageView *imgDeviceIcon;
@property (nonatomic, weak) IBOutlet UILabel *lblDeviceName;

@property (weak, nonatomic) IBOutlet UIView *viewOutlet;
@property (weak, nonatomic) IBOutlet UIImageView *imgOutletIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgOutletWarning;
@property (weak, nonatomic) IBOutlet UIButton *btnOutletTimer;

@property (weak, nonatomic) IBOutlet UIView *viewNightLight;
@property (weak, nonatomic) IBOutlet UIImageView *imgNightLightIcon;
@property (weak, nonatomic) IBOutlet UIButton *btnNightLightTimer;

@property (weak, nonatomic) IBOutlet UIView *viewIr;
@property (weak, nonatomic) IBOutlet UIImageView *imgIrIcon;
@property (weak, nonatomic) IBOutlet UIButton *btnIrTimer;

@property (weak, nonatomic) IBOutlet UIView *viewCo;
@property (weak, nonatomic) IBOutlet UIImageView *imgCoIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgCoWarning;

@property (weak, nonatomic) IBOutlet UIView *viewWarning;
@property (weak, nonatomic) IBOutlet UIImageView *imgLeftWarning;
@property (weak, nonatomic) IBOutlet UILabel *lblWarning;
@property (weak, nonatomic) IBOutlet UIImageView *imgRightWarning;

@end

@implementation DeviceMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    
    // See current device info
    g_DeviceName = _device.name;
    g_DeviceGivenName = _device.givenName;
    g_DeviceIp = _device.ip;
    g_DeviceMac = _device.sid;
    
    if (self.device.icon && self.device.icon.length > 0) {
        int iconId = [self.device.icon intValue];
        if (g_DeviceIcons) {
            NSDictionary *icon = [g_DeviceIcons objectAtIndex:iconId-1];
            NSString *imagePath = [icon objectForKey:@"url"];
            [self.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
        }
    }
    
    if (self.device.givenName && self.device.givenName.length > 0) {
        self.lblDeviceName.text = self.device.givenName;
        self.title = self.device.givenName;
    } else {
        self.lblDeviceName.text = self.device.name;
        self.title = self.device.name;
    }
        
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    UITapGestureRecognizer *tapGestureIRButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapIRButton:)];
    [self.viewIr addGestureRecognizer:tapGestureIRButton];
    [self.viewIr setUserInteractionEnabled:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Get device status
    //WebService *ws = [WebService new];
    //ws.delegate = self;
    //[ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:ICON_RES_1x devId:_device.sid];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onRightBarButton:(id)sender {
    DeviceItemSettingsViewController *itemSettingsVc = [[DeviceItemSettingsViewController alloc] initWithNibName:@"DeviceItemSettingsViewController" bundle:nil];
    itemSettingsVc.device = self.device;
    [self.navigationController pushViewController:itemSettingsVc animated:YES];
}

- (void)startBlinkingAnimation:(UIView *)view {
    view.alpha = 1.0f;
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut |
     UIViewAnimationOptionRepeat |
     UIViewAnimationOptionAutoreverse |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         // Do nothing
                     }];
}

- (IBAction)onBtnOutletTimer:(id)sender {
    // Snooze
    SetTimerSnoozeViewController *setTimerSnoozeVC = [[SetTimerSnoozeViewController alloc] initWithNibName:@"SetTimerSnoozeViewController" bundle:nil];
    setTimerSnoozeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    setTimerSnoozeVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    setTimerSnoozeVC.delegate = self;
    [self presentViewController:setTimerSnoozeVC animated:YES completion:nil];
}

- (IBAction)onBtnNightLightTimer:(id)sender {
    // Timer set, no snooze
    SetTimerViewController *setTimerVC = [[SetTimerViewController alloc] initWithNibName:@"SetTimerViewController" bundle:nil];
    setTimerVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    setTimerVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    setTimerVC.delegate = self;
    [self presentViewController:setTimerVC animated:YES completion:nil];
}

- (IBAction)onBtnIRTimer:(id)sender {
    // Timer not set
    NoTimersViewController *noTimersVC = [[NoTimersViewController alloc] initWithNibName:@"NoTimersViewController" bundle:nil];
    noTimersVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    noTimersVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    noTimersVC.delegate = self;
    [self presentViewController:noTimersVC animated:YES completion:nil];
}

- (void)onTapIRButton:(UITapGestureRecognizer *)tapGestureRecognizer {
    IRMainViewController *irVC = [[IRMainViewController alloc] initWithNibName:@"IRMainViewController" bundle:nil];
    [self.navigationController pushViewController:irVC animated:YES];
}

//==================================================================
#pragma mark - UDPListenerDelegate
//==================================================================

- (void)didReceiveData:(NSData *)data fromAddress:(NSString *)address {
    NSString *dataStr = [[NSString alloc] initWithBytes:[data bytes] length:data.length encoding:NSUTF8StringEncoding];
    NSLog(@"M1 - Received data from address %@: %@", address, dataStr);
    NSArray *components = [dataStr componentsSeparatedByString:@"-"];
    if (components && components.count == 5) {
        NSString *devId = [components objectAtIndex:0];
        NSString *currentDevId = @"123";  //[NSString stringWithFormat:@"%ld", [_device.devid integerValue]];
        if ([devId compare:currentDevId] == NSOrderedSame) {
            // Match
            
            // RELAY
            NSString *relayStr = [components objectAtIndex:1];
            NSInteger relayVal = [relayStr integerValue];
            if (relayVal == 1) {
                self.imgOutletIcon.image = [UIImage imageNamed:@"svc_0_big"];
            } else {
                self.imgOutletIcon.image = [UIImage imageNamed:@"svc_0_big_off"];
            }
            
            // NIGHT LED
            NSString *nlStr = [components objectAtIndex:2];
            NSInteger nlVal = [nlStr integerValue];
            if (nlVal == 1) {
                self.imgNightLightIcon.image = [UIImage imageNamed:@"svc_1_big"];
            } else {
                self.imgNightLightIcon.image = [UIImage imageNamed:@"svc_1_big_off"];
            }

            //HALL SENSOR  ( WITH THE PLUG )
            NSString *hoStr = [components objectAtIndex:3];
            NSInteger hoVal = [hoStr integerValue];
            if (hoVal == 1) {
                self.imgLeftWarning.image = [UIImage imageNamed:@"marker_warn2"];
                [self startBlinkingAnimation:self.imgLeftWarning];
                self.lblWarning.text = NSLocalizedString(@"msg_ha_warning", nil);
            } else {
                self.imgLeftWarning.image = [UIImage imageNamed:@"marker_warn"];
                //warning_icon.clearAnimation();
            }
            
            //CO SENSOR
            NSString *coStr = [components objectAtIndex:4];
            NSInteger coVal = [coStr integerValue];
            if (coVal == 1) {
                self.imgCoWarning.image = [UIImage imageNamed:@"marker_warn2"];
                [self startBlinkingAnimation:self.imgCoWarning];
                self.lblWarning.text = NSLocalizedString(@"msg_co_warning", nil);
            } else {
                self.imgCoWarning.image = [UIImage imageNamed:@"marker_warn"];
                //warning_icon_co.clearAnimation();
            }

            if (coVal == 1 || hoVal == 1) {
                [self.viewWarning setHidden:NO];
            } else {
                [self.viewWarning setHidden:YES];
            }
        }
    }
}

//==================================================================
#pragma mark - NoTimersDelegate
//==================================================================
- (void)addTimer
{
    ScheduleMainViewController *scheduleVC = [[ScheduleMainViewController alloc] initWithNibName:@"ScheduleMainViewController" bundle:nil];
    scheduleVC.device = self.device;
    [self.navigationController pushViewController:scheduleVC animated:YES];
}

//==================================================================
#pragma mark - SetTimersDelegate
//==================================================================
- (void)modifyTimer
{
    ScheduleMainViewController *scheduleVC = [[ScheduleMainViewController alloc] initWithNibName:@"ScheduleMainViewController" bundle:nil];
    scheduleVC.device = self.device;
    [self.navigationController pushViewController:scheduleVC animated:YES];
}

- (void)snooze5Mins
{
    
}

- (void)snooze10Mins
{
    
}

- (void)snooze30Mins
{
    
}

- (void)snooze1Hour
{
    
}

//==================================================================
#pragma mark - SetSnoozeTimersDelegate
//==================================================================
- (void)modifySnoozeTimer
{
    ScheduleMainViewController *scheduleVC = [[ScheduleMainViewController alloc] initWithNibName:@"ScheduleMainViewController" bundle:nil];
    scheduleVC.device = self.device;
    [self.navigationController pushViewController:scheduleVC animated:YES];
}

- (void)snooze5MoreMins
{
    
}

- (void)snooze10MoreMins
{
    
}

- (void)snooze30MoreMins
{
    
}

- (void)snooze1MoreHour
{
    
}

- (void)cancelSnooze
{
    
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received data for %@: %@", resultName, dataString);
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        NSLog(@"Error received: %@", [error localizedDescription]);
    }
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *jsonArray = (NSArray *)jsonObject;
        NSLog(@"jsonArray - %@", jsonArray);
    } else {
        NSDictionary *jsonDict = (NSDictionary *)jsonObject;
        NSLog(@"jsonDict - %@", jsonDict);
        
        if ([resultName compare:WS_DEV_GET] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *icon = (NSString *)[jsonObject objectForKey:@"icon"];
                NSString *iconId = (NSString *)[jsonObject objectForKey:@"iconid"];
                NSString *title = (NSString *)[jsonObject objectForKey:@"title"];
                NSString *notifyPower = (NSString *)[jsonObject objectForKey:@"notify_power"];
                NSString *notifyTimer = (NSString *)[jsonObject objectForKey:@"notify_timer"];
                NSString *notifyDanger = (NSString *)[jsonObject objectForKey:@"notify_danger"];
                
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}


@end
