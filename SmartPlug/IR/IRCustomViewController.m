//
//  IRCustomViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRCustomViewController.h"
#import "IRRecordViewController.h"
#import "DeviceIconViewController.h"
#import "DQAlertView.h"

@interface IRCustomViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UITextField *txtName;
@property (nonatomic, strong) UIImageView *iconImageView;

@end

@implementation IRCustomViewController

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
    NSString *irGroupName = (_txtName && _txtName.text.length>0) ? _txtName.text : @"TV on/off";
    [[SQLHelper getInstance] insertIRGroup:irGroupName icon:0 position:0];
    
    IRRecordViewController *irRecordVC = [[IRRecordViewController alloc] initWithNibName:@"IRRecordViewController" bundle:nil];
    [self.navigationController pushViewController:irRecordVC animated:YES];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"title_title", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Add title
        UILabel *lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width - 90, 7, 100, 40)];
        if (_txtName && _txtName.text) {
            cell.detailTextLabel.text = _txtName.text;
        } else {
            cell.detailTextLabel.text = @"TV on/off";
        }
        [cell addSubview:lblTitle];
        
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"id_icon", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Add icon
        if (!_iconImageView) {
            _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 20, 7, 40, 40)];
            [cell addSubview:_iconImageView];
        }
        _iconImageView.image = [UIImage imageNamed:@"btn_power_pressed"];
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
    } else if (indexPath.row == 0) {
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
        //txtName.text = (_device.givenName && _device.givenName.length>0) ? _device.givenName : _device.name;
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
            //[[SQLHelper getInstance] updatePlugName:_txtName.text sid:_device.sid];
            //_device.givenName = _txtName.text;
            [self.tableView reloadData];
        };
        [alertView show];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
