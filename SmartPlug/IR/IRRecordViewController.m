//
//  IRRecordViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRRecordViewController.h"
#import "UDPCommunication.h"

@interface IRRecordViewController ()
{
    int ir_filename;
}

@property (nonatomic, weak) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UIImageView *imgWait;
@property (nonatomic, weak) IBOutlet UIButton *btnRecordAgain;
@property (nonatomic, weak) IBOutlet UIButton *btnTestCommand;
@property (nonatomic, weak) IBOutlet UIButton *btnAddNow;

@property (nonatomic) BOOL searching;

@end

@implementation IRRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.lblMessage.text = NSLocalizedString(@"msg_recordIr", nil);
    [self.btnRecordAgain setTitle:NSLocalizedString(@"btn_recordAgain", nil) forState:UIControlStateNormal];
    [self.btnTestCommand setTitle:NSLocalizedString(@"btn_testCommand", nil) forState:UIControlStateNormal];
    [self.btnAddNow setTitle:NSLocalizedString(@"btn_addNow", nil) forState:UIControlStateNormal];
        
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

    // Send IR Record command
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        self.searching = YES;
        [self updateUI];
        [self sendIRRecordCommand];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIrFileName:) name:NOTIFICATION_IR_FILENAME object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:NOTIFICATION_IR_FILENAME];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleIrFileName:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    ir_filename = [[userInfo objectForKey:@"filename"] intValue];
    
    if (ir_filename == -1){
        [self.view makeToast:NSLocalizedString(@"ir_timeout", nil)
                    duration:3.0
                    position:CSToastPositionCenter];
        [_btnTestCommand setEnabled:NO];
        [_btnAddNow setEnabled:NO];
    } else {
        [_btnTestCommand setEnabled:YES];
        [_btnAddNow setEnabled:YES];
    }

    self.searching = NO;
    [self updateUI];

    NSLog(@"IR filename: %d", ir_filename);
}

- (void)sendIRRecordCommand {
    [[UDPCommunication getInstance] sendIRMode:g_DeviceIp];
}

- (void)updateUI {
    if (self.searching) {
        [self.imgWait startAnimating];
    }
    else {
        [self.imgWait stopAnimating];
    }
}

- (IBAction)onBtnRecordAgain:(id)sender {
    self.searching = YES;
    [self updateUI];
    [self sendIRRecordCommand];
}

- (IBAction)onBtnTestCommand:(id)sender {
    [[UDPCommunication getInstance] sendIRFileName:ir_filename];
}

- (IBAction)onBtnAddNow:(id)sender {
    int groupId = 0;
    IrGroup *irGroup = [[SQLHelper getInstance] getIRGroupBySID:_groupId];
    if (irGroup) {
        groupId = irGroup.sid;
    }
    int iconId = 0;
    NSArray *icons = [[SQLHelper getInstance] getIconByUrl:_icon];
    if (icons && icons.count>0) {
        Icon *icon = icons.firstObject;
        iconId = [icon.sid intValue];
    }
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws devIrSetButtons:g_UserToken lang:[Global getCurrentLang] devId:g_DeviceMac serviceId:IR_SERVICE action:IR_SET_ADD groupId:groupId buttonId:0 name:_name icon:iconId code:ir_filename iconRes:[Global getIconResolution]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelIRRecordCommand {
    NSLog(@"CANCELING IR SCANNING");
    [[UDPCommunication getInstance] cancelIRMode];
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
                NSArray *groups = (NSArray *)[jsonObject objectForKey:@"groups"];
                if (groups) {
                    NSLog(@"Total %ld groups", (unsigned long)groups.count);
                    
                    for (NSDictionary *group in groups) {
                        int groupId = [[group objectForKey:@"id"] intValue];
                        NSString *title = [group objectForKey:@"title"];
                        NSString *icon = [group objectForKey:@"icon"];
                        
                        [[SQLHelper getInstance] deleteIRGroupBySID:groupId];
                        [[SQLHelper getInstance] insertIRGroup:title icon:icon position:0 sid:groupId];
                        
                        NSArray *buttons = (NSArray *)[group objectForKey:@"buttons"];
                        for (NSDictionary *button in buttons) {
                            int sid = [[button objectForKey:@"id"] intValue];
                            NSString *title = [button objectForKey:@"title"];
                            NSString *icon = [button objectForKey:@"icon"];
                            
                            [[SQLHelper getInstance] insertIRCodes:groupId name:title filename:ir_filename icon:icon mac:g_DeviceMac sid:sid];
                        }
                    }
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
