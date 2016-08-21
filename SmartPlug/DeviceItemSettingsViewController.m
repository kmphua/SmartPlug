//
//  DeviceItemSettingsViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "DeviceItemSettingsViewController.h"
#import "DeviceIconViewController.h"
#import "FirstTimeConfig.h"
#import "UDPCommunication.h"
#import "UDPListenerService.h"
#import "MBProgressHUD.h"

#define ROW_DEVICE_TYPE             0
#define ROW_DEVICE_ICON             1
#define ROW_DEVICE_NAME             2
#define ROW_WIFI                    3
#define ROW_CO_SENSOR               4
#define ROW_HARDWARE                5
#define ROW_FIRMWARE                6
#define ROW_MAC_ADDRESS             7
#define ROW_CONFIG_MSG              8
#define ROW_UPDATE_FIRMWARE         9

#define OTA_TIMEOUT                 60

@interface DeviceItemSettingsViewController ()<DeviceIconDelegate>
{
    NSString *model;
    int buildnumber;
    int protocol;
    NSString *hardware;
    NSString *firmware;
    int firmwaredate;
    NSString *wifi;
    int notify_on_power_outage;
    int notify_on_co_warning;
    int notify_on_timer_activated;
    BOOL customIcon;
    BOOL isSave;
    BOOL isNameChanged;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) BOOL deviceInRange;
@property (nonatomic, strong) UITextField *txtName;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (nonatomic, strong) UIImage *pickerImage;

@end

@implementation DeviceItemSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    notify_on_power_outage = 0;
    notify_on_co_warning = 0;
    notify_on_timer_activated = 0;
    customIcon = false;
    isSave = false;
    isNameChanged = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    wifi = [FirstTimeConfig getSSID];
    
    if (g_DeviceIp && g_DeviceIp.length>0) {
        _deviceInRange = YES;

        // Add navigation buttons
        UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
        self.navigationItem.rightBarButtonItem = rightBarBtn;
    } else {
        _deviceInRange = NO;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaSent:) name:NOTIFICATION_OTA_SENT object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otaFinished:) name:NOTIFICATION_OTA_FINISHED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceInfo:) name:NOTIFICATION_DEVICE_INFO object:nil];
    
    short command = 0x0001;
    [[UDPCommunication getInstance] queryDevices:g_DeviceMac command:command];
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devGet:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution] devId:_device.sid];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_OTA_SENT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_OTA_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_DEVICE_INFO object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showWaitingIndicator {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.labelText = NSLocalizedString(@"processing_command", nil);
    [_hud show:YES];
}

- (void)dismissWaitingIndicator {
    [_hud hide:YES];
}

- (void)onRightBarButton:(id)sender {
    // Disable user interaction
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // Show waiting view
    [self showWaitingIndicator];
    
    /*
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
    */
    
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
            isSave = YES;
            
            if (!customIcon) {
                [ws devSet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac icon:iconId title:name notifyPower:[NSString stringWithFormat:@"%d", notify_on_power_outage] notifyTimer:[NSString stringWithFormat:@"%d", notify_on_timer_activated] notifyDanger:[NSString stringWithFormat:@"%d",notify_on_co_warning]];
            } else {
                [ws uploadImage:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac image:_pickerImage notifyPower:[NSString stringWithFormat:@"%d", notify_on_power_outage] notifyTimer:[NSString stringWithFormat:@"%d", notify_on_timer_activated] notifyDanger:[NSString stringWithFormat:@"%d",notify_on_co_warning]];
            }
            return;
        } else {
            NSLog(@"CHECK IF MAC ADDRESS IS NULL");
            self.navigationItem.rightBarButtonItem.enabled = YES;
            [self dismissWaitingIndicator];
        }
    }
     
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self dismissWaitingIndicator];
}

- (void)otaSent:(NSNotification *)notification {
    [self showWaitingIndicator];
}

- (void)otaFinished:(NSNotification *)notification {
    int count = 10;
    while(count > 0){
        count--;
        [NSThread sleepForTimeInterval:1000];
    }
    
    short command = 0x0001;
    [[UDPCommunication getInstance] queryDevices:g_DeviceMac command:command];
    [self dismissWaitingIndicator];
}

- (void)deviceInfo:(NSNotification *)notification {
    NSLog(@"DEVICE INFO BROADCAST RECEIVED");
    
    UDPListenerService *udp = [UDPListenerService getInstance];
    [[SQLHelper getInstance] updateDeviceVersions:g_DeviceMac
                                            model:udp.js.model
                                         build_no:udp.js.buildno
                                         prot_ver:udp.js.prot_ver
                                           hw_ver:udp.js.hw_ver
                                           fw_ver:udp.js.fw_ver
                                          fw_date:udp.js.fw_date];
    
    NSArray *plugs = [[SQLHelper getInstance] getPlugDataByID:g_DeviceMac];
    if (plugs && plugs.count > 0){
        JSmartPlug *plug = [plugs firstObject];
        model = plug.model;
        buildnumber = plug.buildno;
        protocol = plug.prot_ver;
        hardware = plug.hw_ver;
        firmware = plug.fw_ver;
        firmwaredate = plug.fw_date;
        
        [self.tableView reloadData];
        
        WebService *ws = [WebService new];
        ws.delegate = self;
        [ws devSet2:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac model:model buildNumber:buildnumber protocol:protocol hardware:hardware firmware:firmware firmwareDate:firmwaredate];
    }
}

- (void)otaTimeout:(id)sender {
    [self dismissWaitingIndicator];
    
    [self.view makeToast:NSLocalizedString(@"ota_error", nil)
                duration:3.0
                position:CSToastPositionCenter];
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
    return 60;
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
        case ROW_DEVICE_TYPE:
            cell.textLabel.text = NSLocalizedString(@"id_sevice", nil);
            if (model && model.length>0) {
                cell.detailTextLabel.text = self.device.model;
            } else {
                cell.detailTextLabel.text = @"JSPlug";
            }
            break;
        case ROW_DEVICE_ICON:
        {
            cell.textLabel.text = NSLocalizedString(@"id_icon", nil);
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 100, 7, 40, 40)];
            [imageView setBackgroundColor:[UIColor colorWithRed:134.0/255.0 green:211.0/255.0 blue:209.0/255.0 alpha:1.0]];
            
            NSString *imagePath = DEFAULT_ICON_PATH;
            if (self.device.icon && self.device.icon.length>0) {
                // Server icon
                imagePath = self.device.icon;
                [imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
            } else if (self.pickerImage) {
                // Selected image from picker
                [imageView setImage:self.pickerImage];
            } else {
                imagePath = DEFAULT_ICON_PATH;
                [imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
            }
            cell.accessoryView = imageView;
        }
            break;
        case ROW_DEVICE_NAME:
            cell.textLabel.text = NSLocalizedString(@"id_name", nil);
            
            if (!_txtName) {
                _txtName = [[UITextField alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-150, 5, 100, cell.contentView.frame.size.height)];
                _txtName.backgroundColor = [UIColor whiteColor];
                _txtName.borderStyle = UITextBorderStyleNone;
                _txtName.textAlignment = NSTextAlignmentRight;
                _txtName.placeholder = @"TV on/off";
                _txtName.font = [UIFont systemFontOfSize:18];
                _txtName.adjustsFontSizeToFitWidth = YES;
                [_txtName addTarget:self
                              action:@selector(textFieldDidChange:)
                    forControlEvents:UIControlEventEditingChanged];
            }
            
            if (!isNameChanged) {
                if (_device.givenName && _device.givenName.length > 0) {
                    _txtName.text = _device.givenName;
                } else {
                    _txtName.text = _device.name;
                }
            }
            cell.accessoryView = _txtName;
            break;
        case ROW_WIFI:
            cell.textLabel.text = NSLocalizedString(@"id_wifi", nil);
            if (wifi && wifi.length > 0) {
                cell.detailTextLabel.text = wifi;
            } else {
                //cell.detailTextLabel.text = NSLocalizedString(@"connect_to_wifi", nil);
            }
            break;
        case ROW_CO_SENSOR:
            cell.textLabel.text = NSLocalizedString(@"id_cosensor", nil);
            if (g_DeviceIp && g_DeviceIp.length>0 && self.device.co_sensor) {
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_check"]];
            }
            break;
        case ROW_HARDWARE:
            cell.textLabel.text = NSLocalizedString(@"id_hardware", nil);
            if (hardware && hardware.length > 0) {
                cell.detailTextLabel.text = hardware;
            }
            break;
        case ROW_FIRMWARE:
            cell.textLabel.text = NSLocalizedString(@"id_firmware", nil);
            if (firmware && firmware.length > 0) {
                cell.detailTextLabel.text = firmware;
            }
            break;
        case ROW_MAC_ADDRESS:
            cell.textLabel.text = NSLocalizedString(@"id_macID", nil);
            
            // Add colons to mac address
            if (self.device.sid && self.device.sid.length == 12) {
                NSString *macAddString = [_device.sid uppercaseString];
                NSString *mac = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
                                 [macAddString substringWithRange:NSMakeRange(0, 2)],
                                 [macAddString substringWithRange:NSMakeRange(2, 2)],
                                 [macAddString substringWithRange:NSMakeRange(4, 2)],
                                 [macAddString substringWithRange:NSMakeRange(6, 2)],
                                 [macAddString substringWithRange:NSMakeRange(8, 2)],
                                 [macAddString substringWithRange:NSMakeRange(10, 2)]];
                cell.detailTextLabel.text = mac;
            } else {
                cell.detailTextLabel.text = self.device.sid;
            }
            break;
        case ROW_CONFIG_MSG:
            cell.textLabel.text = NSLocalizedString(@"msg_deskLampBtn", nil);
            cell.textLabel.numberOfLines = 0;
            break;
        case ROW_UPDATE_FIRMWARE:{
            NSAttributedString* attribStrBtnOta = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"btn_ota", nil) attributes:@{NSForegroundColorAttributeName:[Global colorWithType:COLOR_TYPE_LINK],NSFontAttributeName:[UIFont systemFontOfSize:18], NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];
            cell.textLabel.attributedText = attribStrBtnOta;
        }
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == ROW_DEVICE_ICON) {
        // Get device icons
        DeviceIconViewController *iconVC = [[DeviceIconViewController alloc] initWithNibName:@"DeviceIconViewController" bundle:nil];
        iconVC.delegate = self;
        [self.navigationController pushViewController:iconVC animated:YES];
    } else if (indexPath.row == ROW_CONFIG_MSG) {
        // Remove and reset
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:nil
                                              message:NSLocalizedString(@"msg_removeAndResetBtn", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* actionYes = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[SQLHelper getInstance] deletePlugData:g_DeviceMac];
        }];
        [alertController addAction:actionYes];
        UIAlertAction* actionNo = [UIAlertAction actionWithTitle:NSLocalizedString(@"btn_no", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        [alertController addAction:actionNo];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if (indexPath.row == ROW_UPDATE_FIRMWARE) {
        // Update firmare
        if (g_DeviceIp && g_DeviceIp.length>0) {
            if ([Global isNetworkReady]) {
                [[UDPCommunication getInstance] sendOTACommand:g_DeviceMac];
                [self showWaitingIndicator];
                
                // Start timeout timer
                [NSTimer scheduledTimerWithTimeInterval:OTA_TIMEOUT
                                                 target:self
                                               selector:@selector(otaTimeout:)
                                               userInfo:nil
                                                repeats:NO];
            } else {
                [self.view makeToast:NSLocalizedString(@"no_udp_Connection", nil)
                            duration:3.0
                            position:CSToastPositionBottom];
            }
        } else {
            [self.view makeToast:NSLocalizedString(@"ip_not_found", nil)
                        duration:3.0
                        position:CSToastPositionBottom];

        }
    }
    
    [self.tableView reloadData];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//==================================================================
#pragma UITextFieldDelegate
//==================================================================
- (void)textFieldDidChange:(id)sender
{
    isNameChanged = true;
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
    customIcon = false;
}

- (void)selectedImage:(UIImage *)image
{
    // Update device icon with picker image
    _device.icon = nil;
    _pickerImage = [image copy];
    [self.tableView reloadData];
    customIcon = true;
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
        
        if ([resultName isEqualToString:WS_DEV_SET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSLog(@"DB UPDATED SUCCESSFULLY");
                self.navigationItem.rightBarButtonItem.enabled = YES;
                [self dismissWaitingIndicator];
                
                if (isSave) {
                    [self.navigationController popViewControllerAnimated:YES];
                    isSave = false;
                }
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
        } else if ([resultName compare:WS_DEV_GET] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                hardware = [jsonObject objectForKey:@"hardware"];
                firmware = [jsonObject objectForKey:@"firmware"];
                [self.tableView reloadData];
            } else {
                // Failure
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName  webservice:(WebService *)ws{
    NSLog(@"Connect fail for %@", resultName);
}

@end
