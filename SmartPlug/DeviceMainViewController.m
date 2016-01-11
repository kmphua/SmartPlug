//
//  DeviceMainViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/18/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "DeviceMainViewController.h"
#import "DeviceItemSettingsViewController.h"
#import "UDPListenerService.h"
#import "NoTimersViewController.h"

@interface DeviceMainViewController ()<UDPListenerDelegate>

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

@property (strong, nonatomic) UDPListenerService *udpListener;

@end

@implementation DeviceMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.imgDeviceIcon.image = [UIImage imageNamed:@"see_Table Lamps_1_white_bkgnd"];
    //self.lblDeviceName.text = _device.name;
    //self.title = _device.name;
    self.lblDeviceName.text = [_device objectForKey:@"title"];
    self.title = [_device objectForKey:@"title"];
    
    _udpListener = [UDPListenerService getInstance];
    _udpListener.delegate = self;
    [_udpListener startUdpBroadcastListener];
    
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    NoTimersViewController *noTimersVC = [[NoTimersViewController alloc] initWithNibName:@"NoTimersViewController" bundle:nil];
    noTimersVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    noTimersVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:noTimersVC animated:YES completion:nil];
}

- (IBAction)onBtnNightLightTimer:(id)sender {
}

- (IBAction)onBtnIRTimer:(id)sender {
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

@end
