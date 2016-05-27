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
    int _relaySnooze;
    int _ledSnooze;
    int _irSnooze;
    int _serviceId;
    BOOL _deviceStatusChangedFlag;
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
    _relaySnooze = 0;
    _ledSnooze = 0;
    _deviceStatusChangedFlag = false;
    
    // See current device info
    g_DeviceName = _device.name;
    g_DeviceIp = _device.ip;
    g_DeviceMac = _device.sid;
    
    [[UDPCommunication getInstance] queryDevices:_device.ip udpMsg_param:UDP_CMD_DEVICE_QUERY];
    
    NSString *imagePath;
    if (self.device.icon && self.device.icon.length > 0) {
        imagePath = self.device.icon;
    } else {
        imagePath = DEFAULT_ICON_PATH;
    }
    [self.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
    [self.imgDeviceIcon setBackgroundColor:[Global colorWithType:COLOR_TYPE_ICON_BG]];
    
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
    
    // Load animation for warnings
    NSArray *images = [NSArray arrayWithObjects:[UIImage imageNamed:@"marker_warn"], [UIImage imageNamed:@"marker_warn2"], nil];
    [_imgCoWarning setAnimationImages:images];
    [_imgCoWarning setAnimationDuration:1.0];
    [_imgOutletWarning setAnimationImages:images];
    [_imgOutletWarning setAnimationDuration:1.0];
    
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
    [_imgLeftWarning setHidden:YES];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(udpUpdateUI:) name:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceStatusChanged:) name:NOTIFICATION_DEVICE_STATUS_CHANGED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePushNotification:) name:NOTIFICATION_PUSH object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timerCrashReached:) name:NOTIFICATION_TIMER_CRASH_REACHED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpDeviceStatus:) name:NOTIFICATION_HTTP_DEVICE_STATUS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceNotReached:) name:NOTIFICATION_DEVICE_NOT_REACHED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timersSentSuccess:) name:NOTIFICATION_TIMERS_SENT_SUCCESS object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceStatusSet:) name:NOTIFICATION_DEVICE_STATUS_SET object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceRemoved:) name:NOTIFICATION_MDNS_DEVICE_REMOVED object:nil];
    
    [self updateDeviceStatusFromServer];
    
    // Start status checker timer
    _statusCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:STATUS_CHECKER_TIMER_INTERVAL
                                                   target:self
                                                 selector:@selector(checkStatus:)
                                                 userInfo:nil
                                                  repeats:NO];
    
    [self showWaitingIndicator:NSLocalizedString(@"please_wait_done",nil)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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

- (void)timersSentSuccess:(NSNotification *)notification {
    NSLog(@"TIMERS SENT SUCCESSFULLY BROADCAST");
    _deviceStatusChangedFlag = true;
}

- (void)timerCrashReached:(NSNotification *)notification {
    if (!_deviceStatusChangedFlag) {
        [self setDeviceStatus:_serviceId send:0];
    } else {
        if (_serviceId == RELAY_SERVICE) {
            [[SQLHelper getInstance] updatePlugRelayService:_action sid:g_DeviceMac];
        }
        if (_serviceId == NIGHTLED_SERVICE) {
            [[SQLHelper getInstance] updatePlugNightlightService:_action sid:g_DeviceMac];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil userInfo:nil];
        
        [self setDeviceStatus:_serviceId send:1];
    }
    
    _deviceStatusChangedFlag = false;
}

- (void)httpDeviceStatus:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *error = [userInfo objectForKey:@"error"];
        if (error && error.length>0) {
            [self dismissWaitingIndicator];
            [self.view makeToast:NSLocalizedString(@"connection_error", nil)
                        duration:3.0
                        position:CSToastPositionBottom];
        }
    }
    [self updateUI:nil];
}

- (void)deviceStatusSet:(NSNotification *)notification {
    [self startRepeatingTask];
}

- (void)handlePushNotification:(NSNotification *)notification {
    [self updateUI:notification];
}

- (void)udpUpdateUI:(NSNotification *)notification {
    [self dismissWaitingIndicator];
    [self updateUI:nil];
}

- (void)deviceStatusChanged:(NSNotification *)notification {
    _deviceStatusChangedFlag = true;
    [self startRepeatingTask];
    [self dismissWaitingIndicator];
}

- (void)handleDeviceRemoved:(NSNotification*)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *serviceName = [userInfo objectForKey:@"name"];
        [[SQLHelper getInstance] updatePlugIP:serviceName ip:@""];
        NSLog(@"%@", serviceName);
    }
}

- (void)deviceNotReached:(NSNotification *)notification {
    NSLog(@"BROADCAST DEVICE NOT REACHED");
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *error = [userInfo objectForKey:@"error"];
        if (error && error.length>0) {
            [self.view makeToast:NSLocalizedString(@"connection_error", nil)
                        duration:3.0
                        position:CSToastPositionBottom];
        } else {
            [self.view makeToast:NSLocalizedString(@"please_wait", nil)
                        duration:3.0
                        position:CSToastPositionBottom];
        }
        [self dismissWaitingIndicator];
    }
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

- (void)getDataFromServer {
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrGet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE iconRes:[Global getIconResolution]];
}

- (void)updateUI:(NSNotification *)notification {
    [self dismissWaitingIndicator];
    
    NSArray *devices = [[SQLHelper getInstance] getPlugDataByID:_device.sid];
    if (!devices || devices.count == 0) {
        NSLog(@"updateUI: No devices!");
        return;
    }
    
    JSmartPlug *device = [devices firstObject];
    self.device = device;
    
    if (device.givenName && device.givenName.length>0) {
        _lblDeviceName.text = device.givenName;
    } else {
        _lblDeviceName.text = device.name;
    }
    
    NSString *imagePath;
    if (device.icon && device.icon.length > 0) {
        imagePath = device.icon;
    } else {
        imagePath = @"http://flutehuang-001-site2.ctempurl.com/Images/see_Electric_ight_1_white_bkgnd.png";
    }
    [self.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
    
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
        [_imgOutletWarning startAnimating];
        [_imgLeftWarning setHidden:NO];
        [_imgRightWarning setHidden:NO];
        [_lblWarning setText:NSLocalizedString(@"msg_ha_warning", nil)];
    }
    
    // CO sensor
    if (device.co_sensor == 0) {
        [_imgCoWarning setHidden:YES];
        //[_imgCoWarning setImage:[UIImage imageNamed:@"marker_warn"]];
        //[_imgCoWarning stopAnimating];
        [_imgCoIcon setImage:[UIImage imageNamed:@"svc_3_big"]];
        //[_imgLeftWarning setHidden:YES];
        //[_imgRightWarning setHidden:YES];
        [_lblWarning setHidden:YES];
    } else if (device.co_sensor == 1) {
        [_imgCoWarning setHidden:NO];
        [_imgCoWarning setImage:[UIImage imageNamed:@"marker_warn2"]];
        [_imgCoWarning startAnimating];
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
    
    // Relay snooze
    if (device.snooze == 0) {
        NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:g_DeviceMac serviceId:RELAY_SERVICE];
        if (alarms && alarms.count>0) {
            [_btnOutletTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_on"] forState:UIControlStateNormal];
        } else {
            [_btnOutletTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_off"] forState:UIControlStateNormal];
        }
    } else {
        [_btnOutletTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_delay"] forState:UIControlStateNormal];
    }
    
    // Led snooze
    if (device.led_snooze == 0) {
        NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:g_DeviceMac serviceId:NIGHTLED_SERVICE];
        if (alarms && alarms.count>0) {
            [_btnNightLightTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_on"] forState:UIControlStateNormal];
        } else {
            [_btnNightLightTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_off"] forState:UIControlStateNormal];
        }
    } else {
        [_btnNightLightTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_delay"] forState:UIControlStateNormal];
    }

    // Ir snooze
    if (device.ir_snooze == 0) {
        NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:g_DeviceMac serviceId:IR_SERVICE];
        if (alarms && alarms.count>0) {
            [_btnIrTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_on"] forState:UIControlStateNormal];
        } else {
            [_btnIrTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_off"] forState:UIControlStateNormal];
        }
    } else {
        [_btnIrTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_delay"] forState:UIControlStateNormal];
    }
    
    [_viewNightLight setUserInteractionEnabled:YES];
    [_viewOutlet setUserInteractionEnabled:YES];
}

- (void)sendService:(int)serviceId
{
    [self showWaitingIndicator:NSLocalizedString(@"processing_command", nil)];
    
    _serviceId = serviceId;
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

    _serviceId = serviceId;
    
    [_imgLeftWarning setHidden:NO];
    [_lblWarning setText:NSLocalizedString(@"please_wait_done", nil)];
    [_lblWarning setHidden:NO];
    [_imgRightWarning setHidden:NO];

    [_viewOutlet setUserInteractionEnabled:NO];
    [_viewNightLight setUserInteractionEnabled:NO];
    
    [_crashTimer startTimer];

    /*
    _udpConnection = false;

    if ([[UDPCommunication getInstance] setDeviceStatus:_device.ip serviceId:serviceId action:_action]) {
        int counter = 2;
        while (!_deviceStatusChangedFlag && counter > 0) {
            [NSThread sleepForTimeInterval:1];
            counter--;
            //waiting time
        }
    }
    
    if (!_deviceStatusChangedFlag) {
        [self setDeviceStatus:serviceId send:0];
    } else {
        if (serviceId == RELAY_SERVICE) {
            [[SQLHelper getInstance] updatePlugRelayService:_action sid:g_DeviceMac];
        }
        if (serviceId == NIGHTLED_SERVICE) {
            [[SQLHelper getInstance] updatePlugNightlightService:_action sid:g_DeviceMac];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil userInfo:nil];
        
        [self setDeviceStatus:serviceId send:1];
    }
     */
}

- (void)setDeviceStatus:(int)serviceId send:(int)send
{
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
    
    [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:_device.sid send:send data:deviceData];
}

- (void)updateDeviceStatusFromServer
{
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution] devId:_device.sid];
}

- (void)startRepeatingTask {
    if (g_DeviceIp) {
        short command = UDP_CMD_GET_DEVICE_STATUS;
        if ([[UDPCommunication getInstance] queryDevices:g_DeviceIp udpMsg_param:command]) {
            [self dismissWaitingIndicator];
        } else {
            NSLog(@"IP IS NULL");
        }
        _udpConnection = false;
    }
    [self dismissWaitingIndicator];
    [self updateUI:nil];
}

- (void)onRightBarButton:(id)sender {
    DeviceItemSettingsViewController *itemSettingsVc = [[DeviceItemSettingsViewController alloc] initWithNibName:@"DeviceItemSettingsViewController" bundle:nil];
    itemSettingsVc.device = self.device;
    [self.navigationController pushViewController:itemSettingsVc animated:YES];
}

- (IBAction)onBtnOutletTimer:(id)sender {
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_device.sid serviceId:RELAY_SERVICE];

    SetTimerSnoozeViewController *setTimerSnoozeVC = [[SetTimerSnoozeViewController alloc] initWithNibName:@"SetTimerSnoozeViewController" bundle:nil];
    setTimerSnoozeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    setTimerSnoozeVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    setTimerSnoozeVC.devId = _device.sid;
    setTimerSnoozeVC.serviceId = RELAY_SERVICE;
    setTimerSnoozeVC.snooze = _relaySnooze;
    setTimerSnoozeVC.alarmCount = (int)alarms.count;
    setTimerSnoozeVC.delegate = self;
    [self presentViewController:setTimerSnoozeVC animated:YES completion:nil];
}

- (IBAction)onBtnNightLightTimer:(id)sender {
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_device.sid serviceId:NIGHTLED_SERVICE];

    SetTimerSnoozeViewController *setTimerSnoozeVC = [[SetTimerSnoozeViewController alloc] initWithNibName:@"SetTimerSnoozeViewController" bundle:nil];
    setTimerSnoozeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    setTimerSnoozeVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    setTimerSnoozeVC.devId = _device.sid;
    setTimerSnoozeVC.serviceId = NIGHTLED_SERVICE;
    setTimerSnoozeVC.alarmCount = (int)alarms.count;
    setTimerSnoozeVC.delegate = self;
    setTimerSnoozeVC.snooze = _ledSnooze;
    [self presentViewController:setTimerSnoozeVC animated:YES completion:nil];
}

- (void)onTapOutletButton:(UITapGestureRecognizer *)recognizer {
   [self sendService:RELAY_SERVICE];
}

- (void)onTapNightlightButton:(UITapGestureRecognizer *)recognizer {
    [self sendService:NIGHTLED_SERVICE];
}

- (void)onBtnIRTimer:(UITapGestureRecognizer *)recognizer {
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_device.sid serviceId:IR_SERVICE];

    SetTimerSnoozeViewController *setTimerSnoozeVC = [[SetTimerSnoozeViewController alloc] initWithNibName:@"SetTimerSnoozeViewController" bundle:nil];
    setTimerSnoozeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    setTimerSnoozeVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    setTimerSnoozeVC.devId = _device.sid;
    setTimerSnoozeVC.serviceId = IR_SERVICE;
    setTimerSnoozeVC.alarmCount = (int)alarms.count;
    setTimerSnoozeVC.delegate = self;
    setTimerSnoozeVC.snooze = _ledSnooze;
    [self presentViewController:setTimerSnoozeVC animated:YES completion:nil];
}

- (void)onTapIRButton:(UITapGestureRecognizer *)tapGestureRecognizer {
    IREditModeViewController *irVC = [[IREditModeViewController alloc] initWithNibName:@"IREditModeViewController" bundle:nil];
    [self.navigationController pushViewController:irVC animated:YES];
}

- (void)checkStatus:(id)sender {
    if (g_DeviceIp) {
        if ([[UDPCommunication getInstance] queryDevices:g_DeviceIp udpMsg_param:UDP_CMD_GET_DEVICE_STATUS]) {
            [self dismissWaitingIndicator];
            //[_crashTimer startTimer];
        } else {
            NSLog(@"IP IS NULL");
        }
        _udpConnection = NO;
    }
    
    [self dismissWaitingIndicator];

    /*
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution] devId:g_DeviceMac];
     */

    [self updateUI:nil];
}

- (void)updateAlarms {
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws alarmGet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac];
    [_alarms removeAllObjects];
    if(![[SQLHelper getInstance] removeAlarms:g_DeviceMac]) {
        NSLog(@"ALARM WAS NOT ABLE TO BE REMOVED WITH DEVID: %@", g_DeviceMac);
    }
}

- (void)handleUpdateAlarm:(NSData *)data {
    uint8_t array[512];
    memset(array, 0, 512);
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
            } else if(serviceId == IR_SERVICE){
                a.service_id = IR_SERVICE;
            }
            
            NSLog(@"SERVICE FROM SERVER: %d", a.service_id);
            
            a.init_ir = array[i + 5];
            a.end_ir = array[i + 6];
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
        //[[SQLHelper getInstance] removeAlarms:g_DeviceMac];
        for(int i = 0; i < _alarms.count; i++){
            Alarm *a = [_alarms objectAtIndex:i];
            if ([[SQLHelper getInstance] insertAlarm:a]) {
                NSLog(@"ALARM INSERTED");
            } else {
                NSLog(@"ALARM INSERTION FAILURE");
            }
        }
    }
    
    [self updateUI:nil];
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
    [self sendSnooze:serviceId minutes:5];
}

- (void)snooze10Mins:(int)alarmId serviceId:(int)serviceId
{
    [self sendSnooze:serviceId minutes:10];
}

- (void)snooze30Mins:(int)alarmId serviceId:(int)serviceId
{
    [self sendSnooze:serviceId minutes:30];
}

- (void)snooze1Hour:(int)alarmId serviceId:(int)serviceId
{
    [self sendSnooze:serviceId minutes:59];
}

- (void)cancelSnooze:(int)alarmId serviceId:(int)serviceId
{
    [self sendSnooze:serviceId minutes:0];
}

- (void)sendSnooze:(int)serviceId minutes:(int)minutes
{
    int snooze = 0;
    
    if(serviceId == RELAY_SERVICE){
        snooze = [[SQLHelper getInstance] getRelaySnooze:g_DeviceMac];
    }
    
    if(serviceId == NIGHTLED_SERVICE){
        snooze = [[SQLHelper getInstance] getLedSnooze:g_DeviceMac];
    }

    if(serviceId == IR_SERVICE){
        snooze = [[SQLHelper getInstance] getIRSnooze:g_DeviceMac];
    }

    if ([[UDPCommunication getInstance] delayTimer:snooze protocol:1 serviceId:serviceId send:0]) {
        int counter = 10000;
        while (!_deviceStatusChangedFlag && counter > 0) {
            counter--;
            //waiting time
        }
    }
    
    if (!_deviceStatusChangedFlag) {
        if (![[UDPCommunication getInstance] delayTimer:snooze protocol:0 serviceId:serviceId send:0]) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"yes" forKey:@"error"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_NOT_REACHED object:nil userInfo:userInfo];
        } else {
            if(serviceId == RELAY_SERVICE){
                if(minutes > 0) {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:snooze];
                    snooze += minutes;
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:0];
                   snooze = 0;
                }
            }
            if(serviceId == NIGHTLED_SERVICE){
                if(minutes > 0) {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:snooze];
                    snooze += minutes;
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:0];
                    snooze = 0;
                }
            }
            if(serviceId == IR_SERVICE){
                if(minutes > 0) {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:snooze];
                    snooze += minutes;
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:0];
                    snooze = 0;
                }
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil userInfo:nil];

            NSString *toastMsg = [NSString stringWithFormat:@"%@ %@ %d %@", NSLocalizedString(@"timer", nil), NSLocalizedString(@"snooze", nil), minutes, NSLocalizedString(@"minutes", nil)];
            
            [self.view makeToast:toastMsg
                        duration:3.0
                        position:CSToastPositionBottom];

            _deviceStatusChangedFlag = false;
        }
        
    } else {
        [[UDPCommunication getInstance] delayTimer:snooze protocol:0 serviceId:serviceId send:1];
        
        if(serviceId == RELAY_SERVICE){
            if(minutes > 0) {
                [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:snooze];
                snooze += minutes;
            } else {
                [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:0];
                snooze = 0;
            }
        }
        if(serviceId == NIGHTLED_SERVICE){
            if(minutes > 0) {
                [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:snooze];
                snooze += minutes;
            } else {
                [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:0];
                snooze = 0;
            }
        }
        if(serviceId == IR_SERVICE){
            if(minutes > 0) {
                [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:snooze];
                snooze += minutes;
            } else {
                [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:0];
                snooze = 0;
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil userInfo:nil];
        
        NSString *toastMsg = [NSString stringWithFormat:@"%@ %@ %d %@", NSLocalizedString(@"timer", nil), NSLocalizedString(@"snooze", nil), minutes, NSLocalizedString(@"minutes", nil)];
        
        [self.view makeToast:toastMsg
                    duration:3.0
                    position:CSToastPositionBottom];

        _deviceStatusChangedFlag = false;
    }
}

- (void)saveSnoozeToDB:(int)serviceId minutes:(int)minutes
{
    int snooze = 0;
    
    if (serviceId != RELAY_SERVICE && serviceId != NIGHTLED_SERVICE && serviceId != IR_SERVICE) {
        NSLog(@"Invalid service ID!!!");
        return;
    }
    
    if(minutes > 0) {
        [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:serviceId snooze:snooze];
        snooze += minutes;
    } else {
        [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:serviceId snooze:0];
        snooze = 0;
    }
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
                id relay = [jsonObject objectForKey:@"relay"];
                id nightlight = [jsonObject objectForKey:@"nightlight"];
                id co_sensor = [jsonObject objectForKey:@"cosensor"];
                id hall_sensor = [jsonObject objectForKey:@"hallsensor"];
                id snooze = [jsonObject objectForKey:@"snooze"];
                id led_snooze = [jsonObject objectForKey:@"nightlightsnooze"];
                id ir_snooze = [jsonObject objectForKey:@"irsnooze"];
                
                NSString *model = [jsonObject objectForKey:@"model"];
                
                int buildNumber = 0;
                id sBuildNumber = [jsonObject objectForKey:@"buildnumber"];
                if ([sBuildNumber isKindOfClass:[NSNull class]]) {
                    buildNumber = 0;
                } else {
                    buildNumber = [sBuildNumber intValue];
                }

                int protocol = 0;
                id sProtocol = [jsonObject objectForKey:@"protocol"];
                if ([sProtocol isKindOfClass:[NSNull class]]) {
                    protocol = 0;
                } else {
                    protocol = [sProtocol intValue];
                }
                
                NSString *hardware_version = [jsonObject objectForKey:@"hardware"];
                NSString *firmware_version = [jsonObject objectForKey:@"firmware"];
                                              
                int firmwareDate = 0;
                id sfirmwaredate = [jsonObject objectForKey:@"firmwaredate"];
                if ([sfirmwaredate isKindOfClass:[NSNull class]]) {
                    firmwareDate = 0;
                } else {
                    firmwareDate = [sfirmwaredate intValue];
                }

                NSString *title = [jsonObject objectForKey:@"title"];
                NSString *icon = [jsonObject objectForKey:@"icon"];

                [[SQLHelper getInstance] updatePlugName:title sid:g_DeviceMac];
                [[SQLHelper getInstance] updatePlugIcon:g_DeviceMac icon:icon];
                
                NSLog(@"Devget returned: relay=%@, nightlight=%@, co_sensor=%@, hall_sensor=%@, snooze=%@",
                      relay, nightlight, co_sensor, hall_sensor, snooze);
                
                if(![relay isKindOfClass:[NSNull class]] && relay != nil) {
                    [[SQLHelper getInstance] updatePlugRelayService:[relay intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugRelayService:0 sid:g_DeviceMac];
                }
                if(![nightlight isKindOfClass:[NSNull class]] && nightlight != nil) {
                    [[SQLHelper getInstance] updatePlugNightlightService:[nightlight intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugNightlightService:0 sid:g_DeviceMac];
                }
                if(![co_sensor isKindOfClass:[NSNull class]] && co_sensor != nil) {
                    [[SQLHelper getInstance] updatePlugCoSensorService:[co_sensor intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugCoSensorService:0 sid:g_DeviceMac];
                }
                if(![hall_sensor isKindOfClass:[NSNull class]] && hall_sensor != nil) {
                    [[SQLHelper getInstance] updatePlugHallSensorService:[hall_sensor intValue] sid:g_DeviceMac];
                } else {
                    [[SQLHelper getInstance] updatePlugHallSensorService:0 sid:g_DeviceMac];
                }
                if(![snooze isKindOfClass:[NSNull class]] && snooze != nil) {
                    int snoozeVal = [snooze intValue];
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:snoozeVal];
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:0];
                }
                if(![led_snooze isKindOfClass:[NSNull class]] && led_snooze != nil) {
                    int ledSnoozeVal = [led_snooze intValue];
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:ledSnoozeVal];
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:0];
                }
                if(![ir_snooze isKindOfClass:[NSNull class]] && ir_snooze != nil) {
                    int irSnoozeVal = [ir_snooze intValue];
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:irSnoozeVal];
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:0];
                }
                
                [[SQLHelper getInstance] updateDeviceVersions:g_DeviceMac model:model build_no:buildNumber prot_ver:protocol hw_ver:hardware_version fw_ver:firmware_version fw_date:firmwareDate];
                
                //[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HTTP_DEVICE_STATUS
                //                                                    object:self
                //                                                  userInfo:nil];
                
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

                if (_serviceId == RELAY_SERVICE) {
                    [[SQLHelper getInstance] updatePlugRelayService:_action sid:g_DeviceMac];
                }
                if (_serviceId == NIGHTLED_SERVICE) {
                    [[SQLHelper getInstance] updatePlugNightlightService:_action sid:g_DeviceMac];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil userInfo:nil];
                
                // Update device status
                [self updateDeviceStatusFromServer];

            } else {
                // Failure
                NSLog(@"Set device status failed");
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"yes" forKey:@"error"];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HTTP_DEVICE_STATUS object:nil userInfo:userInfo];
            }
        } else if ([resultName isEqualToString:WS_ALARM_GET]) {
            if (data) {
                [self handleUpdateAlarm:data];
            }
        } else if ([resultName isEqualToString:WS_DEV_IR_GET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                [[SQLHelper getInstance] deleteIRGroups];
                
                NSArray *groups = (NSArray *)[jsonObject objectForKey:@"groups"];
                if (groups) {
                    NSLog(@"Total %ld groups", (unsigned long)groups.count);
                    
                    for (NSDictionary *group in groups) {
                        int groupId = [[group objectForKey:@"id"] intValue];
                        NSString *title = [group objectForKey:@"title"];
                        NSString *icon = [group objectForKey:@"icon"];
                        
                        //[[SQLHelper getInstance] updateIRCodeSID:_codeId sid:groupId];
                        
                        //[[SQLHelper getInstance] deleteIRGroupBySID:groupId];
                        //[[SQLHelper getInstance] deleteIRCodes:groupId];
                        //[[SQLHelper getInstance] insertIRGroup:title icon:icon position:0 sid:groupId];
                        
                        NSArray *buttons = (NSArray *)[group objectForKey:@"buttons"];
                        for (NSDictionary *button in buttons) {
                            int sid = [[button objectForKey:@"id"] intValue];
                            NSString *title = [button objectForKey:@"title"];
                            NSString *icon = [button objectForKey:@"icon"];
                            int code = [[button objectForKey:@"code"] intValue];
                            
                            [[SQLHelper getInstance] insertIRCodes:groupId name:title filename:code icon:icon mac:g_DeviceMac sid:sid];
                        }
                    }
                    
                    //[self updateView];
                }
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
