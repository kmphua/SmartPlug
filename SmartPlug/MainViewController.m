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
#import "mDNSService.h"

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, WebServiceDelegate, MainViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *devices;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

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
    //UIBarButtonItem *leftBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_schedule"] style:UIBarButtonItemStylePlain target:self action:@selector(onLeftBarButton:)];
    //self.navigationItem.leftBarButtonItem = leftBarBtn;

    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
    
    WebService *ws = [[WebService alloc] init];
    ws.delegate = self;
    [ws devList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
    [ws showWaitingView:self.view];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI:) name:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceFound:) name:NOTIFICATION_MDNS_DEVICE_FOUND object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceRemoved:) name:NOTIFICATION_MDNS_DEVICE_REMOVED object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_STATUS_CHANGED_UPDATE_UI object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MDNS_DEVICE_FOUND object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_MDNS_DEVICE_REMOVED object:nil];
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

- (void)updateUI:(NSNotification *)notification {
    self.devices = [[SQLHelper getInstance] getPlugData];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)handleDeviceFound:(NSNotification*)notification {
    self.devices = [[SQLHelper getInstance] getPlugData];
    [self syncDeviceIpAddresses];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)handleDeviceRemoved:(NSNotification*)notification {
    self.devices = [[SQLHelper getInstance] getPlugData];
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)syncDeviceIpAddresses {
    // Sync database with mDNS IP addresses
    NSArray *plugs = [[mDNSService getInstance] plugs];
    for (JSmartPlug *plug in plugs) {
        NSLog(@"Updating plug %@ with ip %@", plug.name, plug.ip);
        [[SQLHelper getInstance] updatePlugIP:plug.name ip:plug.ip];
    }
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
    
    JSmartPlug *plug = [self.devices objectAtIndex:[indexPath row]];
    
    if (plug.givenName && plug.givenName.length>0){
        cell.lblDeviceName.text = plug.givenName;
    } else {
        cell.lblDeviceName.text = plug.name;
    }

    if (plug.icon && plug.icon.length>0) {
        NSString *imagePath = plug.icon;
        [cell.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
    }
    
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
    
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSmartPlug *device = [self.devices objectAtIndex:[indexPath row]];
    DeviceMainViewController *devMainVc = [[DeviceMainViewController alloc] initWithNibName:@"DeviceMainViewController" bundle:nil];
    devMainVc.device = device;
    [self.navigationController pushViewController:devMainVc animated:YES];
}

//==================================================================
#pragma MainViewCellDelegate
//==================================================================
- (void)onClickBtnWarn:(id)sender
{
    MainViewCell *clickedCell = (MainViewCell*)[[sender superview] superview];
    NSIndexPath *indexPathCell = [self.tableView indexPathForCell:clickedCell];
    
    // Remove device
    JSmartPlug *plug = [self.devices objectAtIndex:indexPathCell.row];
    if ([[SQLHelper getInstance] deletePlugDataByID:plug.sid]) {
        WebService *ws = [WebService new];
        ws.delegate = self;
        [ws devDel:g_UserToken lang:[Global getCurrentLang] devId:plug.sid];
        
        self.devices = [[SQLHelper getInstance] getPlugData];
        [self.tableView reloadData];
        [self adjustHeightOfTableview];
    }
}

- (void)onClickBtnTimer:(id)sender
{
    
}

- (void)onClickBtnPower:(id)sender
{
    MainViewCell *clickedCell = (MainViewCell*)[[sender superview] superview];
    NSIndexPath *indexPathCell = [self.tableView indexPathForCell:clickedCell];

    JSmartPlug *plug = [self.devices objectAtIndex:indexPathCell.row];
    if ([plug.ip isEqualToString:@"0"]) {
        int action;
        int serviceId = RELAY_SERVICE;
        int relay = plug.relay;
        
        if (relay == 0) {
            action = 0x01;
        } else {
            action = 0x00;
        }
        
        if ([[UDPCommunication getInstance] setDeviceStatus:plug.ip serviceId:serviceId action:action]) {
            NSLog(@"SET DEVICE STATUS PROCESS");
        }
        
        relay = ~relay;
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
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *devices = (NSArray *)[jsonObject objectForKey:@"devs"];
                if (devices) {
                    NSLog(@"Total %ld devices", devices.count);
                    
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
                            [[SQLHelper getInstance] updatePlugServices:plug];
                        }
                    }
                }
                
                // Sync IP address
                [self syncDeviceIpAddresses];
                
                // Get devices from database
                self.devices = [[SQLHelper getInstance] getPlugData];
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
                self.devices = [[SQLHelper getInstance] getPlugData];
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
