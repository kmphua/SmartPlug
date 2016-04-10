//
//  HelpViewController.m
//  XONE
//
//  Created by Kevin Phua on 2016/03/16.
//  Copyright (c) 2016 hagarsoft. All rights reserved.
//

#import "HelpViewController.h"
#import "LoginViewController.h"
#import "AppDelegate.h"

@interface HelpViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imgIcon;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblDesc;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [Global colorWithHelpPage:(int)_indexNumber];
    [_btnLogin setTitle:NSLocalizedString(@"btn_login", nil) forState:UIControlStateNormal];
    
    // Setup image
    switch (_indexNumber) {
        case 0:
            {
                [_imgIcon setImage:[UIImage imageNamed:@"help_1"]];
                [_lblTitle setText:NSLocalizedString(@"help_1_title", nil)];
                [_lblDesc setText:NSLocalizedString(@"help_1_desc", nil)];
                [_btnLogin setHidden:YES];
            }
            break;
        case 1:
            {
                if ([[Global getCurrentLang] isEqualToString:@"en"]) {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_2_en"]];
                } else {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_2_cn"]];
                }
                [_lblTitle setText:NSLocalizedString(@"help_2_title", nil)];
                [_lblDesc setText:NSLocalizedString(@"help_2_desc", nil)];
                [_btnLogin setHidden:YES];
            }
            break;
        case 2:
            {
                if ([[Global getCurrentLang] isEqualToString:@"en"]) {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_3_en"]];
                } else {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_3_cn"]];
                }
                [_lblTitle setText:NSLocalizedString(@"help_3_title", nil)];
                [_lblDesc setText:NSLocalizedString(@"help_3_desc", nil)];
                [_btnLogin setHidden:YES];
            }
            break;
        case 3:
            {
                [_imgIcon setImage:[UIImage imageNamed:@"help_9"]];
                [_lblTitle setText:NSLocalizedString(@"help_4_title", nil)];
                [_lblDesc setText:NSLocalizedString(@"help_4_desc", nil)];
                [_btnLogin setHidden:YES];
            }
            break;
        case 4:
            {
                if ([[Global getCurrentLang] isEqualToString:@"en"]) {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_4_en"]];
                } else {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_4_cn"]];
                }
                [_lblTitle setText:NSLocalizedString(@"help_5_title", nil)];
                [_lblDesc setText:NSLocalizedString(@"help_5_desc", nil)];
                [_btnLogin setHidden:YES];
            }
            break;
        case 5:
            {
                if ([[Global getCurrentLang] isEqualToString:@"en"]) {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_5_en"]];
                } else {
                    [_imgIcon setImage:[UIImage imageNamed:@"help_5_cn"]];
                }
                [_lblTitle setText:NSLocalizedString(@"help_6_title", nil)];
                [_lblDesc setText:NSLocalizedString(@"help_6_desc", nil)];
                [_btnLogin setHidden:YES];
            }
            break;
        case 6:
            {
                [_imgIcon setImage:[UIImage imageNamed:@"help_6"]];
                [_lblTitle setText:NSLocalizedString(@"help_7_title", nil)];
                [_lblDesc setText:@""];
                [_btnLogin setHidden:NO];
            }
            break;
        default:
            break;
    }
    
    _lblDesc.numberOfLines = 0;
    [_lblDesc sizeToFit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBtnLogin:(id)sender {
    LoginViewController *loginController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    UINavigationController *navi = [[UINavigationController alloc]initWithRootViewController:loginController];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = navi;
    [appDelegate.window makeKeyAndVisible];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UD_KEY_FIRST_USE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
