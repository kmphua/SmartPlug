//
//  DeviceItemSettingsViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "DeviceItemSettingsViewController.h"

@interface DeviceItemSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;


@end

@implementation DeviceItemSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // TODO: Get Device Status
    
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)adjustHeightOfTableview
{
    CGFloat height = self.tableView.contentSize.height;
    CGFloat maxHeight = 0.85 * self.tableView.superview.frame.size.height;
    
    // if the height of the content is greater than the maxHeight of
    // total space on the screen, limit the height to the size of the
    // superview.
    
    if (height > maxHeight)
        height = maxHeight;
    
    // now set the height constraint accordingly
    
    [UIView animateWithDuration:0.25 animations:^{
        self.tableViewHeightConstraint.constant = height;
        [self.view setNeedsUpdateConstraints];
    }];
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
    return 7;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 75;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [view setBackgroundColor:[Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 75)];
    [label setFont:[UIFont systemFontOfSize:32]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Desk Lamp"/*self.device.name*/];
    [label setTextAlignment:NSTextAlignmentCenter];
    [view addSubview:label];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableViewCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    NSInteger row = indexPath.row;
    switch (row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"id_sevice", nil);
            cell.detailTextLabel.text = @"Smart Plug";
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"id_icon", nil);
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"id_name", nil);
            cell.detailTextLabel.text = @"Desk Lamp"; //self.device.name;
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"id_wifi", nil);
            cell.detailTextLabel.text = @"MyHomeWIFI";
            break;
        case 4:
            cell.textLabel.text = NSLocalizedString(@"id_macID", nil);
            cell.detailTextLabel.text = @"00:00:00:00:00:00";
            break;
        case 5:
            cell.textLabel.text = NSLocalizedString(@"msg_deskLampBtn", nil);
            break;
        case 6:
            cell.textLabel.text = NSLocalizedString(@"lnk_removeAndReset", nil);
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    //NSDictionary *action = [self.actions objectAtIndex:[indexPath row]];
    ScheduleActionViewController *scheduleActionVc = [[ScheduleActionViewController alloc] initWithNibName:@"ScheduleActionViewController" bundle:nil];
    scheduleActionVc.action = nil;
    [self.navigationController pushViewController:scheduleActionVc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
     */
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
                }
                [self.tableView reloadData];
                [self adjustHeightOfTableview];
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
