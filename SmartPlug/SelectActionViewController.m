//
//  SelectActionViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "SelectActionViewController.h"

@interface SelectActionViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SelectActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 75;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    view.backgroundColor = [UIColor whiteColor];
    
    if (section == 0) {
        UIImageView *imgIcon = [[UIImageView alloc] initWithFrame:CGRectMake(20, 12, 50, 50)];
        imgIcon.image = [UIImage imageNamed:@"see_Table Lamps_1_white_bkgnd"];
        [view addSubview:imgIcon];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(80, 12, tableView.frame.size.width-100, 50)];
        [label setFont:[UIFont systemFontOfSize:32]];
        [label setTextColor:[UIColor blackColor]];
        [label setText:@"Desk Lamp"];
        [label setTextAlignment:NSTextAlignmentLeft];
        [view addSubview:label];
    } else if (section == 1) {
        UIImageView *imgIcon = [[UIImageView alloc] initWithFrame:CGRectMake(20, 12, 50, 50)];
        imgIcon.image = [UIImage imageNamed:@"see_bedroom_1_white_bkgnd"];
        [view addSubview:imgIcon];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(80, 12, tableView.frame.size.width-100, 50)];
        [label setFont:[UIFont systemFontOfSize:32]];
        [label setTextColor:[UIColor blackColor]];
        [label setText:@"Bedroom"];
        [label setTextAlignment:NSTextAlignmentLeft];
        [view addSubview:label];
    }
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableViewCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    switch (indexPath.row) {
        case 0:
            cell.imageView.image = [UIImage imageNamed:@"svc_0_small"];
            cell.textLabel.text = @"Outlet";
            cell.textLabel.textColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_BLUE];
            break;
        case 1:
            cell.imageView.image = [UIImage imageNamed:@"svc_1_small"];
            cell.textLabel.text = @"Night Light";
            cell.textLabel.textColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_YELLOW];
            break;
        case 2:
            cell.imageView.image = [UIImage imageNamed:@"svc_2_small"];
            cell.textLabel.text = @"IR";
            cell.textLabel.textColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
            break;
        case 3:
            cell.imageView.image = [UIImage imageNamed:@"svc_3_small"];
            cell.textLabel.text = @"CO normal";
            cell.textLabel.textColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_RED];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *device;
    NSString *deviceIcon;
    NSString *type;
    NSString *typeIcon;
    
    if (indexPath.section == 0) {
        device = @"Desk Lamp";
        deviceIcon = @"see_Table Lamps_1_white_bkgnd";
    } else if (indexPath.section == 1) {
        device = @"Bedroom";
        deviceIcon = @"see_bedroom_1_white_bkgnd";
    }
    
    if (indexPath.row == 0) {
        type = @"Outlet";
        typeIcon = @"svc_0_small";
    } else if (indexPath.row == 1) {
        type = @"Night Light";
        typeIcon = @"svc_1_small";
    } else if (indexPath.row == 2) {
        type = @"IR";
        typeIcon = @"svc_2_small";
    } else if (indexPath.row == 3) {
        type = @"CO normal";
        typeIcon = @"svc_3_small";
    }
    
    JSAction *action = [JSAction new];
    action.device = device;
    action.deviceIcon = deviceIcon;
    action.type = type;
    action.typeIcon = typeIcon;
    [self.delegate didSelectAction:action];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
