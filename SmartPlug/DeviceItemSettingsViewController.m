//
//  DeviceItemSettingsViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "DeviceItemSettingsViewController.h"
#import "DeviceIconViewController.h"
#import "DQAlertView.h"

@interface DeviceItemSettingsViewController ()<DeviceIconDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) BOOL deviceInRange;
@property (nonatomic, strong) UITextField *txtName;

@end

@implementation DeviceItemSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (self.device.ip && self.device.ip.length>0) {
        _deviceInRange = YES;
    } else {
        _deviceInRange = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // TODO: Get Device Status
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (_deviceInRange) {
        return 9;
    } else {
        return 10;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 75;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [view setBackgroundColor:[Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [label setFont:[UIFont systemFontOfSize:32]];
    [label setTextColor:[UIColor whiteColor]];
    
    if (self.device.givenName && self.device.givenName.length > 0) {
        label.text = self.device.givenName;
    } else {
        label.text = self.device.name;
    }
    [label setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:label];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableViewCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    NSInteger row = indexPath.row;
    switch (row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"id_sevice", nil);
            cell.detailTextLabel.text = @"JSPlug";
            break;
        case 1:
        {
            cell.textLabel.text = NSLocalizedString(@"id_icon", nil);
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            if (self.device.icon && self.device.icon.length>0) {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 30, 7, 40, 40)];
                
                int iconId = [self.device.icon intValue];
                if (g_DeviceIcons) {
                    NSDictionary *icon = [g_DeviceIcons objectAtIndex:iconId-1];
                    NSString *imagePath = [icon objectForKey:@"url"];
                    [imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
                }
                [cell addSubview:imageView];
            }
        }
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"id_name", nil);
            if (self.device.givenName && self.device.givenName.length > 0) {
                cell.detailTextLabel.text = self.device.givenName;
            } else {
                cell.detailTextLabel.text = self.device.name;
            }
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"id_wifi", nil);
            cell.detailTextLabel.text = self.device.server;
            break;
        case 4:
            if (_deviceInRange) {
                cell.textLabel.text = @"CO sensor";
            } else {
                cell.textLabel.text = NSLocalizedString(@"id_macID", nil);
                cell.detailTextLabel.text = self.device.sid;
            }
            break;
        case 5:
            if (_deviceInRange) {
                cell.textLabel.text = @"Hardware";
                cell.detailTextLabel.text = self.device.hw_ver;
            } else {
                cell.textLabel.text = @"Notify on power outage";
            }
            break;
        case 6:
            if (_deviceInRange) {
                cell.textLabel.text = @"Firmware";
                cell.detailTextLabel.text = self.device.fw_ver;
            } else {
                cell.textLabel.text = @"Notify on CO warning";
            }
            break;
        case 7:
            if (_deviceInRange) {
                cell.textLabel.text = NSLocalizedString(@"id_macID", nil);
                cell.detailTextLabel.text = self.device.sid;
            } else {
                cell.textLabel.text = @"Notify on timer activated";
            }
            break;
        case 8:
            if (_deviceInRange) {
                cell.textLabel.text = NSLocalizedString(@"lnk_removeAndReset", nil);
            } else {
                cell.textLabel.text = NSLocalizedString(@"msg_deskLampBtn", nil);
            }
            break;
        case 9:
            cell.textLabel.text = NSLocalizedString(@"lnk_removeAndReset", nil);
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1) {
        // Get device icons
        DeviceIconViewController *iconVC = [[DeviceIconViewController alloc] initWithNibName:@"DeviceIconViewController" bundle:nil];
        iconVC.delegate = self;
        [self.navigationController pushViewController:iconVC animated:YES];
    } else if (indexPath.row == 2) {
        // Set device name
        DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:@"Device Name"
                                                message:@"Please enter new device name"
                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                       otherButtonTitle:NSLocalizedString(@"OK", nil)];
        
        alertView.hideSeperator = YES;
        alertView.customFrame = CGRectMake(0, 0, 320, 200);
        alertView.titleHeight = 50;
        alertView.messageLeftRightPadding = 50;
        
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 150)];
        UITextField *txtName = [[UITextField alloc] initWithFrame:CGRectMake(60, 120, 200, 30)];
        txtName.backgroundColor = [UIColor whiteColor];
        txtName.borderStyle = UITextBorderStyleNone;
        txtName.textAlignment = NSTextAlignmentCenter;
        txtName.text = (_device.givenName && _device.givenName.length>0) ? _device.givenName : _device.name;
        txtName.delegate = self;
        _txtName = txtName;
        [contentView addSubview:txtName];
        
        UILabel *lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(60, 26, 200, 30)];
        lblTitle.font = [UIFont systemFontOfSize:18.0];
        lblTitle.text = @"Device name";
        lblTitle.textAlignment = NSTextAlignmentCenter;
        [contentView addSubview:lblTitle];
        
        UILabel *lblMessage = [[UILabel alloc] initWithFrame:CGRectMake(60, 60, 200, 100)];
        lblMessage.font = [UIFont systemFontOfSize:15.0];
        lblMessage.text = @"Please enter new device name";
        lblMessage.numberOfLines = 0;
        [lblMessage sizeToFit];
        [contentView addSubview:lblMessage];
        contentView.backgroundColor = [UIColor clearColor];
        alertView.contentView = contentView;
        
        alertView.center = self.view.center;
        
        alertView.cancelButtonAction = ^{
            NSLog(@"Cancel button clicked");
        };
        alertView.otherButtonAction = ^{
            [[SQLHelper getInstance] updatePlugName:_txtName.text sid:_device.sid];
            _device.givenName = _txtName.text;
            [self.tableView reloadData];
        };
        [alertView show];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//==================================================================
#pragma DeviceIconDelegate
//==================================================================
- (void)selectedIcon:(int)iconId
{
    // Update device icon
    _device.icon = [NSString stringWithFormat:@"%d", iconId];
    [[SQLHelper getInstance] updatePlugIcon:_device.sid icon:[NSString stringWithFormat:@"%d", iconId]];
    [self.tableView reloadData];
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
        
        if ([resultName isEqualToString:WS_DEV_LIST]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *devices = (NSArray *)[jsonObject objectForKey:@"devs"];
                if (devices) {
                    NSLog(@"Total %ld actions", devices.count);
                }
                [self.tableView reloadData];
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
