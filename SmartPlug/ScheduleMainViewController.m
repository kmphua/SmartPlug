//
//  ScheduleMainViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "ScheduleMainViewController.h"
#import "ScheduleActionViewController.h"
#import "ScheduleMainViewCell.h"
#import "SPAlertView.h"
#import "Alarm.h"

@interface ScheduleMainViewController () <UITableViewDataSource, UITableViewDelegate, ScheduleMainViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *alarms;

@end

@implementation ScheduleMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Add navigation buttons
    UIBarButtonItem *rightBarBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu_new"] style:UIBarButtonItemStylePlain target:self action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = rightBarBtn;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_devId serviceId:_serviceId];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onRightBarButton:(id)sender {
    ScheduleActionViewController *scheduleActionVC = [[ScheduleActionViewController alloc] initWithNibName:@"ScheduleActionViewController" bundle:nil];
    scheduleActionVC.deviceId = _devId;
    scheduleActionVC.deviceName = _devName;
    scheduleActionVC.serviceId = RELAY_SERVICE;
    [self.navigationController pushViewController:scheduleActionVC animated:YES];
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
    return [self.alarms count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 75;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [view setBackgroundColor:[Global colorWithType:COLOR_TYPE_TITLE_BG_RED]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [label setFont:[UIFont systemFontOfSize:32]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:NSLocalizedString(@"title_scheduling", nil)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:label];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ScheduleMainViewCell";
    ScheduleMainViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [tableView registerNib:[UINib nibWithNibName:@"ScheduleMainViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    Alarm *alarm = [self.alarms objectAtIndex:[indexPath row]];
    
    NSMutableString *name = [NSMutableString new];
    int dow = alarm.dow;
    if (((dow >> 1) & 1) == 1){
        [name appendString:@"Sun,"];
    }
    if (((dow >> 2) & 1) == 1){
        [name appendString:@"Mon,"];
    }
    if (((dow >> 3) & 1) == 1){
        [name appendString:@"Tue,"];
    }
    if (((dow >> 4) & 1) == 1){
        [name appendString:@"Wed,"];
    }
    if (((dow >> 5) & 1) == 1){
        [name appendString:@"Thu,"];
    }
    if (((dow >> 6) & 1) == 1){
        [name appendString:@"Fri,"];
    }
    if (((dow >> 7) & 1) == 1){
        [name appendString:@"Sat,"];
    }
    
    [name appendString:[NSString stringWithFormat:@" %.2d:%.2d to %.2d:%.2d", alarm.initial_hour,
                        alarm.initial_minute, alarm.end_hour, alarm.end_minute]];
    cell.lblScheduleTime.text = name;
    
    int serviceId = alarm.service_id;
    if (serviceId == RELAY_SERVICE) {
        cell.lblDeviceName.text = @"Plug";
        cell.imgDeviceAction.image = [UIImage imageNamed:@"svc_0_small"];
    } else if (serviceId == NIGHTLED_SERVICE) {
        cell.lblDeviceName.text = @"Nightlight";
        cell.imgDeviceAction.image = [UIImage imageNamed:@"svc_1_small"];
    }

    cell.imgDeviceIcon.image = [UIImage imageNamed:@"see_Table Lamps_1_white_bkgnd"];
    cell.delegate = self;
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//==================================================================
#pragma ScheduleMainViewCellDelegate
//==================================================================
- (void)onClickBtnEdit:(NSIndexPath *)indexPath
{
    ScheduleActionViewController *scheduleActionVc = [[ScheduleActionViewController alloc] initWithNibName:@"ScheduleActionViewController" bundle:nil];
    scheduleActionVc.deviceId = self.devId;
    scheduleActionVc.deviceName = self.devName;
    scheduleActionVc.serviceId = self.serviceId;
    
    Alarm *alarm = [self.alarms objectAtIndex:[indexPath row]];
    scheduleActionVc.alarmId = alarm.alarm_id;
    [self.navigationController pushViewController:scheduleActionVc animated:YES];
}

- (void)onClickBtnDelete:(NSIndexPath *)indexPath
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"title_removeAction", nil)
                                          message:NSLocalizedString(@"msg_removeActionBtn", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        Alarm *alarm = [self.alarms objectAtIndex:[indexPath row]];
        BOOL result = [[SQLHelper getInstance] deleteAlarmData:alarm.alarm_id];
        NSLog(@"Alarm %d deleted = %d", alarm.alarm_id, result);
        
        self.alarms = [[SQLHelper getInstance] getAlarmDataByDeviceAndService:_devId serviceId:_serviceId];
        [self.tableView reloadData];
    }];
    [alertController addAction:ok];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:cancel];

    [self presentViewController:alertController animated:YES completion:nil];
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
        
        if ([resultName compare:WS_DEV_LIST] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *devices = (NSArray *)[jsonObject objectForKey:@"devs"];
                if (devices) {
                    NSLog(@"Total %ld actions", devices.count);
                    //[self.alarms setArray:devices];
                }
                [self.tableView reloadData];
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
