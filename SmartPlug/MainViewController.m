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

@property (strong, nonatomic) NSTimer *statusCheckerTimer;
@property (strong, nonatomic) MBProgressHUD *hud;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
        
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    // Get plugs
    self.plugs = [[SQLHelper getInstance] getPlugData];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceInfo:) name:NOTIFICATION_DEVICE_INFO object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceFound:) name:NOTIFICATION_MDNS_DEVICE_FOUND object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceRemoved:) name:NOTIFICATION_MDNS_DEVICE_REMOVED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePush:) name:NOTIFICATION_PUSH object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceStatusChanged:) name:NOTIFICATION_DEVICE_STATUS_CHANGED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(m1UpdateUI:) name:NOTIFICATION_M1_UPDATE_UI object:nil];
    
    // Start status checker timer
    _statusCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:STATUS_CHECKER_TIMER_INTERVAL
                                                           target:self
                                                         selector:@selector(checkStatus:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    [self showWaitingIndicator];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_DEVICE_INFO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MDNS_DEVICE_FOUND object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MDNS_DEVICE_REMOVED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PUSH object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_DEVICE_STATUS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_M1_UPDATE_UI object:nil];
    
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

- (void)deviceInfo:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSString *ip = [userInfo objectForKey:@"ip"];
    //NSString *devId = [userInfo objectForKey:@"id"];
    JSmartPlug *jsTemp = [UDPListenerService getInstance].js;
    jsTemp.ip = ip;
    if (jsTemp.ip != nil && jsTemp.ip.length>0) {
        if(jsTemp.sid != nil && jsTemp.sid.length>0) {
            [[SQLHelper getInstance] updatePlugID:jsTemp.sid ip:jsTemp.ip];
            [[SQLHelper getInstance] updatePlugServices:jsTemp];
        }
    }
    
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)handleDeviceFound:(NSNotification*)notification {
    self.plugs = [[SQLHelper getInstance] getPlugData];
    [self syncDeviceIpAddresses];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)handleDeviceRemoved:(NSNotification*)notification {
    self.plugs = [[SQLHelper getInstance] getPlugData];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)handlePush:(NSNotification *)notification {
    // Delete plugs in database first
    [[SQLHelper getInstance] deletePlugs];
    
    // Update device list
    WebService *ws = [[WebService alloc] init];
    ws.delegate = self;
    [ws devList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
    [ws showWaitingView:self.view];
    NSLog(@"GET DEVICE LIST IP: %@", g_DeviceIp);
}

- (void)deviceStatusChanged:(NSNotification *)notification {
    [[UDPCommunication getInstance] queryDevices:g_DeviceIp udpMsg_param:UDP_CMD_GET_DEVICE_STATUS];
}

- (void)syncDeviceIpAddresses {
    // Sync database with mDNS IP addresses
    NSArray *plugs = [[mDNSService getInstance] plugs];
    for (JSmartPlug *plug in plugs) {
        NSLog(@"Updating plug %@ with ip %@", plug.name, plug.ip);
        [[SQLHelper getInstance] updatePlugIP:plug.name ip:plug.ip];
    }
}

- (void)m1UpdateUI:(NSNotification *)notification {
    NSLog(@"UDP BROADCAST RECEIVED");
}

- (void)checkStatus:(id)sender {
    if (g_DeviceIp) {
        if ([[UDPCommunication getInstance] queryDevices:g_DeviceIp udpMsg_param:UDP_CMD_GET_DEVICE_STATUS]) {
            //[_crashTimer startTimer];
        } else {
            NSLog(@"IP IS NULL");
        }
    }
    
    [self getDeviceStatus:g_DeviceMac];
    
    self.plugs = [[SQLHelper getInstance] getPlugData];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
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
    
    if (plug.icon && plug.icon.length>0) {
        NSString *imagePath = plug.icon;
        [cell.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
    }
    
    if ([[SQLHelper getInstance] getAlarmDataById:plug.dbid]) {
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
            WebService *ws = [WebService new];
            ws.delegate = self;
            [ws devDel:g_UserToken lang:[Global getCurrentLang] devId:plug.sid];
            
            self.plugs = [[SQLHelper getInstance] getPlugData];
            [self.tableView reloadData];
            [self adjustHeightOfTableview];
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
    
    [[UDPCommunication getInstance] setDeviceStatus:plug.ip serviceId:serviceId action:action];
    g_DeviceIp = plug.ip;
    g_DeviceMac = plug.sid;
    
    NSLog(@"CURRENTLY ON LISTDEVICEADAPTER: %@, MAC: %@", g_DeviceIp, g_DeviceMac);
    
    if ([[UDPListenerService getInstance] setDeviceStatusProcess:plug.ip serviceId:serviceId action:action]) {
        NSLog(@"SET DEVICE STATUS PROCESS");
    }
    
    [self setDeviceStatus:plug.sid serviceId:serviceId action:action];
    [self getDeviceStatus:plug.sid];

    // Update plugs
    self.plugs = [[SQLHelper getInstance] getPlugData];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}
     
- (void)setDeviceStatus:(NSString *)devId serviceId:(int)serviceId action:(uint8_t)action
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
    [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:devId send:1 data:deviceData];
}

- (void)getDeviceStatus:(NSString *)devId
{
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution] devId:devId];
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
                if (devices) {
                    NSLog(@"Total %ld devices", (unsigned long)devices.count);
                    
                    for (NSDictionary *device in devices) {
                        JSmartPlug *plug = [JSmartPlug new];
                        plug.name = [device objectForKey:@"title_origin"];
                        plug.givenName = [device objectForKey:@"title"];
                        plug.sid = [device objectForKey:@"devid"];
                        plug.icon = [device objectForKey:@"icon"];

                        NSArray *plugs = [[SQLHelper getInstance] getPlugDataByID:plug.sid];
                        if (!plugs || plugs.count == 0) {
                            // Insert new plug to database
                            [[SQLHelper getInstance] insertPlug:plug active:1];
                            NSLog(@"Inserted new plug %@ devId %@", plug.name, plug.sid);
                        } else {
                            // Update plug
                            //[[SQLHelper getInstance] updatePlugServices:plug];
                        }
                    }
                }
                
                // Sync IP address
                [self syncDeviceIpAddresses];
                
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
        
        [self dismissWaitingIndicator];
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
    [self dismissWaitingIndicator];
}

@end
