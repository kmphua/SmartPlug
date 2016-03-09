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
#import "UDPCommunication.h"

@interface ScheduleActionViewController () <MultiSelectSegmentedControlDelegate, SelectActionDelegate>
{
    int init_hour;
    int end_hour;
    int init_minute;
    int end_minute;
    int dow;
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

@end

@implementation ScheduleActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"title_scheduleAction", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_RED];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    self.lblDaysOfWeek.text = NSLocalizedString(@"msg_daysofWeek", nil);
    self.lblTimeEachDay.text = NSLocalizedString(@"msg_timeEachDay", nil);
    self.lblAction.text = NSLocalizedString(@"msg_action", nil);
    [self.btnSelectAction setTitle:NSLocalizedString(@"btn_select", nil) forState:UIControlStateNormal];
    
    /*
    if (_serviceId == ALARM_RELAY_SERVICE) {
        self.imgDeviceAction.image = [UIImage imageNamed:@"svc_0_big"];
    }
    if (_serviceId == ALARM_NIGHTLED_SERVICE) {
        self.imgDeviceAction.image = [UIImage imageNamed:@"svc_1_big"];
    }
    */
    
    // Init segemented control
    self.segCtrlDaysOfWeek.delegate = self;
    
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc]
                                    initWithTitle:NSLocalizedString(@"btn_save", nil)
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
    
    dow = 0b00000000;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(_serviceId == ALARM_RELAY_SERVICE) {
        [_imgDeviceAction setImage:[UIImage imageNamed:@"svc_0_big"]];
    } else if(_serviceId == ALARM_NIGHTLED_SERVICE){
        [_imgDeviceAction setImage:[UIImage imageNamed:@"svc_1_big"]];
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
            dow = a.dow;
            [self setDOW];
        }
    } else {
        dow |= (1 << 2);
        [self setDOW];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)onBtnSelectAction:(id)sender
{
    SelectActionViewController *selectActionVc = [[SelectActionViewController alloc] initWithNibName:@"SelectActionViewController" bundle:nil];
    selectActionVc.delegate = self;
    [self.navigationController pushViewController:selectActionVc animated:YES];
}


- (void)onRightBarButton:(id)sender {
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
    
    [self.view makeToast:NSLocalizedString(@"msg_pleaseWait", nil)
                duration:3.0
                position:CSToastPositionCenter];
    
    [[UDPCommunication getInstance] setDeviceTimers:g_DeviceMac];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
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

@end
