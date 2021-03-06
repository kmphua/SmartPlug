//
//  LoginViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 9/8/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "LoginViewController.h"
#import "CreateAccountViewController.h"
#import "ResetPasswordViewController.h"
#import "MainViewController.h"
#import "AppDelegate.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UITextField *txtLogin;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UILabel *lblCreateAccount;
@property (weak, nonatomic) IBOutlet UILabel *lblForgotPassword;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.txtLogin.placeholder = NSLocalizedString(@"id_username", nil);
    self.txtPassword.placeholder = NSLocalizedString(@"id_password", nil);
    [self.btnLogin setTitle:NSLocalizedString(@"btn_login", nil) forState:UIControlStateNormal];
    
    NSAttributedString* attribStrCreateAcct = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"lnk_createAccount", nil)
                                                                            attributes:@{NSForegroundColorAttributeName:[Global colorWithType:COLOR_TYPE_LINK],NSFontAttributeName:[UIFont systemFontOfSize:18], NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];
    self.lblCreateAccount.attributedText = attribStrCreateAcct;

    NSAttributedString* attribStrForgotPwd = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"lnk_forgetPassword", nil)
                                                                              attributes:@{NSForegroundColorAttributeName:[Global colorWithType:COLOR_TYPE_LINK],NSFontAttributeName:[UIFont systemFontOfSize:18], NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];
    self.lblForgotPassword.attributedText = attribStrForgotPwd;
    
    UITapGestureRecognizer *tapGestureCreateAccount = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapCreateAccount:)];
    [self.lblCreateAccount addGestureRecognizer:tapGestureCreateAccount];

    UITapGestureRecognizer *tapGestureForgotPassword = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapForgotPassword:)];
    [self.lblForgotPassword addGestureRecognizer:tapGestureForgotPassword];

    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Check network availability
    /*
    if (![Global isNetworkReady]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_network_error", nil) message:NSLocalizedString(@"msg_unable_to_connect", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
     */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getGalleryList {
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws galleryList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
}

- (void)registerPushToken {
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws regPush:g_UserToken lang:[Global getCurrentLang] devToken:g_DevToken];
}

- (BOOL)checkInputFields
{
    if (self.txtLogin.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"UsernameEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    if (self.txtPassword.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"PasswordEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    
    return YES;
}

- (IBAction)onBtnLogin:(id)sender {
    if (![self checkInputFields]) {
        return;
    }

    WebService *ws = [[WebService alloc] init];
    [ws setDelegate:self];
    [ws login:self.txtLogin.text password:self.txtPassword.text lang:[Global getCurrentLang]];
    [ws showWaitingView:self.view];
}

- (NSAttributedString *)attributedTextViewString
{
    NSMutableAttributedString *paragraph = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"FirstTimeLoginMsg", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],                                                                                  NSFontAttributeName:[UIFont systemFontOfSize:18]}];
    
    NSAttributedString* attributedString1 = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"FirstTimeLoginMsgLink", nil)
            attributes:@{NSForegroundColorAttributeName:[Global colorWithType:COLOR_TYPE_LINK],NSFontAttributeName:[UIFont systemFontOfSize:18], NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),  @"loadSignUpPage": @(YES)}];
    
    [paragraph appendAttributedString:attributedString1];
    return [paragraph copy];
}

- (void)onTapCreateAccount:(UITapGestureRecognizer *)tapGesture
{
    CreateAccountViewController *createAcctController = [[CreateAccountViewController alloc] initWithNibName:@"CreateAccountViewController" bundle:nil];
    [self.navigationController pushViewController:createAcctController animated:YES];
}

- (void)onTapForgotPassword:(UITapGestureRecognizer *)tapGesture
{
    ResetPasswordViewController *resetPwdController = [[ResetPasswordViewController alloc] initWithNibName:@"ResetPasswordViewController" bundle:nil];
    [self.navigationController pushViewController:resetPwdController animated:YES];
}

- (void)onTapView:(UITapGestureRecognizer *)tapGesture
{
    // Dismiss keyboard
    [self.view endEditing:YES];
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName webservice:(WebService *)ws {
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
        
        if ([resultName compare:WS_LOGIN] == NSOrderedSame) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *userToken = [jsonObject objectForKey:@"token"];
                
                // Save username and password
                [[NSUserDefaults standardUserDefaults] setObject:_txtLogin.text forKey:UD_KEY_PHONE];
                [[NSUserDefaults standardUserDefaults] setObject:_txtPassword.text forKey:UD_KEY_PASSWORD];
                [[NSUserDefaults standardUserDefaults] setObject:userToken forKey:UD_USER_TOKEN];
                
                g_Username = _txtLogin.text;
                g_Password = _txtPassword.text;
                g_UserToken = userToken;
                
                NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                      dateStyle:NSDateFormatterShortStyle
                                                                      timeStyle:NSDateFormatterFullStyle];
                [[NSUserDefaults standardUserDefaults] setObject:dateString forKey:UD_KEY_LAST_LOGIN];
                [[NSUserDefaults standardUserDefaults] synchronize];
                                
                // Go to main view
                g_IsLogin = YES;
                
                [self registerPushToken];
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LoginFailed", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        } else if ([resultName isEqualToString:WS_GALLERY_LIST]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                //NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *icons = (NSArray *)[jsonObject objectForKey:@"icons"];
                if (icons) {
                    NSLog(@"Total %ld icons", (unsigned long)icons.count);
                    g_DeviceIcons = icons;
                }
            }
            
            // Set main view as root
            MainViewController *mainController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
            UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:mainController];
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            appDelegate.window.rootViewController = navi;
            [appDelegate.window makeKeyAndVisible];
            
        } else if ([resultName isEqualToString:WS_REG_PUSH]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                //NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Register push success!");
            } else {
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Register push failed! %@", message);
            }
            [self getGalleryList];
        }
    }
}

- (void)connectFail:(NSString*)resultName  webservice:(WebService *)ws{
    NSLog(@"Connect fail for %@", resultName);
}

@end
