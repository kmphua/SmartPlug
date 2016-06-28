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

#define FILE_PATH   @"http://rgbetanco.com/jiEE/icons/btn_power_pressed.png"

@interface IRCustomViewController()<UITextFieldDelegate, DeviceIconDelegate, IRRecordDelegate>
{
    BOOL customIcon;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UITextField *txtName;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImage *pickerImage;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation IRCustomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    customIcon = false;
    
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
    
    IRRecordViewController *irRecordVC = [[IRRecordViewController alloc] initWithNibName:@"IRRecordViewController" bundle:nil];
    irRecordVC.name = _txtName.text;
    irRecordVC.groupId = _groupId;
    irRecordVC.icon = _filePath;
    irRecordVC.delegate = self;
    irRecordVC.customIcon = _pickerImage;
    irRecordVC.isCustomIcon = customIcon;
    [self.navigationController pushViewController:irRecordVC animated:YES];
}

//==================================================================
#pragma mark - DeviceIconDelegate
//==================================================================

- (void)selectedIcon:(NSString *)icon
{
    // Update group icon
    _filePath = icon;
    [self.tableView reloadData];
    customIcon = false;
}

- (void)selectedImage:(UIImage *)image
{
    // Update device icon with picker image
    _pickerImage = [image copy];
    [self.tableView reloadData];
    customIcon = true;
}

//==================================================================
#pragma mark - IRRecordDelegate
//==================================================================

- (void)onSaveIRRecord
{
    [self.navigationController popViewControllerAnimated:YES];
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
    [label setText:NSLocalizedString(@"title_customCommand", nil)];
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
            _txtName = [[UITextField alloc] initWithFrame:CGRectMake(100, 5, tableView.frame.size.width-110, cell.contentView.frame.size.height)];
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
            _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 80, 7, 40, 40)];
            [_iconImageView setBackgroundColor:[Global colorWithType:COLOR_TYPE_ICON_BG]];
            [cell addSubview:_iconImageView];
        }
        
        NSString *imagePath = DEFAULT_IR_ICON_PATH;
        if (_filePath && _filePath.length>0 && !customIcon) {
            imagePath = _filePath;
            [_iconImageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
        } else if (self.pickerImage) {
            [_iconImageView setImage:self.pickerImage];
        } else {
            imagePath = DEFAULT_IR_ICON_PATH;
            [_iconImageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
        }
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

@end
