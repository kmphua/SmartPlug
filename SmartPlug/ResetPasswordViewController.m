//
//  ResetPasswordViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 9/8/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "ResetPasswordViewController.h"
#import "CreateAccountViewController.h"
#import "CustomBadge.h"
#import "Global.h"

@interface ResetPasswordViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UITextField *txtUsername;
@property (weak, nonatomic) IBOutlet UIButton *btnSubmit;

@end

@implementation ResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"title_resetPassword", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_BLUE];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    self.lblUsername.text = NSLocalizedString(@"msg_enterNewUserName", nil);
    self.txtUsername.placeholder = NSLocalizedString(@"id_username", nil);
    [self.btnSubmit setTitle:NSLocalizedString(@"btn_submit", nil) forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onTapView:(UITapGestureRecognizer *)tapGesture
{
    // Dismiss keyboard
    [self.view endEditing:YES];
}

- (BOOL)checkInputFields
{
    if (self.txtUsername.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"UsernameEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }    
    return YES;
}

- (IBAction)onBtnSubmit:(id)sender
{
    if (![self checkInputFields]) {
        return;
    }
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws changePassword:self.txtUsername.text password:nil lang:[Global getCurrentLang]];
    [ws showWaitingView:self.view];
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
        if ([resultName compare:WS_CHANGE_PWD] == NSOrderedSame) {
            if (code == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"title_passwordResetSent", nil)
                                                                    message:NSLocalizedString(@"msg_passwordResetBtn", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
                
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
        } 
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}

@end
