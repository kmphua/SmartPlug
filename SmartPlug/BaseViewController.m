//
//  BaseViewController.m
//  Raise
//
//  Created by Kevin Phua on 11/5/15.
//  Copyright © 2015 hagarsoft. All rights reserved.
//

#import "BaseViewController.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "Global.h"
#import "WebService.h"

@interface BaseViewController ()<WebServiceDelegate>

@property (nonatomic, strong) UIButton *btnFriends;
@property (nonatomic, strong) UIButton *btnMessages;
@property (nonatomic, strong) UILabel *lblName;
@property (nonatomic, strong) UILabel *lblPoints;

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Bkgnd"]];
    
    // Init reveal view controller
    if ( self == [self.navigationController.viewControllers objectAtIndex:0] ) {
        [self initSidebarDrawerButton];
    }
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    // Init network error view
    _viewNetworkError = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    _viewNetworkError.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Bkgnd"]];
    
    UIImageView *imgNetworkError = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 75)];
    imgNetworkError.image = [UIImage imageNamed:@"err_noconn"];
    imgNetworkError.center = _viewNetworkError.center;
    [_viewNetworkError addSubview:imgNetworkError];
    
    UILabel *lblNetworkError = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, screenWidth, 50)];
    lblNetworkError.textColor = [UIColor whiteColor];
    lblNetworkError.font = [UIFont systemFontOfSize:18.0f];
    lblNetworkError.textAlignment = NSTextAlignmentCenter;
    lblNetworkError.text = NSLocalizedString(@"ConnectionError", nil);
    [_viewNetworkError addSubview:lblNetworkError];
    [_viewNetworkError setHidden:YES];
    [self.view addSubview:_viewNetworkError];
    
    // Init download error view
    _viewDownloadError = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    _viewDownloadError.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Bkgnd"]];
    
    UIImageView *imgDownloadError = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 79)];
    imgDownloadError.image = [UIImage imageNamed:@"err_fail"];
    imgDownloadError.center = _viewDownloadError.center;
    [_viewDownloadError addSubview:imgDownloadError];

    UILabel *lblDownloadError = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, screenWidth, 50)];
    lblDownloadError.textColor = [UIColor whiteColor];
    lblDownloadError.font = [UIFont systemFontOfSize:18.0f];
    lblDownloadError.textAlignment = NSTextAlignmentCenter;
    lblDownloadError.text = NSLocalizedString(@"DownloadFailed", nil);
    [_viewDownloadError addSubview:lblDownloadError];
    
    UITextView *tvDownloadAgain = [[UITextView alloc] initWithFrame:CGRectMake(0, 180, screenWidth, 50)];
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"DownloadAgain", nil) attributes:@{NSForegroundColorAttributeName:[Global colorWithType:COLOR_TYPE_LINK],NSFontAttributeName:[UIFont systemFontOfSize:18], NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),NSParagraphStyleAttributeName:paragraphStyle,    @"loadSignUpPage": @(YES)}];
    
    tvDownloadAgain.backgroundColor = [UIColor clearColor];
    tvDownloadAgain.textAlignment = NSTextAlignmentCenter;
    tvDownloadAgain.attributedText = attributedString;
    tvDownloadAgain.editable = NO;
    [_viewDownloadError addSubview:tvDownloadAgain];
    [_viewDownloadError setHidden:YES];
    
    [self.view addSubview:_viewDownloadError];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavigationBarButtons];
    [self updateVipPoints];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateNavigationBarButtons {
    if (g_IsLogin) {
        // Setup navigation status bar with member info and messages
        int navBarWidth = self.navigationController.navigationBar.frame.size.width;
        
        UITapGestureRecognizer *tapGestureMemberInfo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openMemberInfo:)];
        
        // Member name
        if (!_lblName) {
            _lblName = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 200, 25)];
            _lblName.textColor = [UIColor whiteColor];
            _lblName.font = [UIFont systemFontOfSize:14.0];
            _lblName.userInteractionEnabled = YES;
            [_lblName addGestureRecognizer:tapGestureMemberInfo];
        }
        _lblName.text = [g_MemberInfo objectForKey:INFO_KEY_NAME];
        [self.navigationController.navigationBar addSubview:_lblName];
        
        // Member points
        if (!_lblPoints) {
            _lblPoints = [[UILabel alloc] initWithFrame:CGRectMake(60, 20, 200, 25)];            
            _lblPoints.textColor = [UIColor whiteColor];
            _lblPoints.font = [UIFont systemFontOfSize:14.0];
            _lblPoints.userInteractionEnabled = YES;
            [_lblPoints addGestureRecognizer:tapGestureMemberInfo];
        }
        int points = [[g_MemberInfo objectForKey:INFO_KEY_LAST_POINT] intValue];
        _lblPoints.text = [NSString stringWithFormat:@"%@:%d",
                           NSLocalizedString(@"MemberPoints", nil),
                           points];
        [self.navigationController.navigationBar addSubview:_lblPoints];
        
        // Friends button
        if (!_btnFriends) {
            _btnFriends = [UIButton buttonWithType:UIButtonTypeCustom];
            [_btnFriends setImage:[UIImage imageNamed:@"ic_menu_friends"] forState:UIControlStateNormal];
            [_btnFriends addTarget:self action:@selector(onBtnFriends:) forControlEvents:UIControlEventTouchUpInside];
            _btnFriends.frame = CGRectMake(navBarWidth-90, 8, 32, 32);
            [_btnFriends.titleLabel setHidden:YES];
        }
        [self.navigationController.navigationBar addSubview:_btnFriends];
        
        // Messages button
        if (!_btnMessages) {
            _btnMessages = [UIButton buttonWithType:UIButtonTypeCustom];
            [_btnMessages setImage:[UIImage imageNamed:@"Ic_menu_msg"] forState:UIControlStateNormal];
            [_btnMessages addTarget:self action:@selector(onBtnMessages:) forControlEvents:UIControlEventTouchUpInside];
            _btnMessages.frame = CGRectMake(navBarWidth-42, 8, 32, 32);
            [_btnMessages.titleLabel setHidden:YES];
        }
        [self.navigationController.navigationBar addSubview:_btnMessages];
        
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        UIBarButtonItem *btnLogin = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"MemberLogin", nil)
                                     style:UIBarButtonItemStyleBordered
                                     target:self
                                     action:@selector(onBtnLogin:)];
        self.navigationItem.rightBarButtonItem = btnLogin;
        
        if (_btnFriends) {
            [_btnFriends removeFromSuperview];
            _btnFriends = nil;
        }
        if (_btnMessages) {
            [_btnMessages removeFromSuperview];
            _btnMessages = nil;
        }
    }
}

- (void)clearNavigationBarSubviews {
    if (_lblName) {
        [_lblName removeFromSuperview];
    }
    if (_lblPoints) {
        [_lblPoints removeFromSuperview];
    }
    if (_btnFriends) {
        [_btnFriends removeFromSuperview];
    }
    if (_btnMessages) {
        [_btnMessages removeFromSuperview];
    }
}

- (void)clearNavigationBarButtons {
    if (_btnFriends) {
        [_btnFriends removeFromSuperview];
    }
    if (_btnMessages) {
        [_btnMessages removeFromSuperview];
    }
}

- (void)onBtnLogin:(id)sender {
    LoginViewController *loginController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [self.navigationController pushViewController:loginController animated:YES];
}

- (void)onBtnFriends:(id)sender {
    [self clearNavigationBarSubviews];
    self.title = @"";

    FriendListViewController *friendController = [[FriendListViewController alloc] initWithNibName:@"FriendListViewController" bundle:nil];
    [self.navigationController pushViewController:friendController animated:YES];
}

- (void)onBtnMessages:(id)sender {
    [self clearNavigationBarSubviews];
    self.title = @"";

    MessageViewController *messageController = [[MessageViewController alloc] initWithNibName:@"MessageViewController" bundle:nil];
    [self.navigationController pushViewController:messageController animated:YES];
}

- (IBAction)openMemberInfo:(id)sender
{
    SWRevealViewController *revealController = self.revealViewController;
    
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    MemberInfoViewController *memberInfoViewController = appDelegate.memberInfoViewController;
    
    UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:memberInfoViewController];
    [revealController pushFrontViewController:frontNavigationController animated:YES];
}

- (void)updateVipPoints {
    WebService *ws = [[WebService alloc] init];
    [ws searchLastPointValue:[g_MemberInfo objectForKey:INFO_KEY_ACCKEY]];
    [ws setDelegate:self];
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
        
        if ([resultName compare:WS_SEARCH_LAST_POINT_VALUE] == NSOrderedSame) {
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
    [self.viewDownloadError setHidden:NO];
}

@end
