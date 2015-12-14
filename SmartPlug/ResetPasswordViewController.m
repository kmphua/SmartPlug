//
//  ResetPasswordViewController.m
//  PosApp
//
//  Created by Kevin Phua on 9/8/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "ResetPasswordViewController.h"
#import "CreateAccountViewController.h"
#import "CustomBadge.h"
#import "Global.h"

@interface ResetPasswordViewController ()

@property (weak, nonatomic) IBOutlet UITextField *txtOldPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtNewPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnChangePassword;

@end

@implementation ResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString(@"ChangePassword", nil);
    
    self.txtOldPassword.placeholder = NSLocalizedString(@"OldPassword", nil);
    self.txtNewPassword.placeholder = NSLocalizedString(@"NewPassword", nil);
    
    [self.btnChangePassword setTitle:NSLocalizedString(@"ChangePassword", nil) forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBtnChangePassword:(id)sender {
    WebService *ws = [[WebService alloc] init];
    [ws setDelegate:self];
    
    NSString *vipId = [g_MemberInfo objectForKey:INFO_KEY_VIPID];
    NSString *acckey = [g_MemberInfo objectForKey:INFO_KEY_ACCKEY];
    
    [ws changePassword:vipId acckey:acckey oldpass:self.txtOldPassword.text password:self.txtNewPassword.text];
    [ws showWaitingView:self.view];
}

- (void)onTapView:(UITapGestureRecognizer *)tapGesture
{
    // Dismiss keyboard
    [self.view endEditing:YES];
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received data for %@: %@", resultName, dataString);
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *jsonArray = (NSArray *)jsonObject;
        NSLog(@"jsonArray - %@", jsonArray);
    } else {
        NSDictionary *jsonDict = (NSDictionary *)jsonObject;
        NSLog(@"jsonDict - %@", jsonDict);
        
        long code = [[jsonObject objectForKey:@"code"] longValue];
        if ([resultName compare:WS_CHANGE_PASSWORD] == NSOrderedSame) {
            if (code == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ChangePassword", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
                
                // Save new password
                [[NSUserDefaults standardUserDefaults] setObject:_txtNewPassword.text forKey:UD_KEY_PASSWORD];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // Go back
                [self.navigationController popViewControllerAnimated:YES];
                
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ChangePasswordFailed", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        } else if ([resultName compare:WS_SEARCH_LAST_POINT_VALUE] == NSOrderedSame) {
            long code = [[jsonObject objectForKey:@"code"] longValue];
            if (code == 0) {
                // Success
                NSString *vipPoint = (NSString *)[jsonObject objectForKey:@"vip_point"];
                if (vipPoint && vipPoint.length > 0) {
                    [g_MemberInfo setObject:vipPoint forKey:INFO_KEY_LAST_POINT];
                }
                [self updateNavigationBarButtons];
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
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
