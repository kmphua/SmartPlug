//
//  MainViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "MainViewController.h"
#import "AddDeviceViewController.h"
#import "DeviceMainViewController.h"
#import "SettingsViewController.h"
#import "ScheduleMainViewController.h"
#import "MainViewCell.h"
#import "JSmartPlug.h"
#import "UDPCommunication.h"
#import "UDPListenerService.h"
#import "mDNSService.h"
#import "MBProgressHUD.h"

#define STATUS_CHECKER_TIMER_INTERVAL       7

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, WebServiceDelegate, MainViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *plugs;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

@property (strong, nonatomic) MBProgressHUD *hud;
@property (nonatomic) BOOL deviceStatusChangedFlag;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    _deviceStatusChangedFlag = false;
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws galleryList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
        
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    // Check network availability
    if (![Global isNetworkReady]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_network_error", nil) message:NSLocalizedString(@"msg_unable_to_connect", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    // Remove all plugs
    //[[SQLHelper getInstance] deletePlugs];
    
    // Get device list
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
    [self showWaitingIndicator];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceInfo:) name:NOTIFICATION_DEVICE_INFO object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceFound:) name:NOTIFICATION_MDNS_DEVICE_FOUND object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceRemoved:) name:NOTIFICATION_MDNS_DEVICE_REMOVED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePush:) name:NOTIFICATION_PUSH object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceStatusChanged:) name:NOTIFICATION_DEVICE_STATUS_CHANGED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusChangedUpdateUI:) name:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(m1UpdateUI:) name:NOTIFICATION_M1_UPDATE_UI object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adapterOnClick:) name:NOTIFICATION_ADAPTER_ON_CLICK object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repeatingTaskDone:) name:NOTIFICATION_REPEATING_TASK_DONE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlarmServiceDone:) name:NOTIFICATION_UPDATE_ALARM_SERVICE_DONE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(httpDeviceStatus:) name:NOTIFICATION_HTTP_DEVICE_STATUS object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteSent:) name:NOTIFICATION_DELETE_SENT object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timerCrashReached:) name:NOTIFICATION_TIMER_CRASH_REACHED object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getData {
    self.plugs = [[SQLHelper getInstance] getPlugData];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)showWaitingIndicator {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.labelText = NSLocalizedString(@"please_wait_done",nil);
    [_hud show:YES];
}

- (void)dismissWaitingIndicator {
    [_hud hide:YES];
}

- (void)adjustHeightOfTableview
{
    CGFloat height = self.tableView.contentSize.height;
    CGFloat maxHeight = 0.85 * self.tableView.superview.frame.size.height;
    
    // if the height of the content is greater than the maxHeight of
    // total space on the screen, limit the height to the size of the
    // superview.
    
    if (height > maxHeight)
        height = maxHeight;
    
    // now set the height constraint accordingly
    
    [UIView animateWithDuration:0.25 animations:^{
        self.tableViewHeightConstraint.constant = height;
        [self.view setNeedsUpdateConstraints];
    }];
}

- (IBAction)onBtnAdd:(id)sender {
    AddDeviceViewController *addDeviceController = [[AddDeviceViewController alloc] initWithNibName:@"AddDeviceViewController" bundle:nil];
    [self.navigationController pushViewController:addDeviceController animated:YES];
}

- (void)onLeftBarButton:(id)sender {
    ScheduleMainViewController *scheduleVc = [[ScheduleMainViewController alloc] initWithNibName:@"ScheduleMainViewController" bundle:nil];
    [self.navigationController pushViewController:scheduleVc animated:YES];
}

- (void)onRightBarButton:(id)sender {
    SettingsViewController *settingsVc = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    [self.navigationController pushViewController:settingsVc animated:YES];
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
    [self getData];
}

- (void)repeatingTaskDone:(NSNotification *)notification {
    NSLog(@"Repeating TASK DONE");
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *error = [userInfo objectForKey:@"errorMessage"];
        if (error != nil && error.length>0) {
            [self.view makeToast:NSLocalizedString(@"connection_error", nil)
                        duration:3.0
                        position:CSToastPositionBottom];
        } else {
            NSLog(@"ERROR MESSAGE IS NULL");
        }
        
        [self getData];
        [self dismissWaitingIndicator];
    }
}

- (void)handlePush:(NSNotification *)notification {
    [self checkStatus:nil];
    //[self getData];
}

- (void)updateAlarmServiceDone:(NSNotification *)notification {
    [self getData];
}

- (void)statusChangedUpdateUI:(NSNotification *)notification {
    NSLog(@"DEVICE STATUS CHANGED UI");
    _deviceStatusChangedFlag = true;
    [self getData];
}

- (void)deviceStatusChanged:(NSNotification *)notification {
    _deviceStatusChangedFlag = true;
    
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *macId = [userInfo objectForKey:@"macId"];
        [self startRepeatingTaskByMac:macId];
    }
}

- (void)deviceInfo:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSString *ip = [userInfo objectForKey:@"ip"];
    //NSString *devId = [userInfo objectForKey:@"id"];
    
    JSmartPlug *jsTemp = [UDPListenerService getInstance].js;
    jsTemp.ip = ip;
    if (jsTemp.ip != nil && jsTemp.ip.length>0) {
        if(jsTemp.sid != nil && jsTemp.sid.length>0) {
            [[SQLHelper getInstance] updatePlugServices:jsTemp];
        }
    }
    
    // Update IP address of device
    if (jsTemp.name && jsTemp.name.length>0 && jsTemp.ip && jsTemp.ip.length>0) {
        NSLog(@"Updating device %@ IP to %@", jsTemp.name, jsTemp.ip);
        [[SQLHelper getInstance] updatePlugIP:jsTemp.name ip:jsTemp.ip];
    }
    
    NSArray *plugs = [[SQLHelper getInstance] getPlugDataByID:g_DeviceMac];
    if (plugs && plugs.count > 0) {
        JSmartPlug *plug = [plugs firstObject];
        NSString *model = plug.model;
        int buildnumber = plug.buildno;
        int protocol = plug.prot_ver;
        NSString *hardware = plug.hw_ver;
        NSString *firmware = plug.fw_ver;
        int firmwaredate = plug.fw_date;
        
        WebService *ws = [WebService new];
        ws.delegate = self;
        [ws devSet2:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac model:model buildNumber:buildnumber protocol:protocol hardware:hardware firmware:firmware firmwareDate:firmwaredate];
    }
    
    [self getData];
}

- (void)handleDeviceFound:(NSNotification*)notification {
    [self startRepeatingTask];
    NSLog(@"NEW DEVICE FOUND");
}

- (void)handleDeviceRemoved:(NSNotification*)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *serviceName = [userInfo objectForKey:@"name"];
        [[SQLHelper getInstance] updatePlugIP:serviceName ip:@""];
        NSLog(@"%@", serviceName);
    }
}

- (void)syncDeviceIpAddresses {
    // Sync database with mDNS IP addresses
    NSArray *plugs = [[mDNSService getInstance] plugs];
    for (JSmartPlug *plug in plugs) {
        NSLog(@"Updating plug %@ with ip %@", plug.name, plug.ip);
        if (plug.name && plug.name.length>0 && plug.ip && plug.ip.length>0) {
            [[SQLHelper getInstance] updatePlugIP:plug.name ip:plug.ip];
        }
    }
    
    self.plugs = [[SQLHelper getInstance] getPlugData];
}

- (void)m1UpdateUI:(NSNotification *)notification {
    NSLog(@"UDP BROADCAST RECEIVED");
    
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *macId = [userInfo objectForKey:@"macId"];
        [self startRepeatingTaskByMac:macId];
    }
}

- (void)checkStatus:(id)sender {
    // Remove all plugs
    //[[SQLHelper getInstance] deletePlugs];
    
    // Get device list
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
}

- (void)updateStatus {
    for (JSmartPlug *plug in _plugs) {
        if ([[UDPCommunication getInstance] queryDevices:plug.sid command:UDP_CMD_GET_DEVICE_STATUS]) {
            //[_crashTimer startTimer];
        } else {
            NSLog(@"IP IS NULL");
        }
        
        [self getDeviceStatus:plug.sid];
    }
}

- (void)startRepeatingTask {
    NSArray *plugs = [[SQLHelper getInstance] getPlugData];
    if (plugs && plugs.count > 0) {
        for (JSmartPlug *plug in plugs) {
            [[UDPCommunication getInstance] queryDevices:plug.sid command:UDP_CMD_GET_DEVICE_STATUS];
        }
    }
}

- (void)startRepeatingTaskByMac:(NSString *)macId {
    [[UDPCommunication getInstance] queryDevices:macId command:UDP_CMD_GET_DEVICE_STATUS];
}

- (BOOL)deviceHasAlarm:(NSString *)deviceId {
    BOOL toReturn = false;
    NSArray *alarms = [[SQLHelper getInstance] getAlarmDataByDevice:deviceId];
    if (alarms && alarms.count > 0) {
        toReturn = true;
    }
    return toReturn;
}

//==================================================================
#pragma mark - Table view delegate
//==================================================================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.plugs count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MainViewCell";
    MainViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [tableView registerNib:[UINib nibWithNibName:@"MainViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    JSmartPlug *plug = [self.plugs objectAtIndex:[indexPath row]];
    
    if (plug.givenName && plug.givenName.length>0){
        cell.lblDeviceName.text = plug.givenName;
    } else {
        cell.lblDeviceName.text = plug.name;
    }
    
    NSString *imagePath;
    if (plug.icon && plug.icon.length>0) {
        imagePath = plug.icon;
    } else {
        imagePath = DEFAULT_ICON_PATH;
    }
    [cell.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
    [cell.imgDeviceIcon setBackgroundColor:[Global colorWithType:COLOR_TYPE_ICON_BG]];
    
    if ([self deviceHasAlarm:plug.sid]) {
        [cell.btnTimer setHidden:NO];
        if (plug.snooze > 0) {
            [cell.btnTimer setBackgroundImage:[UIImage imageNamed:@"btn_timer_delay"] forState:UIControlStateNormal];
        }
    } else {
        [cell.btnTimer setHidden:YES];
    }

    if (plug.co_sensor > 0 || plug.hall_sensor > 0) {
        [cell.btnWarn setHidden:NO];
    } else {
        [cell.btnWarn setHidden:YES];
    }
    
    if (plug.relay == 0) {
        [cell.btnPower setBackgroundImage:[UIImage imageNamed:@"btn_power"] forState:UIControlStateNormal];
    } else {
        [cell.btnPower setBackgroundImage:[UIImage imageNamed:@"btn_power_pressed"] forState:UIControlStateNormal];
    }
    
    // Modify cell background according to row position
    NSInteger rowCount = [self.plugs count];
    NSInteger row = indexPath.row;
    if (row == rowCount-1) {
        // Last row
        NSString *cellBgImg = [NSString stringWithFormat:@"main_item_%d_c", (int)row%4];
        cell.imgCellBg.image = [UIImage imageNamed:cellBgImg];
    } else if (row == 0) {
        // First row
        NSString *cellBgImg = [NSString stringWithFormat:@"main_item_%d_a", (int)row%4];
        cell.imgCellBg.image = [UIImage imageNamed:cellBgImg];
    } else {
        // Middle row
        NSString *cellBgImg = [NSString stringWithFormat:@"main_item_%d_b", (int)row%4];
        cell.imgCellBg.image = [UIImage imageNamed:cellBgImg];
    }
    
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSmartPlug *plug = [self.plugs objectAtIndex:[indexPath row]];
    DeviceMainViewController *devMainVc = [[DeviceMainViewController alloc] initWithNibName:@"DeviceMainViewController" bundle:nil];
    devMainVc.device = plug;
    [self.navigationController pushViewController:devMainVc animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Remove device
        JSmartPlug *plug = [self.plugs objectAtIndex:indexPath.row];
        if ([[SQLHelper getInstance] deletePlugDataByID:plug.sid]) {
            NSLog(@"Device removed successfully %@", plug.sid);
            WebService *ws = [WebService new];
            ws.delegate = self;
            [ws devDel:g_UserToken lang:[Global getCurrentLang] devId:plug.sid];
            [self getData];
        }
    }
}

//==================================================================
#pragma MainViewCellDelegate
//==================================================================
- (void)onClickBtnWarn:(id)sender
{

}

- (void)onClickBtnTimer:(id)sender
{
    
}

- (void)onClickBtnPower:(id)sender
{
    MainViewCell *clickedCell = (MainViewCell*)[[sender superview] superview];
    NSIndexPath *indexPathCell = [self.tableView indexPathForCell:clickedCell];

    JSmartPlug *plug = [self.plugs objectAtIndex:indexPathCell.row];
    int action;
    int serviceId = RELAY_SERVICE;
    int relay = plug.relay;
    
    if (relay == 0) {
        action = 0x01;
    } else {
        action = 0x00;
    }
    
    if ([[UDPCommunication getInstance] setDeviceStatus:plug.sid serviceId:serviceId action:action]) {
        _deviceStatusChangedFlag = false;
    }
    
    /*
    
    if (_deviceStatusChangedFlag) {
        [[SQLHelper getInstance] updatePlugRelayService:action sid:plug.sid];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPEATING_TASK_DONE object:nil];
        
        [self setDeviceStatus:plug.sid serviceId:serviceId action:action send:1];
    } else {
        [self setDeviceStatus:plug.sid serviceId:serviceId action:action send:0];
        
        [[SQLHelper getInstance] updatePlugRelayService:action sid:plug.sid];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPEATING_TASK_DONE object:nil];
    }
    
    _deviceStatusChangedFlag = false;
     */
}
     
- (void)setDeviceStatus:(NSString *)devId serviceId:(int)serviceId action:(uint8_t)action send:(int)send
{
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
    uint8_t data = action;
    sMsg[19] = data;
    int terminator = 0x00000000;
    sMsg[23] = (uint8_t)(terminator & 0xff);
    sMsg[22] = (uint8_t)((terminator >> 8 ) & 0xff);
    sMsg[21] = (uint8_t)((terminator >> 16 ) & 0xff);
    sMsg[20] = (uint8_t)((terminator >> 24 ) & 0xff);
    
    NSLog(@"Data length = %ld", sizeof(sMsg));
    
    NSData *deviceData = [NSData dataWithBytes:sMsg length:sizeof(sMsg)];
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:devId send:send data:deviceData];
}

- (void)getDeviceStatus:(NSString *)devId
{
    if (devId) {
        WebService *ws = [WebService new];
        ws.delegate = self;
        [ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution] devId:devId];
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
        
        if ([resultName compare:WS_DEV_LIST] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                //NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *devices = (NSArray *)[jsonObject objectForKey:@"devs"];
                
                if (!devices || devices.count == 0) {
                    // Jump to add device page
                    g_DeviceMac = nil;
                    g_DeviceIp = nil;
                    AddDeviceViewController *addDeviceController = [[AddDeviceViewController alloc] initWithNibName:@"AddDeviceViewController" bundle:nil];
                    [self.navigationController pushViewController:addDeviceController animated:YES];
                }
                
                if (devices) {
                    NSLog(@"Total %ld devices", (unsigned long)devices.count);
                    
                    NSArray *plugs = [[SQLHelper getInstance] getPlugData];
                    NSMutableDictionary *macToPlugs = [NSMutableDictionary dictionary];
                    
                    for( JSmartPlug *plug in plugs ) {
                        [macToPlugs setObject:plug forKey:plug.sid];
                    }
                    
                    for (NSDictionary *device in devices) {
                        JSmartPlug *plug = [JSmartPlug new];
                        plug.name = [device objectForKey:@"title_origin"];
                        plug.givenName = [device objectForKey:@"title"];
                        plug.sid = [device objectForKey:@"devid"];
                        plug.icon = [device objectForKey:@"icon"];
                        
                        id relay = [device objectForKey:@"relay"];
                        if ([relay isKindOfClass:[NSNull class]]) {
                            plug.relay = 0;
                        } else {
                            plug.relay = [relay intValue];
                        }

                        id nightlight = [device objectForKey:@"nightlight"];
                        if ([nightlight isKindOfClass:[NSNull class]]) {
                            plug.nightlight = 0;
                        } else {
                            plug.nightlight = [nightlight intValue];
                        }

                        id cosensor = [device objectForKey:@"cosensor"];
                        if ([cosensor isKindOfClass:[NSNull class]]) {
                            plug.co_sensor = 0;
                        } else {
                            plug.co_sensor = [cosensor intValue];
                        }
                        
                        id hallsensor = [device objectForKey:@"hallsensor"];
                        if ([hallsensor isKindOfClass:[NSNull class]]) {
                            plug.hall_sensor = 0;
                        } else {
                            plug.hall_sensor = [hallsensor intValue];
                        }
                        
                        plug.model = [device objectForKey:@"model"];
                        
                        id buildNumber = [device objectForKey:@"buildnumber"];
                        if (![buildNumber isKindOfClass:[NSNull class]]) {
                            plug.buildno = 0;
                        } else {
                            plug.buildno = [buildNumber intValue];
                        }
                        
                        id protocol = [device objectForKey:@"protocol"];
                        if (![protocol isKindOfClass:[NSNull class]]) {
                            plug.prot_ver = 0;
                        } else {
                            plug.prot_ver = [protocol intValue];
                        }
                        
                        plug.hw_ver = [device objectForKey:@"hardware"];
                        plug.fw_ver = [device objectForKey:@"firmware"];
                        
                        id firmwaredate = [device objectForKey:@"firmwaredate"];
                        if (![firmwaredate isKindOfClass:[NSNull class]]) {
                            plug.fw_date = 0;
                        } else {
                            plug.fw_date = [firmwaredate intValue];
                        }
                        
                        if (plug.name == nil || plug.name.length == 0) {
                            plug.name = plug.givenName;
                        }
                        
                        [macToPlugs removeObjectForKey:plug.sid];

                        // Insert or update plug to database
                        [[SQLHelper getInstance] insertPlug:plug active:1];
                        NSLog(@"Inserted new plug %@ devId %@", plug.name, plug.sid);
                    }
                    
                    // Delete unwanted plugs
                    for (NSString *key in macToPlugs) {
                        [[SQLHelper getInstance] deletePlugDataByID:key];
                    }
                }
                
                // Sync IP address
                [self syncDeviceIpAddresses];
                
                // Get devices from database
                self.plugs = [[SQLHelper getInstance] getPlugData];
                [self.tableView reloadData];
                [self adjustHeightOfTableview];
                [self updateStatus];
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
        } else if ([resultName compare:WS_DEV_DEL] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Deleted device success - %@", message);
                
                // Get devices from database
                self.plugs = [[SQLHelper getInstance] getPlugData];
                [self.tableView reloadData];
                [self adjustHeightOfTableview];
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
                
            } else {
                // Failure
                NSLog(@"Set device status failed");
            }
        } else if ([resultName compare:WS_DEV_GET] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *relay = [jsonObject objectForKey:@"relay"];
                NSString *nightlight = [jsonObject objectForKey:@"nightlight"];
                NSString *co_sensor = [jsonObject objectForKey:@"cosensor"];
                NSString *hall_sensor = [jsonObject objectForKey:@"hallsensor"];
                NSString *snooze = [jsonObject objectForKey:@"snooze"];
                NSString *led_snooze = [jsonObject objectForKey:@"nightlightsnooze"];
                NSString *ir_snooze = [jsonObject objectForKey:@"irsnooze"];
                
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
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:[snooze intValue]];
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:RELAY_SERVICE snooze:0];
                }
                if(![led_snooze isKindOfClass:[NSNull class]] && led_snooze != nil) {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:[led_snooze intValue]];
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:NIGHTLED_SERVICE snooze:0];
                }
                if(![ir_snooze isKindOfClass:[NSNull class]] && ir_snooze != nil) {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:[led_snooze intValue]];
                } else {
                    [[SQLHelper getInstance] updateDeviceSnooze:g_DeviceMac serviceId:IR_SERVICE snooze:0];
                }
                
                [[SQLHelper getInstance] updateDeviceVersions:g_DeviceMac model:model build_no:buildNumber prot_ver:protocol hw_ver:hardware_version fw_ver:firmware_version fw_date:firmwareDate];
                
                // Get devices from database
                self.plugs = [[SQLHelper getInstance] getPlugData];
                [self.tableView reloadData];
                [self adjustHeightOfTableview];

                /*
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HTTP_DEVICE_STATUS
                                                                    object:self
                                                                  userInfo:nil];
                 */
                
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
        } else if ([resultName isEqualToString:WS_GALLERY_LIST]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSArray *icons = (NSArray *)[jsonObject objectForKey:@"icons"];
                if (icons) {
                    for (NSDictionary *icon in icons) {
                        NSString *url = [icon objectForKey:@"url"];
                        NSString *idParam = [icon objectForKey:@"id"];
                        
                        [[SQLHelper getInstance] insertIcons:url size:0 sid:idParam];
                    }
                }
            }
        } else if ([resultName isEqualToString:WS_DEV_SET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSLog(@"DB UPDATED SUCCESSFULLY");
                self.navigationItem.rightBarButtonItem.enabled = YES;
                [self dismissWaitingIndicator];
                //[self.navigationController popViewControllerAnimated:YES];
            } else {
                // Failure
                self.navigationItem.rightBarButtonItem.enabled = YES;
                [self dismissWaitingIndicator];
                
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
        
        [self dismissWaitingIndicator];
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
    [self dismissWaitingIndicator];
}

@end
