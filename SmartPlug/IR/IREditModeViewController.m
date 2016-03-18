//
//  IREditModeViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/3/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IREditModeViewController.h"
#import "IRMainViewController.h"
#import "DeviceItemSettingsViewController.h"
#import "IRAddNewViewController.h"
#import "IRCodeModeViewController.h"
#import "GMGridView.h"

@interface IREditModeViewController ()<GMGridViewDataSource, GMGridViewActionDelegate>

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet GMGridView *gmGridView;
@property (strong, nonatomic) NSArray *irGroups;
@property (nonatomic) BOOL isEditMode;
@property (strong, nonatomic) UIButton *btnAddNew;
@property (strong, nonatomic) UIBarButtonItem *rightBarBtn;

@end

@implementation IREditModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"title_editCommand", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    // Add navigation buttons
    self.rightBarBtn = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"ic_edit"]
                        style:UIBarButtonItemStylePlain
                        target:self
                        action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = self.rightBarBtn;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.irGroups = [[SQLHelper getInstance] getIRGroups];
    [_gmGridView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onRightBarButton:(id)sender {
    if (_isEditMode) {
        _isEditMode = NO;
        [_rightBarBtn setImage:[UIImage imageNamed:@"ic_edit"]];
    } else {
        _isEditMode = YES;
        [_rightBarBtn setImage:[UIImage imageNamed:@"ic_edit_pressed"]];
    }
    [_gmGridView reloadData];
}

- (void)onBtnAddNew:(id)sender {
    IRAddNewViewController *irAddNewVC = [[IRAddNewViewController alloc] initWithNibName:@"IRAddNewViewController" bundle:nil];
    [self.navigationController pushViewController:irAddNewVC animated:YES];
}

/*
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
        
        if (!_btnAddNew) {
            _btnAddNew = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width/2, 8, 56, 56)];
            [_btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add.png"] forState:UIControlStateNormal];
            [_btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add_pressed.png"] forState:UIControlStateSelected];
            [_btnAddNew addTarget:self action:@selector(onBtnAddNew:) forControlEvents:UIControlEventTouchUpInside];            
            [cell addSubview:_btnAddNew];
        }
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
        cell.delegate = self;
        
        if (irGroup.icon && irGroup.icon.length>0) {
            int iconId = [irGroup.icon intValue];
            if (g_DeviceIcons) {
                NSDictionary *icon = [g_DeviceIcons objectAtIndex:iconId];
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
        IRCodeModeViewController *irCodeModeVC = [[IRCodeModeViewController alloc] initWithNibName:@"IRCodeModeViewController" bundle:nil];
        
        IrGroup *irGroup = [self.irGroups objectAtIndex:[indexPath row]-1];
        irCodeModeVC.groupId = irGroup.group_id;
        [self.navigationController pushViewController:irCodeModeVC animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
 */

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [_irGroups count]+1;
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return CGSizeMake(120, 120);
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    //CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    if (!cell) {
        cell = [[GMGridViewCell alloc] init];
    }
    
    if (index == 0) {
        _btnAddNew = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width/2, 8, 56, 56)];
        [_btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add.png"] forState:UIControlStateNormal];
        [_btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add_pressed.png"] forState:UIControlStateSelected];
        [_btnAddNew addTarget:self action:@selector(onBtnAddNew:) forControlEvents:UIControlEventTouchUpInside];
        cell.contentView = _btnAddNew;
    } else {
        IrGroup *group = [_irGroups objectAtIndex:index-1];
        
        // Create ir button
        UIView *viewIr = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
        viewIr.layer.cornerRadius = 10;
        [viewIr setUserInteractionEnabled:YES];
        
        // Modify cell background according to row position
        int row = (index-1) % 4;
        switch (row) {
            case 0:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_RED];
                break;
            case 1:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
                break;
            case 2:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_YELLOW];
                break;
            case 3:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_BLUE];
                break;
            default:
                break;
        }
        
        UIButton *btnIr = [[UIButton alloc] initWithFrame:CGRectMake(25, 25, 70, 70)];
        btnIr.tag = group.group_id;
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        //__weak IRCodeModeViewController *weakself = self;
        [manager downloadImageWithURL:[NSURL URLWithString:group.icon]
                              options:0
                             progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                 // progression tracking code
                                 NSLog(@"Received image %ld of %ld bytes", receivedSize, expectedSize);
                             }
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                if (image) {
                                    NSLog(@"Received image width=%.1f, height=%.lf", image.size.width, image.size.height);
                                    [btnIr setBackgroundImage:image forState:UIControlStateNormal];
                                }
                            }];
        
        [btnIr addTarget:self action:@selector(onBtnIr:) forControlEvents:UIControlEventTouchUpInside];
        [viewIr addSubview:btnIr];
        
        UILabel *lblIr = [[UILabel alloc] initWithFrame:CGRectMake(0, 98, 120, 20)];
        lblIr.textColor = [UIColor whiteColor];
        lblIr.text = group.name;
        lblIr.font = [UIFont systemFontOfSize:15];
        lblIr.textAlignment = NSTextAlignmentCenter;
        lblIr.adjustsFontSizeToFitWidth = YES;
        [viewIr addSubview:lblIr];
        
        if (_isEditMode) {
            UIButton *btnDelete = [[UIButton alloc] initWithFrame:CGRectMake(90, 0, 30, 30)];
            [btnDelete setBackgroundImage:[UIImage imageNamed:@"btn_warn_close"] forState:UIControlStateNormal];
            [btnDelete addTarget:self action:@selector(onBtnDelete:) forControlEvents:UIControlEventTouchUpInside];
            btnDelete.tag = group.group_id;
            [viewIr addSubview:btnDelete];
        }
        
        cell.contentView = viewIr;
    }
    
    return cell;
}

- (void)onBtnIr:(id)sender {
    UIButton *btnIr = (UIButton *)sender;
    int groupId = (int)btnIr.tag;

    IRCodeModeViewController *irCodeModeVC = [[IRCodeModeViewController alloc] initWithNibName:@"IRCodeModeViewController" bundle:nil];
    irCodeModeVC.groupId = groupId;
    [self.navigationController pushViewController:irCodeModeVC animated:YES];
}

- (void)onBtnDelete:(id)sender {
    UIButton *btnDelete = (UIButton *)sender;
    int groupId = (int)btnDelete.tag;
    
    if ([[SQLHelper getInstance] deleteIRGroupById:groupId]){
        NSLog(@"Successfully deleted");
    }
    
    self.irGroups = [[SQLHelper getInstance] getIRGroups];
    [_gmGridView reloadData];
}

- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return NO;
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    //IrGroup *group = [_irGroups objectAtIndex:position];
    //[[UDPCommunication getInstance] sendIRFileName:code.filename];
    //NSLog(@"Sending IR filename %d", code.filename);
}

- (void)GMGridViewDidTapOnEmptySpace:(GMGridView *)gridView
{
    NSLog(@"Tap on empty space");
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Are you sure you want to delete this item?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    
    [alert show];
    
    //_lastDeleteItemIndexAsked = index;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        //[_currentData removeObjectAtIndex:_lastDeleteItemIndexAsked];
        //[_gmGridView removeObjectAtIndex:_lastDeleteItemIndexAsked withAnimation:GMGridViewItemAnimationFade];
    }
}

@end
