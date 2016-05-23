//
//  IREditItemViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IREditItemViewController.h"
#import "IREditModeViewController.h"
#import "DeviceIconViewController.h"
#import "IRRecordViewController.h"

#define FILE_PATH       @"http://rgbetanco.com/jiEE/icons/btn_power_pressed.png"

@interface IREditItemViewController ()<DeviceIconDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UITextField *txtName;
@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) NSString *icon;

@end

@implementation IREditItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc]
                                    initWithTitle:NSLocalizedString(@"btn_done", nil)
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onRightBarButton:(id)sender {
    // Save IR group
    if (!_txtName.text || _txtName.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"NameEmptyMsg", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    int iconId = 0;
    NSArray *icons = [[SQLHelper getInstance] getIconByUrl:_icon];
    if (icons && icons.count>0) {
        Icon *icon = icons.firstObject;
        iconId = [icon.sid intValue];
    }
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrSetGroup:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE action:IR_SET_ADD groupId:0 name:_txtName.text icon:iconId iconRes:[Global getIconResolution]];
}

//==================================================================
#pragma DeviceIconDelegate
//==================================================================
- (void)selectedIcon:(NSString *)icon
{
    // Update device icon
    _icon = icon;
    [self.tableView reloadData];
}

- (void)selectedImage:(UIImage *)image
{
    // Update device icon with picker image
    
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
    return 2;
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
    [label setText:NSLocalizedString(@"title_editCommand", nil)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:label];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"title_title", nil);
        
        if (!_txtName) {
            _txtName = [[UITextField alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-70, 5, 100, cell.contentView.frame.size.height)];
            _txtName.backgroundColor = [UIColor whiteColor];
            _txtName.borderStyle = UITextBorderStyleNone;
            _txtName.textAlignment = NSTextAlignmentRight;
            _txtName.delegate = self;
            _txtName.placeholder = @"TV on/off";
            _txtName.font = [UIFont systemFontOfSize:18];
        }
        [cell.contentView addSubview:_txtName];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"id_icon", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Add icon
        if (!_iconImageView) {
            _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 20, 7, 40, 40)];
            [_iconImageView setBackgroundColor:[Global colorWithType:COLOR_TYPE_ICON_BG]];
            [cell addSubview:_iconImageView];
        }
        
        NSString *imagePath = DEFAULT_IR_ICON_PATH;
        if (_icon && _icon.length>0) {
            imagePath = _icon;
        }
        [_iconImageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
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
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
        
        if ([resultName isEqualToString:WS_DEV_IR_SET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSLog(@"IR set success");
                
                int sid = [[jsonObject objectForKey:@"id"] intValue];
                int groupId = [[jsonObject objectForKey:@"groupid"] intValue];
                [[SQLHelper getInstance] updateIRGroupID:groupId sid:sid];
                
                [self.navigationController popViewControllerAnimated:YES];
                [self.delegate onAddedIRGroup];
            } else {
                // Failure
                NSLog(@"IR set failed");
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}


@end
