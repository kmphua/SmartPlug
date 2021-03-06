//
//  AddDeviceViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "InitDevicesViewController.h"
#import "FirstTimeConfig.h"
#import "Reachability.h"
#import "JSmartPlug.h"
#import "UDPCommunication.h"
#import "mDNSService.h"
#include <arpa/inet.h>
#import "CrashCountDown.h"

@interface AddDeviceViewController () <UITableViewDataSource, UITableViewDelegate, WebServiceDelegate, InitDevicesDelegate>

@property (weak, nonatomic) IBOutlet UIView *titleBgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UITextView *tvDescription;
@property (weak, nonatomic) IBOutlet UIButton *btnInitDevices;
@property (weak, nonatomic) IBOutlet UIImageView *imgWait;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) FirstTimeConfig *config;
@property (nonatomic, strong) Reachability *wifiReachability;

@property (nonatomic, strong) NSMutableArray *plugs;
@property (nonatomic, strong) NSString *devId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *ip;

@property (nonatomic, strong) NSString *ssid;
@property (nonatomic, strong) NSString *gatewayAddress;
@property (nonatomic, strong) NSString *wifiPassword;

@property (nonatomic, strong) JSmartPlug *plug;
@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (strong, nonatomic) CrashCountDown *crashTimer;

@end

@implementation AddDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.titleBgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"title_addDevice", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_YELLOW];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    self.tvDescription.text = NSLocalizedString(@"msg_toStartBtn", nil);
    
    [self.btnInitDevices setTitle:NSLocalizedString(@"Initialize Devices", nil) forState:UIControlStateNormal];
    
    // Load animation images
    NSArray *waitImageNames = @[@"wait_0.png", @"wait_1.png", @"wait_2.png",
                                @"wait_3.png", @"wait_4.png", @"wait_5.png",
                                @"wait_6.png", @"wait_7.png"];
    NSMutableArray *waitImages = [[NSMutableArray alloc] init];
    for (int i = 0; i < waitImageNames.count; i++) {
        [waitImages addObject:[UIImage imageNamed:[waitImageNames objectAtIndex:i]]];
    }
    self.imgWait.animationImages = waitImages;
    self.imgWait.animationDuration = 0.5;
        
    // Check wifi connectivity
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifiStatusChanged:) name:kReachabilityChangedNotification object:nil];
    
    _wifiReachability = [Reachability reachabilityForLocalWiFi];
    [_wifiReachability connectionRequired];
    [_wifiReachability startNotifier];
    
    NetworkStatus netStatus = [_wifiReachability currentReachabilityStatus];
    if ( netStatus == NotReachable ) {// No activity if no wifi
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CC3x Alert" message:@"WiFi not available. Please check your WiFi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        [_btnInitDevices setEnabled:NO];
        _ssid = nil;
        _gatewayAddress = nil;
        _wifiPassword = nil;
    } else {
        NSLog(@"SSID = %@, Gateway IP = %@", [FirstTimeConfig getSSID], [FirstTimeConfig getGatewayAddress]);
        _ssid = [FirstTimeConfig getSSID];
        _gatewayAddress = [FirstTimeConfig getGatewayAddress];
        [_btnInitDevices setEnabled:YES];
    }
    
    _crashTimer = [CrashCountDown getInstance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // stopping the process in app backgroud state
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterInBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterInforground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceInfo:) name:NOTIFICATION_DEVICE_INFO object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceFound:) name:NOTIFICATION_MDNS_DEVICE_FOUND object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceRemoved:) name:NOTIFICATION_MDNS_DEVICE_REMOVED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestDeviceInfo:) name:NOTIFICATION_BROADCASTED_PRESENCE object:nil];
    
    //self.plugs = [[mDNSService getInstance] plugs];
    self.plugs = [NSMutableArray new];
    
    [self.tableView reloadData];
    [self.imgWait startAnimating];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBtnInitDevices:(id)sender {
    NetworkStatus netStatus = [_wifiReachability currentReachabilityStatus];
    if ( netStatus == NotReachable ) {// No activity if no wifi
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CC3x Alert" message:@"WiFi not available. Please check your WiFi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    } else {
        InitDevicesViewController *inputAlertVC = [[InitDevicesViewController alloc] initWithNibName:@"InitDevicesViewController" bundle:nil];
        inputAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        inputAlertVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        inputAlertVC.ssid = [FirstTimeConfig getSSID];
        inputAlertVC.delegate = self;
        [self presentViewController:inputAlertVC animated:YES completion:nil];
    }
}

/*
- (void)updateUI {
    if (self.searching) {
        [self.imgWait startAnimating];
    }
    else {
        [self.imgWait stopAnimating];
    }
}
*/

- (void)handleDeviceInfo:(NSNotification*)notification {
    NSLog(@"%s", __func__);
    
    // Update device info
    NSDictionary *userInfo = notification.userInfo;
    _ip = [userInfo objectForKey:@"ip"];
    _devId = [userInfo objectForKey:@"id"];
    
    NSLog(@"DEVICE INFO RECEIVED IP: %@ ID: %@", _ip, _devId);
    
    NSString *model = [userInfo objectForKey:@"model"];
    model = [model stringByReplacingOccurrencesOfString:@" " withString:@""];
    int buildno = [[userInfo objectForKey:@"buildno"] intValue];
    int prot_ver = [[userInfo objectForKey:@"prot_ver"] intValue];
    NSString *hw_ver = [userInfo objectForKey:@"hw_ver"];
    NSString *fw_ver = [userInfo objectForKey:@"fw_ver"];
    int fw_date = [[userInfo objectForKey:@"fw_date"] intValue];
    int flag = [[userInfo objectForKey:@"flag"] intValue];
    
    for (JSmartPlug *plug in _plugs) {
        if ([plug.name isEqualToString:_plug.name]) {
            plug.sid = _devId;
            plug.model = model;
            plug.buildno = buildno;
            plug.prot_ver = prot_ver;
            plug.hw_ver = hw_ver;
            plug.fw_ver = fw_ver;
            plug.fw_date = fw_date;
            plug.flag = flag;
        }
    }
    
    // Activate device
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws actDev:g_UserToken lang:[Global getCurrentLang] devId:_devId title:g_DeviceName model:model];
}

- (void)handleDeviceFound:(NSNotification*)notification {
    NSDictionary *userInfo = notification.userInfo;
    _name = [userInfo objectForKey:@"name"];
    _ip = [userInfo objectForKey:@"ip"];
    NSLog(@"New Device Received %@, IP %@", _name, _ip);
    [self updateListNew:_name ip:_ip mac:_devId];
}

- (void)handleDeviceRemoved:(NSNotification*)notification {
    self.plugs = [[mDNSService getInstance] plugs];
    [self.tableView reloadData];
}

- (void)requestDeviceInfo:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        _name = [userInfo objectForKey:@"name"];
        _ip = [userInfo objectForKey:@"ip"];
        _devId = [userInfo objectForKey:@"macId"];
        NSLog(@"New Device Received %@, IP %@, MAC %@", _name, _ip, _devId);
        [self updateListNew:_name ip:_ip mac:_devId];
        [[UDPCommunication getInstance] queryDevices:_devId command:UDP_CMD_DEVICE_QUERY];
    }
}

- (void)updateListNew:(NSString *)name ip:(NSString *)ip mac:(NSString *)mac
{
    // Check if the name is not already in the database
    BOOL plugExist = false;
    NSArray *plugData = [[SQLHelper getInstance] getPlugDataByName:name];
    if (plugData && plugData.count > 0){
        plugExist = true;
    } else {
        if (name != nil && name.length>0 && ip != nil && ip.length>0) {
            if (_plugs.count > 0) {
                //check if the name is not already in the plugs array
                for (int i = 0; i < _plugs.count; i++) {
                    JSmartPlug *plug = [_plugs objectAtIndex:i];
                    if ([plug.name isEqualToString:name]) {
                        plugExist = true;
                    } else {
                        JSmartPlug *jSmartPlug = [JSmartPlug new];
                        jSmartPlug.name = name;
                        jSmartPlug.ip = ip;
                        jSmartPlug.sid = mac;
                        NSLog(@"Plug Added, Name: %@", jSmartPlug.name);
                        [_plugs addObject:jSmartPlug];
                        [self.tableView reloadData];
                    }
                }
            } else {
                JSmartPlug *jSmartPlug = [JSmartPlug new];
                jSmartPlug.name = name;
                jSmartPlug.ip = ip;
                jSmartPlug.sid = mac;
                NSLog(@"Plug Added, Name: %@", jSmartPlug.name);
                [_plugs addObject:jSmartPlug];
                [self.tableView reloadData];
            }
            
            if (!plugExist) {
                [self.tableView reloadData];
            }
        }
    }
}

//==================================================================
#pragma mark - UDPCommunicationDelegate
//==================================================================

- (void)didReceiveData:(NSData *)data fromAddress:(NSString *)address {
    NSLog(@"Received data %@ from %@", data, address);
    
    // Check added plugs
    NSArray *plugs = [[SQLHelper getInstance] getPlugData:address];
    if (plugs) {
        //JSmartPlug *plug = [plugs objectAtIndex:0];
        NSString *devIdStr = [[NSString alloc] initWithBytes:[data bytes] length:data.length encoding:NSUTF8StringEncoding];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *devId = [f numberFromString:devIdStr];
        if (devId) {
            //plug.sid = devId intValue;
            //[[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
            
            // Update to web service
            WebService *ws = [WebService new];
            ws.delegate = self;
            
            //NSString *devId = [NSString stringWithFormat:@"%d", [plug.devid intValue]];
            //[ws newDev:g_UserToken lang:[Global getCurrentLang] devId:devId iconRes:ICON_RES_1x title:@"" notifyPower:@"0" notifyTimer:@"" notifyDanger:@"" oriTitle:plug.name ip:plug.ip server:plug.server snooze:@"" relay:@""];
        } else {
            NSLog(@"Error converting device ID!");
        }
    }
}

//==================================================================
#pragma mark - Service UDP connection
//==================================================================

- (BOOL)connectWithService:(NSNetService *)service {
    BOOL _isConnected = NO;
    
    // Copy Service Addresses
    NSArray *addresses = [[service addresses] mutableCopy];
    
    if (!self.socket || ![self.socket isConnected]) {
        // Initialize Socket
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // Connect
        while (!_isConnected && [addresses count]) {
            NSData *address = [addresses objectAtIndex:0];
            
            NSError *error = nil;
            if ([self.socket connectToAddress:address error:&error]) {
                _isConnected = YES;
                
            } else if (error) {
                NSLog(@"Unable to connect to address. Error %@ with user info %@.", error, [error userInfo]);
            }
        }
        
    } else {
        _isConnected = [self.socket isConnected];
    }
    
    return _isConnected;
}

//==================================================================
#pragma mark - InitDevicesDelegate
//==================================================================
- (void)ssidPassword:(NSString *)password
{
    NSLog(@"SSID password is %@", password);
    _wifiPassword = password;
    
    // Start broadcast
    [self startTransmitting];
}

//==================================================================
#pragma mark - Wifi connection
//==================================================================
/*
 Notification method handler when app enter in forground
 @param the fired notification object
 */
- (void)appEnterInforground:(NSNotification*)notification{
    NSLog(@"%s", __func__);
    //ssidField.text = [FirstTimeConfig getSSID];
    //ipAddress.text = [FirstTimeConfig getGatewayAddress];
}

/*
 Notification method handler when app enter in background
 @param the fired notification object
 */
- (void)appEnterInBackground:(NSNotification*)notification{
    NSLog(@"%s", __func__);
    //if ( startbutton.selected )
    //    [self buttonAction:startbutton]; /// Simply revert the state
}

/*
 Notification method handler when status of wifi changes
 @param the fired notification object
 */
- (void)wifiStatusChanged:(NSNotification*)notification{
    NSLog(@"%s", __func__);
    Reachability *verifyConnection = [notification object];
    NSAssert(verifyConnection != NULL, @"currentNetworkStatus called with NULL verifyConnection Object");
    NetworkStatus netStatus = [verifyConnection currentReachabilityStatus];
    if ( netStatus == NotReachable ){
        // The operation couldn’t be completed. No route to host
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CC3x Alert" message:@"Wifi Not available. Please check your wifi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        _ssid = nil;
        _gatewayAddress = nil;
        _wifiPassword = nil;
        [_btnInitDevices setEnabled:NO];
    } else {
        NSLog(@"SSID = %@, Gateway IP = %@", [FirstTimeConfig getSSID], [FirstTimeConfig getGatewayAddress]);
        _ssid = [FirstTimeConfig getSSID];
        _gatewayAddress = [FirstTimeConfig getGatewayAddress];
        [_btnInitDevices setEnabled:YES];
    }
}

//==================================================================
#pragma mark - SmartConfig
//==================================================================

/*
 This method begins configuration transmit
 In case of a failure the method throws an OSFailureException.
 */
- (void)sendAction {
    @try {
        NSLog(@"%s begin", __PRETTY_FUNCTION__);
        [_config transmitSettings];
        NSLog(@"%s end", __PRETTY_FUNCTION__);
    }
    @catch (NSException *exception) {
        NSLog(@"exception === %@",[exception description]);
        //if ( startbutton.selected )/// start button in sending mode
          //  [self buttonAction:startbutton];
    }
    @finally {
        
    }
}

/*
 This method stop the sending of the configuration to the remote device
 In case of a failure the method throws an OSFailureException.
 */
- (void)stopAction {
    NSLog(@"%s begin", __PRETTY_FUNCTION__);
    @try {
        [_config stopTransmitting];
    }
    @catch (NSException *exception) {
        NSLog(@"%s exception == %@",__FUNCTION__,[exception description]);
    }
    @finally {
        
    }
    NSLog(@"%s end", __PRETTY_FUNCTION__);
}

/*
 This method waits for an acknowledge from the remote device than it stops the transmit to the remote device and returns with data it got from the remote device.
 This method blocks until it gets respond.
 The method will return true if it got the ack from the remote device or false if it got aborted by a call to stopTransmitting.
 In case of a failure the method throws an OSFailureException.
 */

- (void)waitForAckThread:(id)sender {
    @try {
        NSLog(@"%s begin", __PRETTY_FUNCTION__);
        Boolean val = [_config waitForAck];
        NSLog(@"Bool value == %d",val);
        if ( val ){
            [self stopAction];
            [self enableUIAccess:YES];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%s exception == %@",__FUNCTION__,[exception description]);
        /// stop here
    }
    @finally {
    }
    
    if ( [NSThread isMainThread]  == NO ){
        NSLog(@"this is not main thread");
        [NSThread exit];
    }else {
        NSLog(@"this is main thread");
    }
    NSLog(@"%s end", __PRETTY_FUNCTION__);
}

/*
 This method start the transmitting the data to connected
 AP. Nerwork validation is also done here. All exceptions from
 library is handled.
 */
- (void)startTransmitting {
    @try {
        NetworkStatus netStatus = [_wifiReachability currentReachabilityStatus];
        if ( netStatus == NotReachable ){// No activity if no wifi
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"CC3x Alert" message:@"WiFi not available. Please check your WiFi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
            return;
        }
        
        if ( _config )
            _config = nil;
        
        if ( _ssid && _wifiPassword ){
            _config = [[FirstTimeConfig alloc] initWithKey:_wifiPassword withEncryptionKey:nil];
        } else {
            _config = [[FirstTimeConfig alloc] init];
        }
        
        // Setting the device name
        //if ( [deviceName.text length] <= 0 )deviceName.text = @"CC3000";
        
        [_config setDeviceName:@"CC3000"];
        
        [self sendAction];
        
        [NSThread detachNewThreadSelector:@selector(waitForAckThread:) toTarget:self withObject:nil];
        
        //NSTimer *stopTimer = [NSTimer scheduledTimerWithTimeInterval:SMARTCONFIG_BROADCAST_TIME target:self selector:@selector(stopAction) userInfo:nil repeats:NO];
                              
        [self enableUIAccess:NO];
    }
    @catch (NSException *exception) {
        NSLog(@"%s exception == %@",__FUNCTION__,[exception description]);
        [self enableUIAccess:YES];
        // Sandy: may be alert for user ...
        
    }
    @finally {
    }
}

#pragma mark - Private Methods -

/* enableUIAccess
 * enable / disable the UI access like enable / disable the textfields
 * and other component while transmitting the packets.
 * @param: vbool is to validate the controls.
 */
- (void)enableUIAccess:(BOOL)isEnable {
    [_btnInitDevices setEnabled:isEnable];
}


//==================================================================
#pragma mark - GCDAsyncSocketDelegate
//==================================================================

- (void)socket:(GCDAsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Socket Did Connect to Host: %@ Port: %hu", host, port);
    
    // Start Reading
    [socket readDataToLength:sizeof(uint64_t) withTimeout:-1.0 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error {
    NSLog(@"Socket Did Disconnect with Error %@ with User Info %@.", error, [error userInfo]);
    
    [socket setDelegate:nil];
    //[self setSocket:nil];
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
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    // Fetch Service
    JSmartPlug *plug = [self.plugs objectAtIndex:[indexPath row]];
    
    // Configure Cell
    [cell.textLabel setText:plug.name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Add device to device list
    JSmartPlug *plug = [self.plugs objectAtIndex:[indexPath row]];
    _plug = plug;

    [[SQLHelper getInstance] insertPlug:plug active:1];

    // Set temp device name
    g_DeviceName = plug.name;
    
    // Activate device
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws actDev:g_UserToken lang:[Global getCurrentLang] devId:plug.sid title:g_DeviceName model:plug.model];
    
    [[UDPCommunication getInstance] queryDevices:plug.sid command:UDP_CMD_DEVICE_QUERY];
     
    [self.view makeToast:NSLocalizedString(@"msg_pleaseWait", nil)
                duration:3.0
                position:CSToastPositionBottom];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName webservice:(WebService *)ws {
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
        
        if ([resultName compare:WS_ACT_DEV] == NSOrderedSame) {
            NSString *result = [jsonObject objectForKey:@"r"];
            if ([result isEqualToString:@"0"]) {
                // Success
                [self.view makeToast:NSLocalizedString(@"title_deviceAdded", nil)
                            duration:3.0
                            position:CSToastPositionBottom];
                
                [[SQLHelper getInstance] insertPlug:_plug active:1];
                
                //NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                [self.navigationController popViewControllerAnimated:YES];
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

- (void)connectFail:(NSString*)resultName webservice:(WebService *)ws {
    NSLog(@"Connect fail for %@", resultName);
}

@end
