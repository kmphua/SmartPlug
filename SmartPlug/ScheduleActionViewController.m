//
//  ScheduleActionViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "ScheduleActionViewController.h"
#import "SelectActionViewController.h"
#import "MultiSelectSegmentedControl.h"
#import "IRListCommandsViewController.h"
#import "UDPCommunication.h"

@interface ScheduleActionViewController () <MultiSelectSegmentedControlDelegate, SelectActionDelegate, IRListCommandsDelegate>
{
    int init_hour;
    int end_hour;
    int init_minute;
    int end_minute;
    int dow;
    NSString *init_ir_name;
    NSString *end_ir_name;
    int init_ir_code;
    int end_ir_code;
}

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblDaysOfWeek;
@property (weak, nonatomic) IBOutlet MultiSelectSegmentedControl *segCtrlDaysOfWeek;
@property (weak, nonatomic) IBOutlet UILabel *lblTimeEachDay;
@property (weak, nonatomic) IBOutlet UILabel *lblAction;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectAction;
@property (weak, nonatomic) IBOutlet UIDatePicker *pickerFromTime;
@property (weak, nonatomic) IBOutlet UIDatePicker *pickerToTime;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UIImageView *imgDeviceIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgDeviceAction;
@property (weak, nonatomic) IBOutlet UIButton *btnInitIR;
@property (weak, nonatomic) IBOutlet UIButton *btnEndIR;

@property (assign, nonatomic) BOOL deviceStatusChangedFlag;
@property (assign, nonatomic) BOOL udpConnection;

@end

@implementation ScheduleActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _deviceStatusChangedFlag = false;
    _udpConnection = false;
    init_ir_code = -1;
    end_ir_code = -1;

    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"title_scheduleAction", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_RED];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    self.lblDaysOfWeek.text = NSLocalizedString(@"msg_daysofWeek", nil);
    self.lblTimeEachDay.text = NSLocalizedString(@"msg_timeEachDay", nil);
    self.lblAction.text = NSLocalizedString(@"msg_action", nil);
    [self.btnSelectAction setTitle:NSLocalizedString(@"btn_select", nil) forState:UIControlStateNormal];
    self.lblDeviceName.text = _deviceName;
    
    // Init segemented control
    [self.segCtrlDaysOfWeek setTitle:NSLocalizedString(@"sunday", nil) forSegmentAtIndex:0];
    [self.segCtrlDaysOfWeek setTitle:NSLocalizedString(@"monday", nil) forSegmentAtIndex:1];
    [self.segCtrlDaysOfWeek setTitle:NSLocalizedString(@"tuesday", nil) forSegmentAtIndex:2];
    [self.segCtrlDaysOfWeek setTitle:NSLocalizedString(@"wednesday", nil) forSegmentAtIndex:3];
    [self.segCtrlDaysOfWeek setTitle:NSLocalizedString(@"thursday", nil) forSegmentAtIndex:4];
    [self.segCtrlDaysOfWeek setTitle:NSLocalizedString(@"friday", nil) forSegmentAtIndex:5];
    [self.segCtrlDaysOfWeek setTitle:NSLocalizedString(@"saturday", nil) forSegmentAtIndex:6];
    self.segCtrlDaysOfWeek.delegate = self;
    
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc]
                                    initWithTitle:NSLocalizedString(@"btn_save", nil)
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    if (self.serviceId != IR_SERVICE) {
        [self.btnInitIR setHidden:YES];
        [self.btnEndIR setHidden:YES];
    }
    
    dow = 0b00000000;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(_serviceId == RELAY_SERVICE) {
        [_imgDeviceAction setImage:[UIImage imageNamed:@"svc_0_small"]];
    } else if(_serviceId == NIGHTLED_SERVICE){
        [_imgDeviceAction setImage:[UIImage imageNamed:@"lamp"]];
    }
    
    // Init action
    if (_alarmId > 0) {
        NSArray *alarms = [[SQLHelper getInstance] getAlarmDataById:_alarmId];
        if (alarms && alarms.count > 0) {
            Alarm *a = [alarms firstObject];
            init_hour = a.initial_hour;
            init_minute = a.initial_minute;
            end_hour = a.end_hour;
            end_minute = a.end_minute;
            init_ir_code = a.init_ir;
            end_ir_code = a.end_ir;
            dow = a.dow;
            [self setDOW];
            [self setTime];
        }
    } else {
        dow |= (1 << 2);
        [self setDOW];
    }
    
    // Init IR buttons
    if(self.alarmId != -1){
        NSString *init_name = @"";
        NSArray *irCodes = [[SQLHelper getInstance] getIRCodeById:init_ir_code];
        if (irCodes && irCodes.count>0) {
            IrCode *irCode = [irCodes firstObject];
            init_name = irCode.name;
        }
        _btnInitIR.titleLabel.text = init_name;
        
        NSString *end_name = @"";
        irCodes = [[SQLHelper getInstance] getIRCodeById:end_ir_code];
        if (irCodes && irCodes.count>0) {
            IrCode *irCode = [irCodes firstObject];
            end_name = irCode.name;
        }
        _btnEndIR.titleLabel.text = end_name;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timersSentSuccess:) name:NOTIFICATION_TIMERS_SENT_SUCCESS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceNotReached:) name:NOTIFICATION_DEVICE_NOT_REACHED object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Deregister notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_TIMERS_SENT_SUCCESS object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_DEVICE_NOT_REACHED object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)timersSentSuccess:(NSNotification *)notification {
    NSLog(@"TIMERS SENT SUCCESSFULLY BROADCAST");
    _deviceStatusChangedFlag = true;
    _udpConnection = true;
}

- (void)deviceNotReached:(NSNotification *)notification {
    NSLog(@"BROADCAST DEVICE NOT REACHED");
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSString *error = [userInfo objectForKey:@"error"];
        if (error != nil && error.length>0){
            [self.view makeToast:NSLocalizedString(@"connection_error", nil)
                        duration:3.0
                        position:CSToastPositionCenter];
        } else {
            [self.view makeToast:NSLocalizedString(@"please_wait", nil)
                        duration:3.0
                        position:CSToastPositionCenter];
        }
    }
}

- (void)setDOW {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    for (int i=1; i<=7; i++) {
        if (((dow >> i) & 1) == 1) {
            [indexSet addIndex:i-1];
        }
    }
    
    [_segCtrlDaysOfWeek setSelectedSegmentIndexes:indexSet];
}

- (void)setTime {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *fromComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:_pickerFromTime.date];
    [fromComponents setHour:init_hour];
    [fromComponents setMinute:init_minute];
    NSDate *fromTime = [calendar dateFromComponents:fromComponents];
    [self.pickerFromTime setDate:fromTime animated:TRUE];
    
    NSDateComponents *toComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:_pickerToTime.date];
    [toComponents setHour:end_hour];
    [toComponents setMinute:end_minute];
    NSDate *toTime = [calendar dateFromComponents:toComponents];
    [self.pickerToTime setDate:toTime animated:TRUE];
}

- (IBAction)onBtnSelectAction:(id)sender
{
    SelectActionViewController *selectActionVc = [[SelectActionViewController alloc] initWithNibName:@"SelectActionViewController" bundle:nil];
    selectActionVc.delegate = self;
    [self.navigationController pushViewController:selectActionVc animated:YES];
}


- (void)onRightBarButton:(id)sender {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // Save to database
    Alarm *a = [Alarm new];
    a.device_id = _deviceId;
    a.service_id = _serviceId;
    a.alarm_id = _alarmId;
    a.dow = dow;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:_pickerFromTime.date];
    NSInteger initHour = [components hour];
    NSInteger initMinute = [components minute];
    a.initial_hour = (int)initHour;
    a.initial_minute = (int)initMinute;
    
    components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:_pickerToTime.date];
    NSInteger endHour = [components hour];
    NSInteger endMinute = [components minute];
    a.end_hour = (int)endHour;
    a.end_minute = (int)endMinute;
    a.snooze = 0;
    
    if (_alarmId > 0) {
        [[SQLHelper getInstance] updateAlarm:a];
    } else {
        [[SQLHelper getInstance] insertAlarm:a];
    }
    
    if ([[UDPCommunication getInstance] sendTimers:g_DeviceMac ip:g_DeviceIp]) {
        int counter = 10000;
        while (!_deviceStatusChangedFlag && counter > 0) {
            counter--;
            //waiting time
        }
    }
    
    NSDictionary *userInfo;
    if(!_deviceStatusChangedFlag) {
        if (![[UDPCommunication getInstance] sendTimersHTTP:g_DeviceMac send:0]) {
            userInfo = [NSDictionary dictionaryWithObject:@"yes" forKey:@"error"];
        } else {
            userInfo = [NSDictionary dictionaryWithObject:@"" forKey:@"error"];
            _deviceStatusChangedFlag = false;
        }
    } else {
        [[UDPCommunication getInstance] sendTimersHTTP:g_DeviceMac send:1];
        userInfo = [NSDictionary dictionaryWithObject:@"" forKey:@"error"];
        _deviceStatusChangedFlag = false;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DEVICE_NOT_REACHED object:self userInfo:userInfo];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
        [self.delegate didUpdateAlarms];
    });
}

- (IBAction)onBtnInitIR:(id)sender {
    IRListCommandsViewController *irListCmdVC = [IRListCommandsViewController new];
    irListCmdVC.status = 0;
    irListCmdVC.delegate = self;
    [self.navigationController pushViewController:irListCmdVC animated:YES];
}

- (IBAction)onBtnEndIR:(id)sender {
    IRListCommandsViewController *irListCmdVC = [IRListCommandsViewController new];
    irListCmdVC.status = 1;
    irListCmdVC.delegate = self;
    [self.navigationController pushViewController:irListCmdVC animated:YES];
}

//==================================================================
#pragma mark - MultiSelectSegmentedControlDelegate
//==================================================================
- (void)multiSelect:(MultiSelectSegmentedControl *)multiSelectSegmentedControl didChangeValue:(BOOL)selected atIndex:(NSUInteger)index {
    
    if (selected) {
        NSLog(@"multiSelect with tag %ld selected button at index: %ld", multiSelectSegmentedControl.tag, index);
    } else {
        NSLog(@"multiSelect with tag %ld deselected button at index: %ld", multiSelectSegmentedControl.tag, index);
    }
    
    int position = (int)index+1;
    dow ^= (1 << position);
    
    NSLog(@"selected: '%@'", [multiSelectSegmentedControl.selectedSegmentTitles componentsJoinedByString:@","]);
    NSLog(@"dow = %d", dow);
}

//==================================================================
#pragma mark - SelectActionDelegate
//==================================================================
/*
- (void)didSelectAction:(JSAction *)action {
    NSLog(@"Selected action: Device=%@, type=%@", action.device, action.type);
    
    _lblDeviceName.text = action.device;
    _imgDeviceIcon.image = [UIImage imageNamed:action.deviceIcon];
    _imgDeviceAction.image = [UIImage imageNamed:action.typeIcon];
 
}
 */

//==================================================================
#pragma mark - IRListCommandsDelegate
//==================================================================

- (void)onSelectIRCommand:(int)status group:(NSString *)group irName:(NSString *)irName
{
    int groupId = 0;
    int IRId = -1;
    
    NSArray *irGroups = [[SQLHelper getInstance] getIRGroupByName:group];
    if (irGroups && irGroups.count > 0) {
        for (IrGroup *group in irGroups) {
            groupId = group.group_id;
            NSArray *codes = [[SQLHelper getInstance] getIRCodesByGroup:groupId];
            if (codes && codes.count > 0) {
                for (IrCode *code in codes) {
                    if ([irName isEqualToString:code.name]) {
                        IRId = code.filename;
                    }
                }
            }
        }
    }
    
    switch (status){
        case 0:
            init_ir_name = irName;
            [_btnInitIR setTitle:irName forState:UIControlStateNormal];
            init_ir_code = (uint8_t)IRId;
            break;
        case 1:
            end_ir_name = irName;
            [_btnEndIR setTitle:irName forState:UIControlStateNormal];
            end_ir_code = (uint8_t)IRId;
            break;
    }
}

@end
