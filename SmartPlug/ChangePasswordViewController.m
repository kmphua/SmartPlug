//
//  ChangePasswordViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 9/8/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "ChangePasswordViewController.h"

#define kOFFSET_FOR_KEYBOARD 80.0

@interface ChangePasswordViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblOldPassword;
@property (weak, nonatomic) IBOutlet UILabel *lblNewPassword;
@property (weak, nonatomic) IBOutlet UILabel *lblConfirmNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtOldPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtConfirmNewPassword;

@property (strong, nonatomic) UITextField *activeField;

@end

@implementation ChangePasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"id_changePassword", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_RED];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    self.lblOldPassword.text = NSLocalizedString(@"msg_enterOldPassword", nil);
    self.txtOldPassword.placeholder = NSLocalizedString(@"id_password", nil);
    self.lblNewPassword.text = NSLocalizedString(@"msg_enterNewPassword", nil);
    self.txtNewPassword.placeholder = NSLocalizedString(@"id_password", nil);
    self.lblConfirmNewPassword.text = NSLocalizedString(@"msg_confirmPassword", nil);
    self.txtConfirmNewPassword.placeholder = NSLocalizedString(@"id_password", nil);
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"btn_done", nil)    style:UIBarButtonItemStylePlain target:self action:@selector(onBtnSubmit:)];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    if (self.txtOldPassword.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"OldPasswordEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    if (self.txtNewPassword.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"NewPasswordEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    if (self.txtConfirmNewPassword.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"ConfirmPasswordEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    if (self.txtNewPassword.text.length < 6) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"password_length_error", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    if ([self.txtNewPassword.text containsString:@"#"] ||
        [self.txtNewPassword.text containsString:@"&"]) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"password_badchar_error", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    if ([self.txtNewPassword.text compare:self.txtConfirmNewPassword.text] != NSOrderedSame) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"PasswordsNotMatch", nil)
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
    [ws changePassword:g_UserToken lang:[Global getCurrentLang] password:self.txtOldPassword.text newPassword:self.txtNewPassword.text];
    [ws showWaitingView:self.view];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName webservice:(WebService *)ws {
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
        
        if ([resultName compare:WS_CHANGE_PWD] == NSOrderedSame) {
            // Register
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                //NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:NSLocalizedString(@"title_changePassword", nil)
                                             message:NSLocalizedString(@"password_reset", nil)
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* ok = [UIAlertAction
                                     actionWithTitle:NSLocalizedString(@"OK", nil)
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action)
                                     {
                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                         // Return to login page
                                         [self.navigationController popViewControllerAnimated:YES];
                                     }];
                
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            } else  {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"title_changePassword", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName  webservice:(WebService *)ws{
    NSLog(@"Connect fail for %@", resultName);
}

@end
