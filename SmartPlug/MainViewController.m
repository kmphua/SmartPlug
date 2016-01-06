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
#import "UDPListenerService.h"
#import "MainViewCell.h"
#import "JSmartPlug.h"

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, WebServiceDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, UDPListenerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *devices;               // Added plugs
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

@property (strong, nonatomic) NSMutableArray *services;
@property (strong, nonatomic) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic) BOOL searching;

@property (strong, nonatomic) UDPListenerService *udpListener;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.devices = [NSMutableArray new];
    
    // TODO: Update IP addresses with mDNS discovery
    
    
    // TODO: Start UDPListener and listen for broadcast packets from devices
    
    NSMutableDictionary *device1 = [NSMutableDictionary new];
    [device1 setObject:@"Desk Lamp" forKey:@"title"];
    [device1 setObject:[NSNumber numberWithBool:YES] forKey:@"hasTimer"];
    [device1 setObject:[NSNumber numberWithBool:NO] forKey:@"hasWarning"];
    [device1 setObject:@"see_Table Lamps_1_white_bkgnd" forKey:@"icon"];
    [self.devices addObject:device1];
    
    NSMutableDictionary *device2 = [NSMutableDictionary new];
    [device2 setObject:@"Bedroom" forKey:@"title"];
    [device2 setObject:[NSNumber numberWithBool:NO] forKey:@"hasTimer"];
    [device2 setObject:[NSNumber numberWithBool:YES] forKey:@"hasWarning"];
    [device2 setObject:@"see_bedroom_1_white_bkgnd" forKey:@"icon"];
    [self.devices addObject:device2];
    
    NSMutableDictionary *device3 = [NSMutableDictionary new];
    [device3 setObject:@"TV" forKey:@"title"];
    [device3 setObject:[NSNumber numberWithBool:YES] forKey:@"hasTimer"];
    [device3 setObject:[NSNumber numberWithBool:YES] forKey:@"hasWarning"];
    [device3 setObject:@"see_TV_1_white_bkgnd" forKey:@"icon"];
    [self.devices addObject:device3];

    NSMutableDictionary *device4 = [NSMutableDictionary new];
    [device4 setObject:@"Kitchen" forKey:@"title"];
    [device4 setObject:[NSNumber numberWithBool:YES] forKey:@"hasTimer"];
    [device4 setObject:[NSNumber numberWithBool:YES] forKey:@"hasWarning"];
    [device4 setObject:@"see_Datong Electric Pans_1_white_bkgnd" forKey:@"icon"];
    [self.devices addObject:device4];

    NSMutableDictionary *device5 = [NSMutableDictionary new];
    [device5 setObject:@"Wi-Fi" forKey:@"title"];
    [device5 setObject:[NSNumber numberWithBool:YES] forKey:@"hasTimer"];
    [device5 setObject:[NSNumber numberWithBool:YES] forKey:@"hasWarning"];
    [device5 setObject:@"see_Wi-Fi sharing device_1_white_bkgnd" forKey:@"icon"];
    [self.devices addObject:device5];
    
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add navigation buttons
    UIBarButtonItem *leftBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_schedule"] style:UIBarButtonItemStylePlain target:self action:@selector(onLeftBarButton:)];
    self.navigationItem.leftBarButtonItem = leftBarBtn;

    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    _udpListener = [UDPListenerService getInstance];
    _udpListener.delegate = self;
    [_udpListener startUdpBroadcastListener];
    
    /*
    self.devices = [JSmartPlug MR_findAll];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
    [self startBrowsing];
    */
    
    /*
    WebService *ws = [[WebService alloc] init];
    ws.delegate = self;
    [ws devList:g_UserToken lang:[Global getCurrentLang] iconRes:ICON_RES_2x];
    [ws showWaitingView:self.view];
     */
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_udpListener) {
        [_udpListener stopUdpBroadcastListener];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

//==================================================================
#pragma mark - Bonjour service discovery
//==================================================================

- (void)startBrowsing {
    if (self.services) {
        [self.services removeAllObjects];
    } else {
        self.services = [NSMutableArray new];
    }
    
    // Initialize Service Browser
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    
    // Configure Service Browser
    [self.serviceBrowser setDelegate:self];
    [self.serviceBrowser searchForServicesOfType:SERVICE_TYPE inDomain:@"local."];
}

- (void)stopBrowsing {
    if (self.serviceBrowser) {
        [self.serviceBrowser stop];
        [self.serviceBrowser setDelegate:nil];
        [self setServiceBrowser:nil];
    }
    self.searching = NO;
}

// Error handling code
- (void)handleError:(NSNumber *)error {
    NSString *errorMsg = [NSString stringWithFormat:@"An error occurred.\nNSNetServicesErrorCode = %d", [error intValue]];
    // Handle error here
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)                                                                    message:errorMsg
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

//==================================================================
#pragma mark - NSNetServiceBrowserDelegate
//==================================================================

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser {
    self.searching = YES;
}

// Sent when browsing stops
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser {
    [self stopBrowsing];
}

// Sent if browsing fails
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary *)errorDict {
    [self stopBrowsing];
    self.searching = NO;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    NSLog(@"Found domain: %@", domainString);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services addObject:service];
    
    // Sort Services
    [self.services sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    
    // Resolve Service
    [service setDelegate:self];
    [service resolveWithTimeout:30.0];
    
    if (!moreComing) {
        [self stopBrowsing];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services removeObject:service];
    
    if (!moreComing) {
        [self stopBrowsing];
    }
}

//==================================================================
#pragma mark - NSNetServiceDelegate
//==================================================================

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    
    if ([service.name compare:SMARTCONFIG_IDENTIFIER] == NSOrderedSame) {
        // Update IP address
        NSArray *plugs = [JSmartPlug MR_findAll];
        for (JSmartPlug *plug in plugs) {
            // Check if plug exists
            if ([plug.server compare:service.hostName] == NSOrderedSame) {
                NSArray *addresses = [[service addresses] mutableCopy];
                NSData *address = [addresses objectAtIndex:0];
                NSString *ip = [Global convertIpAddressToString:address];        
                if ([plug.ip compare:ip] != NSOrderedSame) {
                    plug.ip = ip;
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
                    [self.view makeToast:NSLocalizedString(@"DeviceAddressUpdated", nil)
                                duration:3.0
                                position:CSToastPositionCenter];
                }
                break;
            }
        }
    }
}

- (void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
    [service setDelegate:nil];
}

//==================================================================
#pragma mark - UDPListenerDelegate
//==================================================================

- (void)didReceiveData:(NSData *)data fromAddress:(NSString *)address {
    NSString *dataStr = [[NSString alloc] initWithBytes:[data bytes] length:data.length encoding:NSUTF8StringEncoding];
    NSLog(@"Received data from address %@: %@", address, dataStr);
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
    return [self.devices count];
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
    
    /*
    JSmartPlug *device = [self.devices objectAtIndex:[indexPath row]];
    NSString *deviceName = device.name;
    BOOL hasTimer = YES;
    BOOL hasWarning = YES;
    NSString *deviceUrl = @"see_Table Lamps_1_white_bkgnd";
     */
    
    NSDictionary *device = [self.devices objectAtIndex:[indexPath row]];
    NSString *deviceName = [device objectForKey:@"title"];
    BOOL hasTimer = [[device objectForKey:@"hasTimer"] boolValue];
    BOOL hasWarning = [[device objectForKey:@"hasWarning"] boolValue];
    NSString *deviceUrl = [device objectForKey:@"icon"];
    
    cell.lblDeviceName.text = deviceName;
    [cell.btnTimer setHidden:!hasTimer];
    [cell.btnWarn setHidden:!hasWarning];
    cell.imgDeviceIcon.image = [UIImage imageNamed:deviceUrl];
    
    // Modify cell background according to row position
    NSInteger rowCount = [self.devices count];
    NSInteger row = indexPath.row;
    if (row == rowCount-1) {
        // Last row
        NSString *cellBgImg = [NSString stringWithFormat:@"main_item_%ld_c", row%4];
        cell.imgCellBg.image = [UIImage imageNamed:cellBgImg];
    } else if (row == 0) {
        // First row
        NSString *cellBgImg = [NSString stringWithFormat:@"main_item_%ld_a", row%4];
        cell.imgCellBg.image = [UIImage imageNamed:cellBgImg];
    } else {
        // Middle row
        NSString *cellBgImg = [NSString stringWithFormat:@"main_item_%ld_b", row%4];
        cell.imgCellBg.image = [UIImage imageNamed:cellBgImg];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *device = [self.devices objectAtIndex:[indexPath row]];
    //JSmartPlug *device = [self.devices objectAtIndex:[indexPath row]];
    DeviceMainViewController *devMainVc = [[DeviceMainViewController alloc] initWithNibName:@"DeviceMainViewController" bundle:nil];
    devMainVc.device = device;
    [self.navigationController pushViewController:devMainVc animated:YES];
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
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *devices = (NSArray *)[jsonObject objectForKey:@"devs"];
                if (devices) {
                    NSLog(@"Total %ld devices", devices.count);
                    self.devices = [NSArray arrayWithArray:devices];
                }
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
