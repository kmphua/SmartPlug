//
//  LoginViewController.m
//  PosApp
//
//  Created by Kevin Phua on 9/8/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "LoginViewController.h"
#import "CreateAccountViewController.h"
#import "CustomBadge.h"
#import "Global.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *txtLogin;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
@property (weak, nonatomic) IBOutlet UITextView *tvMessage;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Bkgnd"]];
    self.title = NSLocalizedString(@"MemberLogin", nil);
    
    self.txtLogin.placeholder = NSLocalizedString(@"MemberPhone", nil);
    self.txtLogin.textColor = [UIColor whiteColor];
    self.txtLogin.backgroundColor = [Global colorWithType:COLOR_TYPE_TEXTBOX_BG];
    self.txtPassword.placeholder = NSLocalizedString(@"Password", nil);
    self.txtPassword.textColor = [UIColor whiteColor];
    self.txtPassword.backgroundColor = [Global colorWithType:COLOR_TYPE_TEXTBOX_BG];
    [self.btnLogin setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    [self.tvMessage setAttributedText:[self attributedTextViewString]];
    [self.tvMessage setTextAlignment:NSTextAlignmentCenter];
    
    UITapGestureRecognizer *tapGestureSignIn = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapSignIn:)];
    [self.tvMessage addGestureRecognizer:tapGestureSignIn];

    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBtnLogin:(id)sender {
    WebService *ws = [[WebService alloc] init];
    [ws setDelegate:self];
    [ws login:self.txtLogin.text password:self.txtPassword.text];
    [ws showWaitingView:self.view];
}

- (void)registerDeviceToken {
    NSString *acckey = [g_MemberInfo objectForKey:INFO_KEY_ACCKEY];
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:UD_DEVICE_TOKEN];
    
    if (acckey && acckey.length>0 && deviceToken && deviceToken.length > 0) {
        WebService *ws = [[WebService alloc] init];
        [ws setDelegate:self];
        [ws registerDevice:acckey deviceId:deviceToken];
    }
}

- (NSAttributedString *)attributedTextViewString
{
    NSMutableAttributedString *paragraph = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"FirstTimeLoginMsg", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],                                                                                  NSFontAttributeName:[UIFont systemFontOfSize:18]}];
    
    NSAttributedString* attributedString1 = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"FirstTimeLoginMsgLink", nil)
            attributes:@{NSForegroundColorAttributeName:[Global colorWithType:COLOR_TYPE_LINK],NSFontAttributeName:[UIFont systemFontOfSize:18], NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),  @"loadSignUpPage": @(YES)}];
    
    [paragraph appendAttributedString:attributedString1];
    return [paragraph copy];
}

- (void)onTapSignIn:(UITapGestureRecognizer *)tapGesture
{
    UITextView *textView = (UITextView *)tapGesture.view;
    
    // Location of the tap in text-container coordinates
    NSLayoutManager *layoutManager = textView.layoutManager;
    CGPoint location = [tapGesture locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;
    
    //NSLog(@"location: %@", NSStringFromCGPoint(location));
    
    // Find the character that's been tapped on
    NSUInteger characterIndex;
    characterIndex = [layoutManager characterIndexForPoint:location
                                           inTextContainer:textView.textContainer
                  fractionOfDistanceBetweenInsertionPoints:NULL];
    
    if (characterIndex < textView.textStorage.length) {
        NSRange range;
        NSDictionary *attributes = [textView.textStorage attributesAtIndex:characterIndex effectiveRange:&range];
        //NSLog(@"%@, %@", attributes, NSStringFromRange(range));
        
        // Based on the attributes, do something
        if ([attributes objectForKey:@"loadSignUpPage"]) {
            CreateAccountViewController *createAcctController = [[CreateAccountViewController alloc] initWithNibName:@"CreateAccountViewController" bundle:nil];
            [self.navigationController pushViewController:createAcctController animated:YES];
        }
    }
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
        
        if ([resultName compare:WS_LOGIN] == NSOrderedSame) {
            long code = [[jsonObject objectForKey:@"code"] longValue];
            if (code == 0) {
                // Success
                NSString *accKey = (NSString *)[jsonObject objectForKey:@"acckey"];
                if (accKey && accKey.length > 0) {
                    [g_MemberInfo setObject:accKey forKey:INFO_KEY_ACCKEY];
                }
                NSString *address = (NSString *)[jsonObject objectForKey:@"address"];
                if (address && address.length > 0) {
                    [g_MemberInfo setObject:address forKey:INFO_KEY_ADDRESS];
                }
                NSString *birthday = (NSString *)[jsonObject objectForKey:@"birthday"];
                if (birthday && birthday.length > 0) {
                    [g_MemberInfo setObject:birthday forKey:INFO_KEY_BIRTHDAY];
                }
                NSString *card = (NSString *)[jsonObject objectForKey:@"card"];
                if (card && card.length > 0) {
                    [g_MemberInfo setObject:card forKey:INFO_KEY_CARD];
                }
                NSString *vipId = (NSString *)[jsonObject objectForKey:@"vip_id"];
                if (vipId && vipId.length > 0) {
                    [g_MemberInfo setObject:vipId forKey:INFO_KEY_VIPID];
                }
                NSString *name = (NSString *)[jsonObject objectForKey:@"name"];
                if (name && name.length > 0) {
                    [g_MemberInfo setObject:name forKey:INFO_KEY_NAME];
                }
                id zip = [jsonObject objectForKey:@"zip"];
                if ([zip isKindOfClass:[NSString class]]) {
                    NSString *zipString = (NSString *)zip;
                    [g_MemberInfo setObject:zipString forKey:INFO_KEY_ZIP];
                }
                NSString *telephone = (NSString *)[jsonObject objectForKey:@"telephone"];
                if (telephone && telephone.length > 0) {
                    [g_MemberInfo setObject:telephone forKey:INFO_KEY_TELEPHONE];
                }
                NSString *sex = (NSString *)[jsonObject objectForKey:@"sex"];
                if (sex && sex.length > 0) {
                    [g_MemberInfo setObject:sex forKey:INFO_KEY_SEX];
                }
                NSString *email = (NSString *)[jsonObject objectForKey:@"email"];
                if (email && email.length > 0) {
                    [g_MemberInfo setObject:email forKey:INFO_KEY_EMAIL];
                }
                NSString *mobile = (NSString *)[jsonObject objectForKey:@"mobile"];
                if (mobile && mobile.length > 0) {
                    [g_MemberInfo setObject:mobile forKey:INFO_KEY_MOBILE];
                }
                NSString *lastPoint = (NSString *)[jsonObject objectForKey:@"last_point"];
                if (lastPoint && lastPoint.length > 0) {
                    [g_MemberInfo setObject:lastPoint forKey:INFO_KEY_LAST_POINT];
                }
                NSString *lastAmt = (NSString *)[jsonObject objectForKey:@"last_amt"];
                if (lastAmt && lastAmt.length > 0) {
                    [g_MemberInfo setObject:lastAmt forKey:INFO_KEY_LAST_AMT];
                }
                NSString *lastIcPoint = (NSString *)[jsonObject objectForKey:@"last_icpoint"];
                if (lastIcPoint && lastIcPoint.length > 0) {
                    [g_MemberInfo setObject:lastIcPoint forKey:INFO_KEY_LAST_IC_POINT];
                }
                NSString *endDate = (NSString *)[jsonObject objectForKey:@"end_date"];
                if (endDate && endDate.length > 0) {
                    [g_MemberInfo setObject:endDate forKey:INFO_KEY_END_DATE];
                }
                NSString *idCard = (NSString *)[jsonObject objectForKey:@"id_card"];
                if (idCard && idCard.length > 0) {
                    [g_MemberInfo setObject:idCard forKey:INFO_KEY_ID_CARD];
                }
                
                // Save username and password
                [[NSUserDefaults standardUserDefaults] setObject:_txtLogin.text forKey:UD_KEY_PHONE];
                [[NSUserDefaults standardUserDefaults] setObject:_txtPassword.text forKey:UD_KEY_PASSWORD];
                
                NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                      dateStyle:NSDateFormatterShortStyle
                                                                      timeStyle:NSDateFormatterFullStyle];
                [[NSUserDefaults standardUserDefaults] setObject:dateString forKey:UD_KEY_LAST_LOGIN];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // Register device token
                [self registerDeviceToken];
                
                // Go back
                g_IsLogin = YES;
                [self.navigationController popViewControllerAnimated:YES];
                
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LoginFailed", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        } else if ([resultName compare:WS_REGISTER_DEVICE] == NSOrderedSame) {
            long code = [[jsonObject objectForKey:@"code"] longValue];
            if (code == 0) {
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                NSLog(@"Register device success: %@", message);
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                NSLog(@"Register device failed: %@", message);
            }
        }
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}

@end
