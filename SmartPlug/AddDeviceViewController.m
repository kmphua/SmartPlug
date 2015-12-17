//
//  AddDeviceViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/17/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "Global.h"
#import "WebService.h"

@interface AddDeviceViewController () <UITableViewDataSource, UITableViewDelegate, WebServiceDelegate>

@property (weak, nonatomic) IBOutlet UIView *titleBgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UITextView *tvDescription;
@property (weak, nonatomic) IBOutlet UIButton *btnInitDevices;
@property (weak, nonatomic) IBOutlet UIImageView *imgWait;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;
@property (strong, nonatomic) NSMutableArray *devices;

@end

@implementation AddDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.layer.cornerRadius = CORNER_RADIUS;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.titleBgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"title_addDevice", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_YELLOW];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    self.tvDescription.text = NSLocalizedString(@"msg_toStartBtn", nil);
    
    [self.btnInitDevices setTitle:NSLocalizedString(@"Initialize Devices", nil) forState:UIControlStateNormal];
    
    self.devices = [NSMutableArray new];
    
    // Load animation images
    NSArray *waitImageNames = @[@"wait_0.png", @"wait_1.png", @"wait_2.png",
                                @"wait_3.png", @"wait_4.png", @"wait_5.png",
                                @"wait_6.png", @"wait_7.png"];
    NSMutableArray *waitImages = [[NSMutableArray alloc] init];
    for (int i = 0; i < waitImageNames.count; i++) {
        [waitImages addObject:[UIImage imageNamed:[waitImageNames objectAtIndex:i]]];
    }
    self.imgWait.animationImages = waitImages;
    self.imgWait.animationDuration = 0.5;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [self adjustHeightOfTableview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBtnInitDevices:(id)sender {
    if (!self.imgWait.isAnimating) {
        [self.imgWait startAnimating];
    } else {
        [self.imgWait stopAnimating];
    }
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
    return [self.devices count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *device = [self.devices objectAtIndex:[indexPath row]];
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
        
        if ([resultName compare:WS_ACT_DEV] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *devices = (NSArray *)[jsonObject objectForKey:@"devs"];
                if (devices) {
                    NSLog(@"Total %ld devices", devices.count);
                    [self.devices setArray:devices];
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
