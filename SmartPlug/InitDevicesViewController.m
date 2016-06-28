//
//  InitDevicesViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "InitDevicesViewController.h"

@interface InitDevicesViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIImageView *imgBackground;
@property (weak, nonatomic) IBOutlet UILabel *lblInitDevices;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UILabel *lblSSID;
@property (weak, nonatomic) IBOutlet UITextField *txtSSID;
@property (weak, nonatomic) IBOutlet UILabel *lblPassword;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIButton *btnOK;

@end

@implementation InitDevicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    
    UIImage *originalImage = [UIImage imageNamed:@"dialog_bkgnd"];
    UIEdgeInsets insets = UIEdgeInsetsMake(65, 20, 20, 20);
    UIImage *stretchableImage = [originalImage resizableImageWithCapInsets:insets];
    self.imgBackground.image = stretchableImage;
    
    self.lblInitDevices.text = NSLocalizedString(@"title_initializeDevices", nil);
    self.lblMessage.text = NSLocalizedString(@"msg_enterSSID_password", nil);
    self.lblSSID.text = @"SSID";
    self.lblPassword.text = NSLocalizedString(@"id_password", nil);
    self.txtSSID.placeholder = @"SSID";
    self.txtPassword.placeholder = NSLocalizedString(@"id_password", nil);
    [self.btnCancel setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [self.btnOK setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    
    if (self.ssid) {
        self.txtSSID.text = self.ssid;
    }
    
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
    if (self.txtSSID.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"OldPasswordEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    if (self.txtPassword.text.length == 0) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error",nil)
                                              message:NSLocalizedString(@"NewPasswordEmpty", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    
    return YES;
}

- (IBAction)onBtnCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnOK:(id)sender {
    if (![self checkInputFields]) {
        return;
    }
    
    [self.delegate ssidPassword:self.txtPassword.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
