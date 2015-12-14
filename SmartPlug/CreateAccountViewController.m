//
//  CreateAccountViewController.m
//  PosApp
//
//  Created by Kevin Phua on 9/8/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "CreateAccountViewController.h"
#import "Global.h"

#define STEP_1              0
#define STEP_2              1
#define STEP_3              2
#define STEP_4              3

#define LABEL_FONT_SIZE     18.0

@interface CreateAccountViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UITextField *txtPhoneNumber;
@property (strong, nonatomic) UITextField *txtVerificationCode;
@property (strong, nonatomic) UITextField *txtPassword;
@property (strong, nonatomic) UITextField *txtConfirmPassword;

@property (nonatomic, strong) NSArray *headers;
@property (nonatomic) int currentStep;

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *verificationCode;

@end

@implementation CreateAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Bkgnd"]];
    self.title = NSLocalizedString(@"RegisterAccount", nil);
    
    self.headers = [NSArray arrayWithObjects:NSLocalizedString(@"StepOne", nil),
                    NSLocalizedString(@"StepTwo", nil),
                    NSLocalizedString(@"StepThree", nil),
                    NSLocalizedString(@"StepFour", nil), nil];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.currentStep = STEP_1;
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)viewDidAppear:(BOOL)animated {
    self.phoneNumber = @"";
    self.verificationCode = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSAttributedString *)attributedResendString
{
    NSMutableAttributedString *paragraph = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"NotReceivedVerCode", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],                                                                                  NSFontAttributeName:[UIFont systemFontOfSize:18]}];
    
    NSAttributedString* attributedString1 = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"SendAgain", nil)
                                                                            attributes:@{NSForegroundColorAttributeName:[Global colorWithType:COLOR_TYPE_LINK],NSFontAttributeName:[UIFont systemFontOfSize:18], NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),  @"resendVerCode": @(YES)}];
    
    [paragraph appendAttributedString:attributedString1];
    return [paragraph copy];
}

- (void)onTapResend:(UITapGestureRecognizer *)tapGesture
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
        if ([attributes objectForKey:@"resendVerCode"]) {
            [self onBtnStep1:nil];
        }
    }
}

- (void)onTapView:(UITapGestureRecognizer *)tapGesture
{
    // Dismiss keyboard
    [self.view endEditing:YES];
}

//==================================================================
#pragma mark - Table view delegate
//==================================================================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [_headers count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    
    /* Create custom view to display section header... */
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 200, 30)];
    titleLabel.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
    titleLabel.text = [_headers objectAtIndex:section];
    titleLabel.textColor = [Global colorWithType:COLOR_TYPE_LINK];
    [titleLabel sizeToFit];
    [view addSubview:titleLabel];

    if (section < _currentStep) {
        CGFloat lblWidth = titleLabel.frame.size.width;
        UIImageView *imgTick = [[UIImageView alloc] initWithFrame:CGRectMake(lblWidth+25, 10, 32, 32)];
        imgTick.image = [UIImage imageNamed:@"Ic_menu_yes_orange"];
        [view addSubview:imgTick];
    }
    
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == _currentStep) {
        switch (section) {
            case STEP_2:
            case STEP_3:
                return 4;
            case STEP_4:
                return 2;
            default:
                return 3;
        }
    } else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == STEP_2 && indexPath.row == 0) {
        return 60;
    }
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    
    switch (section) {
        case STEP_1:
            if (row == 0) {
                cell.textLabel.text = NSLocalizedString(@"PleaseEnterPhone", nil);
                cell.textLabel.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                cell.textLabel.textColor = [UIColor whiteColor];
            } else if (row == 1) {
                // Add phone number text field
                _txtPhoneNumber = [[UITextField alloc]initWithFrame:CGRectMake(20, 0, cell.frame.size.width, 30)];
                _txtPhoneNumber.textAlignment = NSTextAlignmentLeft;
                _txtPhoneNumber.delegate = self;
                _txtPhoneNumber.placeholder = NSLocalizedString(@"PhoneNumber", nil);
                _txtPhoneNumber.keyboardType = UIKeyboardTypeNumberPad;
                _txtPhoneNumber.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                _txtPhoneNumber.backgroundColor = [Global colorWithType:COLOR_TYPE_TEXTBOX_BG];
                _txtPhoneNumber.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:_txtPhoneNumber];
            } else if (row == 2) {
                // Add next button
                CGRect buttonRect = CGRectMake(20, 0, 80, 34);
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = buttonRect;
                [button setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
                [button addTarget:self action:@selector(onBtnStep1:) forControlEvents:UIControlEventTouchUpInside];
                [button.titleLabel setFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]];
                button.backgroundColor = [Global colorWithType:COLOR_TYPE_BUTTON_UP];
                button.titleLabel.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:button];
            }
            break;
        case STEP_2:
            if (row == 0) {
                UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(20, 0, 300, 60)];
                textView.text = NSLocalizedString(@"VerificationMsg", nil);
                textView.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                textView.backgroundColor = [UIColor clearColor];
                textView.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:textView];
            } else if (row == 1) {
                // Add verification code field
                _txtVerificationCode = [[UITextField alloc]initWithFrame:CGRectMake(20, 0, cell.frame.size.width, 30)];
                _txtVerificationCode.textAlignment = NSTextAlignmentLeft;
                _txtVerificationCode.delegate = self;
                _txtVerificationCode.placeholder = NSLocalizedString(@"VerificationCode", nil);
                _txtVerificationCode.keyboardType = UIKeyboardTypeNumberPad;
                _txtVerificationCode.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                _txtVerificationCode.backgroundColor = [Global colorWithType:COLOR_TYPE_TEXTBOX_BG];
                _txtVerificationCode.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:_txtVerificationCode];
            } else if (row == 2) {
                // Add next button
                CGRect buttonRect = CGRectMake(20, 0, 80, 34);
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = buttonRect;
                [button setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
                [button addTarget:self action:@selector(onBtnStep2:) forControlEvents:UIControlEventTouchUpInside];
                [button.titleLabel setFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]];
                button.backgroundColor = [Global colorWithType:COLOR_TYPE_BUTTON_UP];
                button.titleLabel.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:button];
            } else if (row == 3) {
                // Add resend label
                UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(20, 0, cell.frame.size.width, 30)];
                textView.attributedText = [self attributedResendString];
                UITapGestureRecognizer *tapGestureResend = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapResend:)];
                [tapGestureResend setNumberOfTouchesRequired:1];
                [tapGestureResend setNumberOfTapsRequired:1];
                textView.backgroundColor = [UIColor clearColor];
                [textView addGestureRecognizer:tapGestureResend];
                [cell.contentView addSubview:textView];
            }
            break;
        case STEP_3:
            if (row == 0) {
                cell.textLabel.text = NSLocalizedString(@"PleaseEnterNewPassword", nil);
                cell.textLabel.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                cell.textLabel.textColor = [UIColor whiteColor];
            } else if (row == 1) {
                // Add password field
                _txtPassword = [[UITextField alloc]initWithFrame:CGRectMake(20, 0, cell.frame.size.width, 30)];
                _txtPassword.textAlignment = NSTextAlignmentLeft;
                _txtPassword.delegate = self;
                _txtPassword.placeholder = NSLocalizedString(@"NewPassword", nil);
                _txtPassword.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                _txtPassword.secureTextEntry = YES;
                _txtPassword.backgroundColor = [Global colorWithType:COLOR_TYPE_TEXTBOX_BG];
                _txtPassword.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:_txtPassword];
            } else if (row == 2) {
                // Add confirm password field
                _txtConfirmPassword = [[UITextField alloc]initWithFrame:CGRectMake(20, 0, cell.frame.size.width, 30)];
                _txtConfirmPassword.textAlignment = NSTextAlignmentLeft;
                _txtConfirmPassword.delegate = self;
                _txtConfirmPassword.placeholder = NSLocalizedString(@"ConfirmPassword", nil);
                _txtConfirmPassword.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                _txtConfirmPassword.secureTextEntry = YES;
                _txtConfirmPassword.backgroundColor = [Global colorWithType:COLOR_TYPE_TEXTBOX_BG];
                _txtConfirmPassword.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:_txtConfirmPassword];
            } else if (row == 3) {
                // Add next button
                CGRect buttonRect = CGRectMake(20, 0, 80, 34);
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = buttonRect;
                [button setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
                [button addTarget:self action:@selector(onBtnStep3:) forControlEvents:UIControlEventTouchUpInside];
                [button.titleLabel setFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]];
                button.backgroundColor = [Global colorWithType:COLOR_TYPE_BUTTON_UP];
                button.titleLabel.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:button];
            }
            break;
        case STEP_4:
            if (row == 0) {
                cell.textLabel.text = NSLocalizedString(@"YouCanStartUsing", nil);
                cell.textLabel.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
                cell.textLabel.textColor = [UIColor whiteColor];
            } else if (row == 1) {
                // Add done button
                CGRect buttonRect = CGRectMake(20, 0, 80, 34);
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = buttonRect;
                [button setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
                [button addTarget:self action:@selector(onBtnStep4:) forControlEvents:UIControlEventTouchUpInside];
                [button.titleLabel setFont:[UIFont systemFontOfSize:LABEL_FONT_SIZE]];
                button.backgroundColor = [Global colorWithType:COLOR_TYPE_BUTTON_UP];
                button.titleLabel.textColor = [UIColor whiteColor];
                [cell.contentView addSubview:button];
            }
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)onBtnStep1:(id)sender {
    if (!_txtPhoneNumber || [_txtPhoneNumber.text length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:NSLocalizedString(@"PhoneNumberError", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    WebService *ws = [[WebService alloc] init];
    ws.delegate = self;
    [ws registerAccount:_txtPhoneNumber.text];
    [ws showWaitingView:self.view];
}

- (void)onBtnStep2:(id)sender {
    if (!_txtVerificationCode || [_txtVerificationCode.text length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:NSLocalizedString(@"VerificationCodeError", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }

    WebService *ws = [[WebService alloc] init];
    ws.delegate = self;
    [ws authenticate:self.phoneNumber authCode:_txtVerificationCode.text];
    [ws showWaitingView:self.view];
}

- (void)onBtnStep3:(id)sender {
    if (!_txtPassword || [_txtPassword.text length] == 0 ||
        !_txtConfirmPassword || [_txtConfirmPassword.text length] == 0 ||
        [_txtPassword.text compare:_txtConfirmPassword.text] != NSOrderedSame) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:NSLocalizedString(@"PasswordError", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    WebService *ws = [[WebService alloc] init];
    ws.delegate = self;
    [ws setPassword:[g_MemberInfo objectForKey:INFO_KEY_VIPID] acckey:[g_MemberInfo objectForKey:INFO_KEY_ACCKEY] password:_txtPassword.text];
    [ws showWaitingView:self.view];
}

- (void)onBtnStep4:(id)sender {
    // Go back to login page
    [self.navigationController popViewControllerAnimated:YES];
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
        
        if ([resultName compare:WS_REGISTER] == NSOrderedSame) {
            // Register
            long code = [[jsonObject objectForKey:@"code"] longValue];
            if (code == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RegisterSuccess", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
                
                self.phoneNumber = _txtPhoneNumber.text;
                _currentStep = STEP_2;
                [self.tableView reloadData];
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RegisterFailed", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        } else if ([resultName compare:WS_AUTH] == NSOrderedSame) {
            // Auth
            long code = [[jsonObject objectForKey:@"code"] longValue];
            if (code == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VerificationSuccess", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];

                NSString *vipId = (NSString *)[jsonObject objectForKey:@"vip_id"];
                if (vipId && vipId.length > 0) {
                    [g_MemberInfo setObject:vipId forKey:INFO_KEY_VIPID];
                }
                NSString *accKey = (NSString *)[jsonObject objectForKey:@"acckey"];
                if (accKey && accKey.length > 0) {
                    [g_MemberInfo setObject:accKey forKeyedSubscript:INFO_KEY_ACCKEY];
                }
                
                _currentStep = STEP_3;
                [self.tableView reloadData];
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VerificationFailed", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
        } else if ([resultName compare:WS_SET_PASSWORD] == NSOrderedSame) {
            // Set password
            long code = [[jsonObject objectForKey:@"code"] longValue];
            if (code == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PasswordSuccess", nil)
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                          otherButtonTitles:nil, nil];
                [alertView show];
                
                NSString *vipId = (NSString *)[jsonObject objectForKey:@"vip_id"];
                if (vipId && vipId.length > 0) {
                    [g_MemberInfo setObject:vipId forKey:INFO_KEY_VIPID];
                }
                
                _currentStep = STEP_4;
                [self.tableView reloadData];
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"message"];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PasswordFailed", nil)
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
