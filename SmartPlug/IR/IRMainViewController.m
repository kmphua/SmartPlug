//
//  IRMainViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/18/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "IRMainViewController.h"
#import "DeviceItemSettingsViewController.h"
#import "IRAddNewViewController.h"
#import "IrGroupViewCell.h"
#import "IREditModeViewController.h"

@interface IRMainViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *irGroups;

@end

@implementation IRMainViewController

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
    
    self.irGroups = [[SQLHelper getInstance] getIRGroups];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onBtnAddNew:(id)sender {
    IRAddNewViewController *irAddNewVC = [[IRAddNewViewController alloc] initWithNibName:@"IRAddNewViewController" bundle:nil];
    [self.navigationController pushViewController:irAddNewVC animated:YES];
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
    if (_irGroups) {
        return _irGroups.count+1;
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 75;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [view setBackgroundColor:[Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [label setFont:[UIFont systemFontOfSize:32]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:NSLocalizedString(@"title_irControl", nil)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:label];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        // Add new ir group
        static NSString *CellIdentifier = @"TableViewCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        UIButton *btnAddNew = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width/2, 8, 56, 56)];
        [btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add.png"] forState:UIControlStateNormal];
        [btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add_pressed.png"] forState:UIControlStateSelected];
        [btnAddNew addTarget:self action:@selector(onBtnAddNew:) forControlEvents:UIControlEventTouchUpInside];

        [cell addSubview:btnAddNew];
        return cell;
        
    } else {
        static NSString *CellIdentifier = @"IrGroupViewCell";
        IrGroupViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:@"IrGroupViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        }
        
        IrGroup *irGroup = [self.irGroups objectAtIndex:[indexPath row]-1];
        cell.lblDeviceName.text = irGroup.name;
        
        if (irGroup.icon && irGroup.icon.length>0) {
            int iconId = [irGroup.icon intValue];
            if (g_DeviceIcons) {
                NSDictionary *icon = [g_DeviceIcons objectAtIndex:iconId-1];
                NSString *imagePath = [icon objectForKey:@"url"];
                [cell.imgDeviceIcon sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:nil];
            }
        }
        
        // Modify cell background according to row position
        NSInteger rowCount = [self.irGroups count];
        NSInteger row = indexPath.row-1;
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        IRAddNewViewController *irAddNewVC = [[IRAddNewViewController alloc] initWithNibName:@"IRAddNewViewController" bundle:nil];
        [self.navigationController pushViewController:irAddNewVC animated:YES];
    } else {
        IREditModeViewController *irEditModeVC = [[IREditModeViewController alloc] initWithNibName:@"IREditModeViewController" bundle:nil];
        irEditModeVC.irGroup = (IrGroup *)[self.irGroups objectAtIndex:[indexPath row]-1];
        [self.navigationController pushViewController:irEditModeVC animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



@end
