//
//  IRCodeModeViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRCodeModeViewController.h"
#import "IREditModeViewController.h"
#import "GMGridView.h"

#import "IRRecordViewController.h"
#import "IRCustomViewController.h"
#import "UDPCommunication.h"

@interface IRCodeModeViewController()<GMGridViewDataSource, GMGridViewActionDelegate>
{
    int _codeId;
}

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet GMGridView *gmGridView;
@property (nonatomic, strong) NSArray *codes;
@property (nonatomic, strong) IrGroup *group;
@property (nonatomic) BOOL isEditMode;
@property (strong, nonatomic) UIButton *btnAddNew;
@property (strong, nonatomic) UIBarButtonItem *rightBarBtn;

@end

@implementation IRCodeModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    _group = [[SQLHelper getInstance] getIRGroupBySID:_groupId];
    if (_group) {
        self.lblTitle.text = _group.name;
    }
    
    // Add navigation buttons
    self.rightBarBtn = [[UIBarButtonItem alloc]
                                    initWithImage:[UIImage imageNamed:@"ic_edit"]
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = self.rightBarBtn;
    
    // Setup grid view
    self.gmGridView.clipsToBounds = YES;
    self.gmGridView.centerGrid = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrGet:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE iconRes:[Global getIconResolution]];

    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePush:) name:NOTIFICATION_PUSH object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
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
    if (g_DeviceIp) {
        IRCustomViewController *irCustomVC = [[IRCustomViewController alloc] initWithNibName:@"IRCustomViewController" bundle:nil];
        irCustomVC.groupId = _groupId;
        [self.navigationController pushViewController:irCustomVC animated:YES];
    } else {
        [self.view makeToast:NSLocalizedString(@"msg_deskLampBtn", nil)
                    duration:3.0
                    position:CSToastPositionBottom];
    }
}

- (void)updateView
{
    _codes = [[SQLHelper getInstance] getIRCodesByGroup:_groupId];
    [_gmGridView reloadData];
    if (self.codes.count > 0) {
        self.navigationItem.rightBarButtonItem = _rightBarBtn;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [_codes count]+1;
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return CGSizeMake(120, 120);
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
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
        IrCode *code = [_codes objectAtIndex:index-1];
        
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
        btnIr.tag = code.code_id;
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        //__weak IRCodeModeViewController *weakself = self;
        
        NSString *icon = @"http://rgbetanco.com/jiEE/icons/btn_power_pressed.png";
        if (code.icon && code.icon.length>0) {
            icon = code.icon;
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
        lblIr.text = code.name;
        lblIr.font = [UIFont systemFontOfSize:15];
        lblIr.textAlignment = NSTextAlignmentCenter;
        lblIr.adjustsFontSizeToFitWidth = YES;
        [viewIr addSubview:lblIr];
        
        if (_isEditMode) {
            UIButton *btnDelete = [[UIButton alloc] initWithFrame:CGRectMake(90, 0, 30, 30)];
            [btnDelete setBackgroundImage:[UIImage imageNamed:@"btn_warn_close"] forState:UIControlStateNormal];
            [btnDelete addTarget:self action:@selector(onBtnDelete:) forControlEvents:UIControlEventTouchUpInside];
            btnDelete.tag = code.sid;
            [viewIr addSubview:btnDelete];
        }
        
        cell.contentView = viewIr;
    }
    
    return cell;
}

- (void)onBtnIr:(id)sender {
    UIButton *btnIr = (UIButton *)sender;
    int codeId = (int)btnIr.tag;
    
    for (IrCode *code in _codes) {
        if (code.code_id == codeId) {
            [self setDeviceStatus:g_DeviceMac serviceId:IR_SERVICE action:code.filename];
            //[[UDPCommunication getInstance] sendIRFileName:g_DeviceMac filename:code.filename];
            NSLog(@"Sending IR filename %d", code.filename);
            
            [self.view makeToast:NSLocalizedString(@"processing_ir_command", nil)
                        duration:1.0
                        position:CSToastPositionBottom];
            
            break;
        }
    }
}

- (void)onBtnDelete:(id)sender {
    UIButton *btnDelete = (UIButton *)sender;
    _codeId = (int)btnDelete.tag;
    
    int groupId = 0;
    IrGroup *irGroup = [[SQLHelper getInstance] getIRGroupBySID:_groupId];
    if (irGroup) {
        groupId = irGroup.sid;
    }
    int iconId = 0;
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrSetButtons:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE action:IR_SET_DELETE groupId:groupId buttonId:_codeId name:@"" icon:iconId code:0 iconRes:[Global getIconResolution]];
}

- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return NO;
}

- (void)setDeviceStatus:(NSString *)devId serviceId:(int)serviceId action:(uint8_t)action
{
    int header = 0x534D5254;
    uint8_t sMsg[24];
    sMsg[3] = (uint8_t)(header);
    sMsg[2] = (uint8_t)((header >> 8 ));
    sMsg[1] = (uint8_t)((header >> 16 ));
    sMsg[0] = (uint8_t)((header >> 24 ));
    
    int msid = (int)(random()*4294967+1);
    sMsg[7] = (uint8_t)(msid);
    sMsg[6] = (uint8_t)((msid >> 8 ));
    sMsg[5] = (uint8_t)((msid >> 16 ));
    sMsg[4] = (uint8_t)((msid >> 24 ));
    int seq = 0x80000000;
    sMsg[11] = (uint8_t)(seq);
    sMsg[10] = (uint8_t)((seq >> 8 ));
    sMsg[9] = (uint8_t)((seq >> 16 ));
    sMsg[8] = (uint8_t)((seq >> 24 ));
    short command = 0x0008;
    sMsg[13] = (uint8_t)(command);
    sMsg[12] = (uint8_t)((command >> 8 ));
    //int serviceId = 0xD1000000;
    sMsg[17] = (uint8_t)(serviceId);
    sMsg[16] = (uint8_t)((serviceId >> 8 ));
    sMsg[15] = (uint8_t)((serviceId >> 16 ));
    sMsg[14] = (uint8_t)((serviceId >> 24 ));
    
    uint8_t datatype = 0x01;
    sMsg[18] = datatype;
    uint8_t data = action;
    sMsg[19] = data;
    int terminator = 0x00000000;
    sMsg[23] = (uint8_t)(terminator & 0xff);
    sMsg[22] = (uint8_t)((terminator >> 8 ) & 0xff);
    sMsg[21] = (uint8_t)((terminator >> 16 ) & 0xff);
    sMsg[20] = (uint8_t)((terminator >> 24 ) & 0xff);
    
    NSLog(@"Data length = %ld", sizeof(sMsg));
    
    NSData *deviceData = [NSData dataWithBytes:sMsg length:sizeof(sMsg)];
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devCtrl:g_UserToken lang:[Global getCurrentLang] devId:devId send:0 data:deviceData];
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    IrCode *code = [_codes objectAtIndex:position-1];
    [[UDPCommunication getInstance] sendIRFileName:g_DeviceMac filename:code.filename];
    NSLog(@"Sending IR filename %d", code.filename);
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
        
        if ([resultName compare:WS_DEV_CTRL] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSLog(@"Set device status success");
            } else {
                // Failure
                NSLog(@"Set device status failed");
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
        } else if ([resultName isEqualToString:WS_DEV_IR_GET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                [[SQLHelper getInstance] deleteIRGroups];
                
                NSArray *groups = (NSArray *)[jsonObject objectForKey:@"groups"];
                if (groups) {
                    NSLog(@"Total %ld groups", (unsigned long)groups.count);
                    
                    for (NSDictionary *group in groups) {
                        int groupId = [[group objectForKey:@"id"] intValue];
                        //NSString *title = [group objectForKey:@"title"];
                        //NSString *icon = [group objectForKey:@"icon"];
                        
                        [[SQLHelper getInstance] updateIRCodeSID:_codeId sid:groupId];
                        
                        //[[SQLHelper getInstance] deleteIRGroupBySID:groupId];
                        //[[SQLHelper getInstance] deleteIRCodes:groupId];
                        //[[SQLHelper getInstance] insertIRGroup:title icon:icon position:0 sid:groupId];
                        
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
        }
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}


@end
