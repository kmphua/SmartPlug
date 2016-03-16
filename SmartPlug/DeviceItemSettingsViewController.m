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
#import "FirstTimeConfig.h"
#import "UDPCommunication.h"

@interface DeviceItemSettingsViewController ()<DeviceIconDelegate>
{
    int notify_on_power_outage;
    int notify_on_co_warning;
    int notify_on_timer_activated;
}

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
    
    notify_on_power_outage = 0;
    notify_on_co_warning = 0;
    notify_on_timer_activated = 0;
    
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    /*
    // Get Device Status
    NSArray *plugs = [[SQLHelper getInstance] getPlugDataByID:g_DeviceMac];
    if (plugs && plugs.count>0) {
        _device = [plugs firstObject];
        [self.tableView reloadData];
    }
     */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onRightBarButton:(id)sender {
    if (_device.notify_power) {
        notify_on_power_outage = 1;
    } else {
        notify_on_power_outage = 0;
    }
    if (_device.notify_co) {
        notify_on_co_warning = 1;
    } else {
        notify_on_co_warning = 0;
    }
    if (_device.notify_timer) {
        notify_on_timer_activated = 1;
    } else {
        notify_on_timer_activated = 0;
    }
    
    NSString *name = _txtName.text;
    if (g_DeviceMac && _deviceInRange) {
        BOOL result = [[SQLHelper getInstance] updatePlugNameNotify:g_DeviceMac
                                                               name:name
                                                notifyOnPowerOutage:notify_on_power_outage
                                                  notifyOnCoWarning:notify_on_co_warning
                                             notifyOnTimerActivated:notify_on_timer_activated
                                                               icon:_device.icon];
        
        if (result) {
            NSArray *icons = [[SQLHelper getInstance] getIconByUrl:_device.icon];
            NSString *iconId = @"";
            if(icons && icons.count > 0){
                Icon *icon = [icons firstObject];
                iconId = icon.sid;
            }
            
            WebService *ws = [WebService new];
            ws.delegate = self;
            [ws devSet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac icon:iconId title:name notifyPower:[NSString stringWithFormat:@"%d", notify_on_power_outage] notifyTimer:[NSString stringWithFormat:@"%d", notify_on_timer_activated] notifyDanger:[NSString stringWithFormat:@"%d",notify_on_co_warning]];
            
            NSLog(@"DB UPDATED SUCCESSFULLY");
        } else {
            NSLog(@"CHECK IF MAC ADDRESS IS NULL");
        }
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
    return 10;
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
            if (self.device.model) {
                cell.detailTextLabel.text = self.device.model;
            } else {
                cell.detailTextLabel.text = @"JSPlug";
            }
            break;
        case 1:
        {
            cell.textLabel.text = NSLocalizedString(@"id_icon", nil);
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            if (self.device.icon && self.device.icon.length>0) {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 30, 7, 40, 40)];
                NSString *imagePath = self.device.icon;
                [imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
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
            cell.detailTextLabel.text = [FirstTimeConfig getSSID];
            break;
        case 4:
            if (_deviceInRange) {
                cell.textLabel.text = @"CO sensor";
                if (self.device.co_sensor) {
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_check"]];
                }
            } else {
                cell.textLabel.text = NSLocalizedString(@"id_macID", nil);
                
                // Add colons to mac address
                if (self.device.sid && self.device.sid.length == 12) {
                    NSString *mac = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
                                     [_device.sid substringWithRange:NSMakeRange(0, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(2, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(4, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(6, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(8, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(10, 2)]];
                    cell.detailTextLabel.text = mac;
                } else {
                    cell.detailTextLabel.text = self.device.sid;
                }
            }
            break;
        case 5:
            if (_deviceInRange) {
                cell.textLabel.text = @"Hardware";
                cell.detailTextLabel.text = self.device.hw_ver;
            } else {
                cell.textLabel.text = @"Notify on power outage";
                if (self.device.notify_power) {
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_check"]];
                }
            }
            break;
        case 6:
            if (_deviceInRange) {
                cell.textLabel.text = @"Firmware";
                cell.detailTextLabel.text = self.device.fw_ver;
            } else {
                cell.textLabel.text = @"Notify on CO warning";
                if (self.device.notify_co) {
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_check"]];
                }
            }
            break;
        case 7:
            if (_deviceInRange) {
                cell.textLabel.text = NSLocalizedString(@"id_macID", nil);
                
                // Add colons to mac address
                if (self.device.sid && self.device.sid.length == 12) {
                    NSString *mac = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
                                     [_device.sid substringWithRange:NSMakeRange(0, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(2, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(4, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(6, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(8, 2)],
                                     [_device.sid substringWithRange:NSMakeRange(10, 2)]];
                    cell.detailTextLabel.text = mac;
                } else {
                    cell.detailTextLabel.text = self.device.sid;
                }
            } else {
                cell.textLabel.text = @"Notify on timer activated";
                if (self.device.notify_timer) {
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_check"]];
                }
            }
            break;
        case 8:
            if (_deviceInRange) {
                cell.textLabel.text = NSLocalizedString(@"lnk_removeAndReset", nil);
            }
            break;
        case 9:
            if (_deviceInRange) {
                cell.textLabel.text = NSLocalizedString(@"btn_ota", nil);
            } else {
                cell.textLabel.text = NSLocalizedString(@"lnk_removeAndReset", nil);
            }
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
    } else if (indexPath.row == 5) {
        if (!_deviceInRange) {
            if (self.device.notify_power) {
                self.device.notify_timer = 0;
            } else {
                self.device.notify_timer = 1;
            }
        }
    } else if (indexPath.row == 6) {
        if (!_deviceInRange) {
            if (self.device.notify_co) {
                self.device.notify_co = 0;
            } else {
                self.device.notify_co = 1;
            }
        }
    } else if (indexPath.row == 7) {
        if (!_deviceInRange) {
            if (self.device.notify_co) {
                self.device.notify_co = 0;
            } else {
                self.device.notify_co = 1;
            }
        }
    } else if (indexPath.row == 8) {
        if (_deviceInRange) {
            // Remove and reset
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:nil
                                                  message:NSLocalizedString(@"msg_removeAndResetBtn", nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* actionYes = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[SQLHelper getInstance] deletePlugDataByID:g_DeviceMac];
            }];
            [alertController addAction:actionYes];
            UIAlertAction* actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }];
            [alertController addAction:actionNo];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    } else if (indexPath.row == 9) {
        if (_deviceInRange) {
            // Update firmare
            [[UDPCommunication getInstance] sendOTACommand:g_DeviceIp];
            
            [self.view makeToast:NSLocalizedString(@"please_wait", nil)
                        duration:3.0
                        position:CSToastPositionCenter];
        } else {
            // Remove and reset
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:nil
                                                  message:NSLocalizedString(@"msg_removeAndResetBtn", nil)
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* actionYes = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[SQLHelper getInstance] deletePlugDataByID:g_DeviceMac];
            }];
            [alertController addAction:actionYes];
            UIAlertAction* actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }];
            [alertController addAction:actionNo];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    
    [self.tableView reloadData];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//==================================================================
#pragma DeviceIconDelegate
//==================================================================
- (void)selectedIcon:(NSString *)icon
{
    // Update device icon
    _device.icon = icon;
    [[SQLHelper getInstance] updatePlugIcon:_device.sid icon:icon];
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
        } else if ([resultName isEqualToString:WS_DEV_SET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                
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
