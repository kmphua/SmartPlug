//
//  DeviceMainViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/18/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "DeviceMainViewController.h"
#import "DeviceItemSettingsViewController.h"
#import "SetTimerSnoozeViewController.h"
#import "ScheduleMainViewController.h"
#import "ScheduleActionViewController.h"
#import "IREditModeViewController.h"
#import "UDPCommunication.h"
#import "UDPListenerService.h"
#import "CrashCountDown.h"
#import "MBProgressHUD.h"

#define STATUS_CHECKER_TIMER_INTERVAL       7

@interface DeviceMainViewController ()<SetSnoozeTimerDelegate, WebServiceDelegate>
{
    int _relay;
    int _nightlight;
    int _action;
    int _snooze;
}

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (nonatomic, weak) IBOutlet UIImageView *imgDeviceIcon;
@property (nonatomic, weak) IBOutlet UILabel *lblDeviceName;

@property (weak, nonatomic) IBOutlet UIView *viewOutlet;
@property (weak, nonatomic) IBOutlet UIImageView *imgOutletBg;
@property (weak, nonatomic) IBOutlet UIImageView *imgOutletIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgOutletWarning;
@property (weak, nonatomic) IBOutlet UILabel *lblOutlet;
@property (weak, nonatomic) IBOutlet UIButton *btnOutletTimer;

@property (weak, nonatomic) IBOutlet UIView *viewNightLight;
@property (weak, nonatomic) IBOutlet UIImageView *imgNightLightBg;
@property (weak, nonatomic) IBOutlet UIImageView *imgNightLightIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblNightLight;
@property (weak, nonatomic) IBOutlet UIButton *btnNightLightTimer;

@property (weak, nonatomic) IBOutlet UIView *viewIr;
@property (weak, nonatomic) IBOutlet UIImageView *imgIrBg;
@property (weak, nonatomic) IBOutlet UIImageView *imgIrIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblIr;
@property (weak, nonatomic) IBOutlet UIButton *btnIrTimer;

@property (weak, nonatomic) IBOutlet UIView *viewCo;
@property (weak, nonatomic) IBOutlet UIImageView *imgCoBg;
@property (weak, nonatomic) IBOutlet UIImageView *imgCoIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgCoWarning;
@property (weak, nonatomic) IBOutlet UILabel *lblCo;

@property (weak, nonatomic) IBOutlet UIView *viewWarning;
@property (weak, nonatomic) IBOutlet UIImageView *imgLeftWarning;
@property (weak, nonatomic) IBOutlet UILabel *lblWarning;
@property (weak, nonatomic) IBOutlet UIImageView *imgRightWarning;

@property (strong, nonatomic) CrashCountDown *crashTimer;
@property (strong, nonatomic) NSTimer *statusCheckerTimer;
@property (assign, nonatomic) BOOL udpConnection;

@property (strong, nonatomic) MBProgressHUD *hud;

@property (strong, nonatomic) NSMutableArray *alarms;

@end

@implementation DeviceMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    
    _udpConnection = NO;
    _crashTimer = [CrashCountDown getInstance];
    _alarms = [NSMutableArray new];
    _snooze = 0;
    
    // See current device info
    g_DeviceName = _device.name;
    g_DeviceIp = _device.ip;
    g_DeviceMac = _device.sid;
    
    [[UDPCommunication getInstance] queryDevices:_device.ip udpMsg_param:UDP_CMD_DEVICE_QUERY];
    
    NSString *imagePath;
    if (self.device.icon && self.device.icon.length > 0) {
        imagePath = self.device.icon;
    } else {
        imagePath = @"http://flutehuang-001-site2.ctempurl.com/Images/see_Electric_ight_1_white_bkgnd.png";
    }
    [self.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];

    
    if (self.device.givenName && self.device.givenName.length > 0) {
        self.lblDeviceName.text = self.device.givenName;
        self.title = self.device.givenName;
    } else {
        self.lblDeviceName.text = self.device.name;
        self.title = self.device.name;
        self.device.givenName = self.device.name;
    }
    
    self.lblOutlet.text = NSLocalizedString(@"btn_outlet", nil);
    self.lblNightLight.text = NSLocalizedString(@"btn_nightLight", nil);
    self.lblIr.text = NSLocalizedString(@"btn_ir", nil);
    self.lblCo.text = NSLocalizedString(@"btn_coNormal", nil);
    self.lblWarning.text = NSLocalizedString(@"please_wait_done", nil);
    
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    UITapGestureRecognizer *tapGestureOutletButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOutletButton:)];
    [self.viewOutlet addGestureRecognizer:tapGestureOutletButton];
    [self.viewOutlet setUserInteractionEnabled:YES];

    UITapGestureRecognizer *tapGestureNightlightButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapNightlightButton:)];
    [self.viewNightLight addGestureRecognizer:tapGestureNightlightButton];
    [self.viewNightLight setUserInteractionEnabled:YES];
    
    UITapGestureRecognizer *tapGestureIRButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapIRButton:)];
    [self.viewIr addGestureRecognizer:tapGestureIRButton];
    [self.viewIr setUserInteractionEnabled:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Init UI
    [_imgOutletWarning setHidden:YES];
    [_imgCoWarning setHidden:YES];
    [_btnIrTimer setHidden:YES];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(udpUpdateUI:) name:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceStatusChanged:) name:NOTIFICATION_DEVICE_STATUS_CHANGED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePushNotification:) name:NOTIFICATION_PUSH object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timerCrashReached:) name:NOTIFICATION_TIMER_CRASH_REACHED object:nil];
    
    // Start status checker timer
    _statusCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:STATUS_CHECKER_TIMER_INTERVAL
                                                   target:self
                                                 selector:@selector(checkStatus:)
                                                 userInfo:nil
                                                  repeats:YES];
    
    [self showWaitingIndicator:NSLocalizedString(@"please_wait_done",nil)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_DEVICE_STATUS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PUSH object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_TIMER_CRASH_REACHED object:nil];
    
    // Stop status checker timer
    if (_statusCheckerTimer) {
        [_statusCheckerTimer invalidate];
        _statusCheckerTimer = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showWaitingIndicator:(NSString *)labelText {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.labelText = labelText;
    [_hud show:YES];
}

- (void)dismissWaitingIndicator {
    [_hud hide:YES];
}

- (void)udpUpdateUI:(NSNotification *)notification {
    _udpConnection = true;
    if(_crashTimer) {
        [_crashTimer stopTimer];
    }
    //[self dismissWaitingIndicator];
    [self updateUI:nil];
}

- (void)deviceStatusChanged:(NSNotification *)notification {
    _udpConnection = true;
    [_crashTimer stopTimer];
    [[UDPCommunication getInstance] queryDevices:g_DeviceIp udpMsg_param:UDP_CMD_GET_DEVICE_STATUS];
}

- (void)handlePushNotification:(NSNotification *)notification {
    NSLog(@"RECEIVED PUSH");
    [self checkStatus:nil];
}

- (void)timerCrashReached:(NSNotification *)notification {
    [_imgLeftWarning setHidden:NO];
    [_lblWarning setText:NSLocalizedString(@"no_udp_Connection", nil)];
    [_lblWarning setHidden:NO];
    [_imgRightWarning setHidden:NO];
    _udpConnection = false;
}

- (void)broadcastUdpUpdateUi:(NSNotification *)notification {
    _udpConnection = true;
    [_crashTimer stopTimer];
    
    //while(!mServiceBound){System.out.println("."); SystemClock.sleep(100);}
    
    /*
    if (g_DeviceIp && g_DeviceIp.length>0) {
        [[UDPCommunication getInstance] queryDevices:g_DeviceIp udpMsg_param:UDP_CMD_GET_DEVICE_STATUS];
    } else {
        NSLog(@"IP IS NULL");
    }
    */
}

- (void)updateUI:(NSNotification *)notification {
    NSLog(@"Updating UI");
    NSArray *devices = [[SQLHelper getInstance] getPlugDataByID:_device.sid];
    if (!devices || devices.count == 0) {
        NSLog(@"updateUI: No devices!");
        return;
    }
    
    JSmartPlug *device = [devices firstObject];
    
    if (device.givenName && device.givenName.length>0) {
        _lblDeviceName.text = device.givenName;
    } else {
        _lblDeviceName.text = device.name;
    }
    
    // Relay
    if (device.relay == 0) {
        _relay = 0;
        [_imgOutletIcon setImage:[UIImage imageNamed:@"svc_0_big_off"]];
    } else if (device.relay == 1) {
        _relay = 1;
        [_imgOutletIcon setImage:[UIImage imageNamed:@"svc_0_big"]];
    }
    
    // Hall effect sensor
    if (device.hall_sensor == 0) {
        [_imgOutletWarning setHidden:YES];
        [_imgOutletWarning setImage:[UIImage imageNamed:@"marker_warn"]];
        [_imgOutletWarning stopAnimating];
        [_lblWarning setText:@""];
        [_imgLeftWarning setHidden:YES];
        [_imgRightWarning setHidden:YES];
    } else if (device.hall_sensor == 1) {
        [_imgOutletWarning setHidden:NO];
        [_lblWarning setHidden:NO];
        [_imgOutletWarning setImage:[UIImage imageNamed:@"marker_warn2"]];
        [self startBlinkingAnimation:_imgOutletWarning];
        [_imgLeftWarning setHidden:NO];
        [_imgRightWarning setHidden:NO];
        [_lblWarning setText:NSLocalizedString(@"msg_ha_warning", nil)];
    }
    
    // CO sensor
    if (device.co_sensor == 0) {
        [_imgCoWarning setHidden:YES];
        [_imgCoWarning setImage:[UIImage imageNamed:@"marker_warn"]];
        [_imgCoWarning stopAnimating];
        [_imgCoIcon setImage:[UIImage imageNamed:@"svc_3_big"]];
        [_imgLeftWarning setHidden:YES];
        [_imgRightWarning setHidden:YES];
        [_lblWarning setHidden:YES];
    } else if (device.co_sensor == 1) {
        [_imgCoWarning setHidden:NO];
        [_imgCoWarning setImage:[UIImage imageNamed:@"marker_warn2"]];
        [self startBlinkingAnimation:_imgCoWarning];
        [_imgCoIcon setImage:[UIImage imageNamed:@"svc_3_big"]];
        [_imgLeftWarning setHidden:NO];
        [_imgRightWarning setHidden:NO];
        [_lblWarning setText:NSLocalizedString(@"msg_co_warning", nil)];
        [_lblWarning setHidden:NO];
    } else if (device.co_sensor == 3) {
        [_viewCo setHidden:NO];
        [_imgCoIcon setImage:[UIImage imageNamed:@"svc_3_big_off"]];
        [_imgLeftWarning setHidden:NO];
        [_imgRightWarning setHidden:NO];
        [_lblWarning setText:NSLocalizedString(@"USB_not_plugged_in", nil)];
        [_lblWarning setHidden:NO];
    }
    
    // Night light
    if (device.nightlight == 0) {
        _nightlight = 0;
        [_imgNightLightIcon setImage:[UIImage imageNamed:@"svc_1_big_off"]];
    } else if (device.nightlight == 1) {
        _nightlight = 1;
        [_imgNightLightIcon setImage:[UIImage imageNamed:@"svc_1_big"]];
    }
    
    // Snooze
    if (device.snooze == 0) {
        NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:g_DeviceMac serviceId:RELAY_SERVICE];
        if (alarms && alarms.count>0) {
            [_btnOutletTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_on"] forState:UIControlStateNormal];
        } else {
            [_btnOutletTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_off"] forState:UIControlStateNormal];
        }

        alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:g_DeviceMac serviceId:NIGHTLED_SERVICE];
        if (alarms && alarms.count>0) {
            [_btnNightLightTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_on"] forState:UIControlStateNormal];
        } else {
            [_btnNightLightTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_off"] forState:UIControlStateNormal];
        }
    } else {
        _snooze = device.snooze;
        [_btnOutletTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_delay"] forState:UIControlStateNormal];
        [_btnNightLightTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_delay"] forState:UIControlStateNormal];
    }
    
    if (device.icon && device.icon.length>0) {
        NSString *imagePath = self.device.icon;
        [_imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
    }
    
    [_viewNightLight setUserInteractionEnabled:YES];
    [_viewOutlet setUserInteractionEnabled:YES];
    
    [self dismissWaitingIndicator];
}

- (void)sendService:(int)serviceId
{
    [self showWaitingIndicator:NSLocalizedString(@"processing_command", nil)];
    
    if (serviceId == RELAY_SERVICE) {
        if (_relay == 0) {
            _action = 0x01;
        } else {
            _action = 0x00;
        }
    }
    
    if (serviceId == NIGHTLED_SERVICE) {
        if (_nightlight == 0) {
            _action = 0x01;
        } else {
            _action = 0x00;
        }
    }
    
    //[_imgLeftWarning setHidden:NO];
    //[_lblWarning setText:NSLocalizedString(@"please_wait_done", nil)];
    //[_lblWarning setHidden:NO];
    //[_imgRightWarning setHidden:NO];

    [_viewOutlet setUserInteractionEnabled:NO];
    [_viewNightLight setUserInteractionEnabled:NO];
    
    _udpConnection = false;
    [[UDPCommunication getInstance] setDeviceStatus:_device.ip serviceId:serviceId action:_action];

    // Send to HTTP after delay 1 second
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    
        // Set device status
        WebService *ws = [WebService new];
        ws.delegate = self;
        
        int header = 0x534D5254;
        uint8_t sMsg[24];
        sMsg[3] = (uint8_t)(header);
        sMsg[2] = (uint8_t)((header >> 8 ));
        sMsg[1] = (uint8_t)((header >> 16 ));
        sMsg[0] = (uint8_t)((header >> 24 ));
        
        int msid = (int)(random()*4294967+1);
        sMsg[7] = (uint8_t)(msid);
        sMsg[6] = (uint8_t)((msid >> 8 ));
        sMsg[5] = (uint8_t)((msid >> 16 ));
        sMsg[4] = (uint8_t)((msid >> 24 ));
        int seq = 0x80000000;
        sMsg[11] = (uint8_t)(seq);
        sMsg[10] = (uint8_t)((seq >> 8 ));
        sMsg[9] = (uint8_t)((seq >> 16 ));
        sMsg[8] = (uint8_t)((seq >> 24 ));
        short command = 0x0008;
        sMsg[13] = (uint8_t)(command);
        sMsg[12] = (uint8_t)((command >> 8 ));
        //int serviceId = 0xD1000000;
        sMsg[17] = (uint8_t)(serviceId);
        sMsg[16] = (uint8_t)((serviceId >> 8 ));
        sMsg[15] = (uint8_t)((serviceId >> 16 ));
        sMsg[14] = (uint8_t)((serviceId >> 24 ));
        
        uint8_t datatype = 0x01;
        sMsg[18] = datatype;
        uint8_t data = _action;
        sMsg[19] = data;
        int terminator = 0x00000000;
        sMsg[23] = (uint8_t)(terminator & 0xff);
        sMsg[22] = (uint8_t)((terminator >> 8 ) & 0xff);
        sMsg[21] = (uint8_t)((terminator >> 16 ) & 0xff);
        sMsg[20] = (uint8_t)((terminator >> 24 ) & 0xff);
        
        NSLog(@"Data length = %ld", sizeof(sMsg));
        
        NSData *deviceData = [NSData dataWithBytes:sMsg length:sizeof(sMsg)];
        
        int send;
        if (!_udpConnection) {
            send = 1;
        } else {
            send = 0;
        }
        
        [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:_device.sid send:send data:deviceData];
    });
}

- (void)updateDeviceStatusFromServer
{
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution] devId:_device.sid];
}

- (void)onRightBarButton:(id)sender {
    DeviceItemSettingsViewController *itemSettingsVc = [[DeviceItemSettingsViewController alloc] initWithNibName:@"DeviceItemSettingsViewController" bundle:nil];
    itemSettingsVc.device = self.device;
    [self.navigationController pushViewController:itemSettingsVc animated:YES];
}

- (void)startBlinkingAnimation:(UIView *)view {
    view.alpha = 1.0f;
    [UIView animateWithDuration:0.6
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
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_device.sid serviceId:RELAY_SERVICE];
    if (alarms && alarms.count>0) {
        // Snooze
        SetTimerSnoozeViewController *setTimerSnoozeVC = [[SetTimerSnoozeViewController alloc] initWithNibName:@"SetTimerSnoozeViewController" bundle:nil];
        setTimerSnoozeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
        setTimerSnoozeVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        setTimerSnoozeVC.devId = _device.sid;
        setTimerSnoozeVC.serviceId = RELAY_SERVICE;
        setTimerSnoozeVC.snooze = _snooze;
        setTimerSnoozeVC.delegate = self;
        [self presentViewController:setTimerSnoozeVC animated:YES completion:nil];
    } else {
        // Add new timer
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"no_timer_set",nil)
                                              message:NSLocalizedString(@"add_timer", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* actionYes = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            ScheduleActionViewController *scheduleActionVC = [[ScheduleActionViewController alloc] initWithNibName:@"ScheduleActionViewController" bundle:nil];
            scheduleActionVC.modalPresentationStyle = UIModalPresentationCurrentContext;
            scheduleActionVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            scheduleActionVC.deviceId = _device.sid;
            scheduleActionVC.deviceName = _device.givenName;
            scheduleActionVC.serviceId = RELAY_SERVICE;
            [self.navigationController pushViewController:scheduleActionVC animated:YES];
            
        }];
        [alertController addAction:actionYes];
        UIAlertAction* actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        [alertController addAction:actionNo];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)onBtnNightLightTimer:(id)sender {
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_device.sid serviceId:NIGHTLED_SERVICE];
    if (alarms && alarms.count>0) {
        // Snooze
        SetTimerSnoozeViewController *setTimerSnoozeVC = [[SetTimerSnoozeViewController alloc] initWithNibName:@"SetTimerSnoozeViewController" bundle:nil];
        setTimerSnoozeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
        setTimerSnoozeVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        setTimerSnoozeVC.devId = _device.sid;
        setTimerSnoozeVC.serviceId = NIGHTLED_SERVICE;
        setTimerSnoozeVC.delegate = self;
        setTimerSnoozeVC.snooze = _snooze;
        [self presentViewController:setTimerSnoozeVC animated:YES completion:nil];
    } else {
        // Add new timer
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"no_timer_set",nil)
                                              message:NSLocalizedString(@"add_timer", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* actionYes = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            ScheduleActionViewController *scheduleActionVC = [[ScheduleActionViewController alloc] initWithNibName:@"ScheduleActionViewController" bundle:nil];
            scheduleActionVC.modalPresentationStyle = UIModalPresentationCurrentContext;
            scheduleActionVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            scheduleActionVC.deviceId = _device.sid;
            scheduleActionVC.deviceName = _device.givenName;
            scheduleActionVC.serviceId = NIGHTLED_SERVICE;
            [self.navigationController pushViewController:scheduleActionVC animated:YES];
            
        }];
        [alertController addAction:actionYes];
        UIAlertAction* actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        [alertController addAction:actionNo];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)onTapOutletButton:(UITapGestureRecognizer *)recognizer {
   [self sendService:RELAY_SERVICE];
}

- (void)onTapNightlightButton:(UITapGestureRecognizer *)recognizer {
    [self sendService:NIGHTLED_SERVICE];
}

- (void)onBtnIRTimer:(UITapGestureRecognizer *)recognizer {
    // TODO: Handle IR timers
}

- (void)onTapIRButton:(UITapGestureRecognizer *)tapGestureRecognizer {
    IREditModeViewController *irVC = [[IREditModeViewController alloc] initWithNibName:@"IREditModeViewController" bundle:nil];
    [self.navigationController pushViewController:irVC animated:YES];
}

- (void)checkStatus:(id)sender {
    if (g_DeviceIp) {
        if ([[UDPCommunication getInstance] queryDevices:g_DeviceIp udpMsg_param:UDP_CMD_GET_DEVICE_STATUS]) {
            //[_crashTimer startTimer];
        } else {
            NSLog(@"IP IS NULL");
        }
        _udpConnection = NO;
    }

    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution] devId:g_DeviceMac];

    [self updateUI:nil];
}

- (void)updateAlarms {
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws alarmGet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac];
    [_alarms removeAllObjects];
}

- (void)handleUpdateAlarm:(NSData *)data {
    uint8_t array[128];
    memset(array, 0, 128);
    //I need to delete all the alarms
    [data getBytes:array length:data.length];
    
    for (int i = 0; i < data.length ; i+=12) {
        int serviceId = [Global process_long:array[i] b:array[i+1] c:array[i+2] d:array[i+3]];
        
        if(serviceId != 0) {
            Alarm *a = [Alarm new];
            a.device_id = g_DeviceMac;
            if(serviceId == RELAY_SERVICE) {
                a.service_id = RELAY_SERVICE;
            } else if(serviceId == NIGHTLED_SERVICE){
                a.service_id = NIGHTLED_SERVICE;
            }
            
            NSLog(@"SERVICE FROM SERVER: %d", a.service_id);
            
            a.dow = array[i + 7];
            a.initial_hour = array[i + 8];
            a.initial_minute = array[i + 9];
            a.end_hour = array[i + 10];
            a.end_minute = array[i + 11];
            NSLog(@"ALARM GET CONTROL - Service Id: %d, DOW: %d, Init Hour: %d, Init Minute: %d, End Hour: %d, End Minute: %d", a.service_id, a.dow, a.initial_hour, a.initial_minute, a.end_hour, a.end_minute);
            [_alarms addObject:a];
        }
    }
    
    if (_alarms.count > 0) {
        [[SQLHelper getInstance] removeAlarms:g_DeviceMac];
        for(int i = 0; i < _alarms.count; i++){
            Alarm *a = [_alarms objectAtIndex:i];
            if ([[SQLHelper getInstance] insertAlarm:a]) {
                NSLog(@"ALARM INSERTED");
            } else {
                NSLog(@"ALARM INSERTION FAILURE");
            }
        }
    }
}

//==================================================================
#pragma mark - SetSnoozeTimerDelegate
//==================================================================
- (void)addTimer:(int)alarmId serviceId:(int)serviceId
{
    ScheduleActionViewController *scheduleVC = [[ScheduleActionViewController alloc] initWithNibName:@"ScheduleActionViewController" bundle:nil];
    scheduleVC.deviceId = _device.sid;
    scheduleVC.deviceName = _device.givenName;
    scheduleVC.serviceId = serviceId;
    scheduleVC.alarmId = alarmId;
    [self.navigationController pushViewController:scheduleVC animated:YES];
}

- (void)modifyTimer:(int)alarmId serviceId:(int)serviceId
{
    ScheduleMainViewController *scheduleVC = [[ScheduleMainViewController alloc] initWithNibName:@"ScheduleMainViewController" bundle:nil];
    scheduleVC.devId = _device.sid;
    scheduleVC.devName = _device.givenName;
    scheduleVC.serviceId = serviceId;
    scheduleVC.alarmId = alarmId;
    [self.navigationController pushViewController:scheduleVC animated:YES];
}

- (void)snooze5Mins:(int)alarmId serviceId:(int)serviceId
{
    // Sending 5 minutes snooze to device
    [[UDPCommunication getInstance] delayTimer:_snooze+5 protocol:PROTOCOL_UDP];
    [[SQLHelper getInstance] updateSnooze:_snooze+5 sid:_device.sid];
    [[UDPCommunication getInstance] delayTimer:_snooze+5 protocol:PROTOCOL_HTTP];
    [self.view makeToast:NSLocalizedString(@"delay_5_minutes", nil)
                duration:3.0
                position:CSToastPositionCenter];
}

- (void)snooze10Mins:(int)alarmId serviceId:(int)serviceId
{
    [[UDPCommunication getInstance] delayTimer:_snooze+10 protocol:PROTOCOL_UDP];
    [[SQLHelper getInstance] updateSnooze:_snooze+10 sid:_device.sid];
    [[UDPCommunication getInstance] delayTimer:_snooze+10 protocol:PROTOCOL_HTTP];
    [self.view makeToast:NSLocalizedString(@"delay_10_minutes", nil)
                duration:3.0
                position:CSToastPositionCenter];
}

- (void)snooze30Mins:(int)alarmId serviceId:(int)serviceId
{
    [[UDPCommunication getInstance] delayTimer:_snooze+30 protocol:PROTOCOL_UDP];
    [[SQLHelper getInstance] updateSnooze:_snooze+30 sid:_device.sid];
    [[UDPCommunication getInstance] delayTimer:_snooze+30 protocol:PROTOCOL_HTTP];
    [self.view makeToast:NSLocalizedString(@"delay_30_minutes", nil)
                duration:3.0
                position:CSToastPositionCenter];
}

- (void)snooze1Hour:(int)alarmId serviceId:(int)serviceId
{
    [[UDPCommunication getInstance] delayTimer:_snooze+59 protocol:PROTOCOL_UDP];
    [[SQLHelper getInstance] updateSnooze:_snooze+59 sid:_device.sid];
    [[UDPCommunication getInstance] delayTimer:_snooze+59 protocol:PROTOCOL_HTTP];
    [self.view makeToast:NSLocalizedString(@"delay_60_minutes", nil)
                duration:3.0
                position:CSToastPositionCenter];
}

- (void)cancelSnooze:(int)alarmId serviceId:(int)serviceId
{
    [[UDPCommunication getInstance] delayTimer:0 protocol:PROTOCOL_UDP];
    [[SQLHelper getInstance] updateSnooze:0 sid:_device.sid];
    [[UDPCommunication getInstance] delayTimer:0 protocol:PROTOCOL_HTTP];
    [self.view makeToast:NSLocalizedString(@"CancelSnooze", nil)
                duration:3.0
                position:CSToastPositionCenter];
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
                NSString *relay = [jsonObject objectForKey:@"relay"];
                NSString *nightlight = [jsonObject objectForKey:@"nightlight"];
                NSString *co_sensor = [jsonObject objectForKey:@"cosensor"];
                NSString *hall_sensor = [jsonObject objectForKey:@"hallsensor"];
                NSString *snooze = [jsonObject objectForKey:@"snooze"];
                
                NSString *title = [jsonObject objectForKey:@"title"];
                NSString *icon = [jsonObject objectForKey:@"icon"];

                [[SQLHelper getInstance] updatePlugName:title sid:g_DeviceMac];
                [[SQLHelper getInstance] updatePlugIcon:g_DeviceMac icon:icon];
                
                NSLog(@"Devget returned: relay=%@, nightlight=%@, co_sensor=%@, hall_sensor=%@, snooze=%@",
                      relay, nightlight, co_sensor, hall_sensor, snooze);
                
                if(![relay isKindOfClass:[NSNull class]] && relay != nil && relay.length>0) {
                    [[SQLHelper getInstance] updatePlugRelayService:[relay intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugRelayService:0 sid:g_DeviceMac];
                }
                if(![nightlight isKindOfClass:[NSNull class]] && nightlight != nil && nightlight.length>0) {
                    [[SQLHelper getInstance] updatePlugNightlightService:[nightlight intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugNightlightService:0 sid:g_DeviceMac];
                }
                if(![co_sensor isKindOfClass:[NSNull class]] && co_sensor != nil && co_sensor.length>0) {
                    [[SQLHelper getInstance] updatePlugCoSensorService:[co_sensor intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugCoSensorService:0 sid:g_DeviceMac];
                }
                if(![hall_sensor isKindOfClass:[NSNull class]] && hall_sensor != nil && hall_sensor.length>0) {
                    [[SQLHelper getInstance] updatePlugHallSensorService:[hall_sensor intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugHallSensorService:0 sid:g_DeviceMac];
                }
                if(![snooze isKindOfClass:[NSNull class]] && snooze != nil && snooze.length>0) {
                    [[SQLHelper getInstance] updateSnooze:[snooze intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updateSnooze:0 sid:g_DeviceMac];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HTTP_DEVICE_STATUS
                                                                    object:self
                                                                  userInfo:nil];
                
                [self updateUI:nil];

                // Update alarms from server
                [self updateAlarms];
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
        } else if ([resultName compare:WS_DEV_CTRL] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSLog(@"Set device status success");
                
                // Update device status
                [self updateDeviceStatusFromServer];

            } else {
                // Failure
                NSLog(@"Set device status failed");
            }
        } else if ([resultName isEqualToString:WS_ALARM_GET]) {
            if (jsonObject) {
                long result = [[jsonObject objectForKey:@"r"] longValue];
                if (result == 0) {
                    // Success
                    NSLog(@"Get alarm success");
                    [self handleUpdateAlarm:data];
                } else {
                    // Failure
                    NSLog(@"Set alarm failed");
                }
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}


@end
