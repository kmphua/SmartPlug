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



#define SMARTCONFIG_BROADCAST_TIME      5  // seconds

@interface AddDeviceViewController () <UITableViewDataSource, UITableViewDelegate, WebServiceDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate, InitDevicesDelegate>

@property (weak, nonatomic) IBOutlet UIView *titleBgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UITextView *tvDescription;
@property (weak, nonatomic) IBOutlet UIButton *btnInitDevices;
@property (weak, nonatomic) IBOutlet UIImageView *imgWait;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;



@property (nonatomic, strong) FirstTimeConfig *config;
@property (nonatomic, strong) Reachability *wifiReachability;

@property (nonatomic, strong) NSString *ssid;
@property (nonatomic, strong) NSString *gatewayAddress;
@property (nonatomic, strong) NSString *wifiPassword;

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
    
    //// stoping the process in app backgroud state
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterInBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterInforground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
    //[self startBrowsing];
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
            unsigned char buffer[1];
            buffer[0] = 0x03;
            NSData *keyData = [NSData dataWithBytes:buffer length:1];
            _config = [[FirstTimeConfig alloc] initWithKey:_wifiPassword withEncryptionKey:keyData];
        } else {
            _config = [[FirstTimeConfig alloc] init];
        }
        
        // Setting the device name
        //if ( [deviceName.text length] <= 0 )deviceName.text = @"CC3000";
        
        //[_config setDeviceName:deviceName.text];
        
        [self sendAction];
        
        //[NSThread detachNewThreadSelector:@selector(waitForAckThread:) toTarget:self withObject:nil];
        
        NSTimer *stopTimer = [NSTimer scheduledTimerWithTimeInterval:SMARTCONFIG_BROADCAST_TIME target:self selector:@selector(stopAction) userInfo:nil repeats:NO];
                              
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
    return 1;
    //return [self.services count];
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
    NSNetService *service = [self.services objectAtIndex:[indexPath row]];
    
    // Configure Cell
    [cell.textLabel setText:[service name]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"btn_addingDevice", nil)                                                                    message:NSLocalizedString(@"msg_pleaseWait", nil)
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil, nil];
    [alertView show];
    
    NSNetService *service = [self.services objectAtIndex:[indexPath row]];
    // Resolve Service
    [service setDelegate:self];
    [service resolveWithTimeout:30.0];
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
        
        if ([resultName compare:WS_ACT_DEV] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *devices = (NSArray *)[jsonObject objectForKey:@"devs"];
               // if (devices) {
                   // NSLog(@"Total %ld devices", devices.count);
                 //   [self.devices setArray:devices];
                //}
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
        }
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}

@end
