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

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    self.navigationItem.title = @"";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    self.view.backgroundColor = [Global colorWithType:COLOR_TYPE_DEFAULT_BG];
    
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateNavigationBarButtons {
    if (g_IsLogin) {
        // Setup navigation status bar with member info and messages
        int navBarWidth = self.navigationController.navigationBar.frame.size.width;
        
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        /*
        UIBarButtonItem *btnLogin = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"MemberLogin", nil)
                                     style:UIBarButtonItemStyleBordered
                                     target:self
                                     action:@selector(onBtnLogin:)];
        self.navigationItem.rightBarButtonItem = btnLogin;
         */
    }
}

- (void)onBtnLogin:(id)sender {
    LoginViewController *loginController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [self.navigationController pushViewController:loginController animated:YES];
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
        
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
    [self.viewDownloadError setHidden:NO];
}

@end
