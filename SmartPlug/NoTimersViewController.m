//
//  NoTimersViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "NoTimersViewController.h"
#import "SetTimerViewController.h"
#import "SetTimerSnoozeViewController.h"

@interface NoTimersViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIImageView *imgBackground;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnAddTimer;

@end

@implementation NoTimersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    
    UIImage *originalImage = [UIImage imageNamed:@"dialog_bkgnd"];
    UIEdgeInsets insets = UIEdgeInsetsMake(65, 20, 20, 20);
    UIImage *stretchableImage = [originalImage resizableImageWithCapInsets:insets];
    self.imgBackground.image = stretchableImage;
    
    self.lblTitle.text = NSLocalizedString(@"NoTimersSet", nil);
    [self.btnAddTimer setTitle:NSLocalizedString(@"AddTimer", nil) forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onTapView:(UITapGestureRecognizer *)tapGesture
{
    // Dismiss view
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBtnAddTimer:(id)sender {
#if 0
    SetTimerViewController *setTimerVC = [[SetTimerViewController alloc] initWithNibName:@"SetTimerViewController" bundle:nil];
    setTimerVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    setTimerVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    // Close self when next modal dialog closes
    [self presentViewController:setTimerVC animated:YES completion:nil];
#else
    SetTimerSnoozeViewController *setTimerSnoozeVC = [[SetTimerSnoozeViewController alloc] initWithNibName:@"SetTimerSnoozeViewController" bundle:nil];
    setTimerSnoozeVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    setTimerSnoozeVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:setTimerSnoozeVC animated:YES completion:nil];
#endif
}

@end
