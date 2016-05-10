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
#import "IREditItemViewController.h"
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
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrGet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE iconRes:[Global getIconResolution]];

    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePush:) name:NOTIFICATION_PUSH object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PUSH object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handlePush:(NSNotification *)notification {
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrGet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE iconRes:[Global getIconResolution]];
}

- (void)updateView
{
    self.irGroups = [[SQLHelper getInstance] getIRGroups];
    [_gmGridView reloadData];
    if (self.irGroups.count > 0) {
        self.navigationItem.rightBarButtonItem = _rightBarBtn;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
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
    IREditItemViewController *irEditItemVC = [[IREditItemViewController alloc] initWithNibName:@"IREditItemViewController" bundle:nil];
    [self.navigationController pushViewController:irEditItemVC animated:YES];

    /*
    IRAddNewViewController *irAddNewVC = [[IRAddNewViewController alloc] initWithNibName:@"IRAddNewViewController" bundle:nil];
    [self.navigationController pushViewController:irAddNewVC animated:YES];
     */
}

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
        
        cell.layer.masksToBounds = NO;
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
        btnIr.tag = group.sid;
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        //__weak IRCodeModeViewController *weakself = self;
        
        NSString *icon = @"http://rgbetanco.com/jiEE/icons/btn_power_pressed.png";
        if (group.icon && group.icon.length>0) {
            icon = group.icon;
        }
        [manager downloadImageWithURL:[NSURL URLWithString:icon]
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
            btnDelete.tag = group.sid;
            [viewIr addSubview:btnDelete];
        }
        
        cell.contentView = viewIr;
    }
    
    return cell;
}

- (void)onBtnIr:(id)sender {
    UIButton *btnIr = (UIButton *)sender;
    int groupId = (int)btnIr.tag;

    if (g_DeviceIp) {
        IRCodeModeViewController *irCodeModeVC = [[IRCodeModeViewController alloc] initWithNibName:@"IRCodeModeViewController" bundle:nil];
        irCodeModeVC.groupId = groupId;
        [self.navigationController pushViewController:irCodeModeVC animated:YES];
    } else {
        NSLog(@"NO DEVICE IP!!!");
    }
}

- (void)onBtnDelete:(id)sender {
    UIButton *btnDelete = (UIButton *)sender;
    int groupId = (int)btnDelete.tag;
    
    int newIndex = 0;
    NSString *groupName = @"";
    NSString *iconId = @"";
    NSArray *groups = [[SQLHelper getInstance] getIRGroup:groupId];
    if (groups && groups.count>0) {
        IrGroup *group = groups.firstObject;
        newIndex = group.sid;
        groupName = group.name;
        iconId = group.icon;
    }
    
    if ([[SQLHelper getInstance] deleteIRGroupById:groupId]){
        NSLog(@"Successfully deleted");
    }
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrSetGroup:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE action:IR_SET_DELETE groupId:newIndex name:groupName icon:[iconId intValue] iconRes:[Global getIconResolution]];
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
        
        if ([resultName isEqualToString:WS_DEV_IR_GET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                [[SQLHelper getInstance] deleteIRGroups];

                // Success
                NSArray *groups = (NSArray *)[jsonObject objectForKey:@"groups"];
                if (groups) {
                    NSLog(@"Total %ld groups", (unsigned long)groups.count);
                    
                    for (NSDictionary *group in groups) {
                        int groupId = [[group objectForKey:@"id"] intValue];
                        NSString *title = [group objectForKey:@"title"];
                        NSString *icon = [group objectForKey:@"icon"];
                        
                        [[SQLHelper getInstance] deleteIRGroupBySID:groupId];
                        [[SQLHelper getInstance] deleteIRCodes:groupId];
                        [[SQLHelper getInstance] insertIRGroup:title icon:icon position:0 sid:groupId];
                        
                        NSArray *buttons = (NSArray *)[group objectForKey:@"buttons"];
                        for (NSDictionary *button in buttons) {
                            int sid = [[button objectForKey:@"id"] intValue];
                            NSString *title = [button objectForKey:@"title"];
                            NSString *icon = [button objectForKey:@"icon"];
                            int code = [[button objectForKey:@"code"] intValue];
                            
                            [[SQLHelper getInstance] insertIRCodes:groupId name:title filename:code icon:icon mac:g_DeviceMac sid:sid];
                        }
                    }
                    
                    [self updateView];
                }
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
        } else if ([resultName isEqualToString:WS_DEV_IR_SET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSLog(@"IR set success");
                
                WebService *ws = [WebService new];
                ws.delegate = self;
                [ws devIrGet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE iconRes:[Global getIconResolution]];
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
