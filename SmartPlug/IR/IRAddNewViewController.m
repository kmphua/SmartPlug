//
//  IRAddNewViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 2/29/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRAddNewViewController.h"
#import "IRDetectIRViewController.h"
#import "IREditItemViewController.h"

@interface IRAddNewViewController ()

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIView *viewChoose;
@property (weak, nonatomic) IBOutlet UIView *viewDetect;
@property (weak, nonatomic) IBOutlet UIView *viewCreate;

@end

@implementation IRAddNewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"ir_add_new", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    self.viewChoose.layer.cornerRadius = CORNER_RADIUS;
    self.viewDetect.layer.cornerRadius = CORNER_RADIUS;
    self.viewCreate.layer.cornerRadius = CORNER_RADIUS;
    
    UITapGestureRecognizer *tapViewChoose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapViewChoose:)];
    [self.view addGestureRecognizer:tapViewChoose];

    UITapGestureRecognizer *tapViewDetect = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapViewDetect:)];
    [self.view addGestureRecognizer:tapViewDetect];

    UITapGestureRecognizer *tapViewCreate = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapViewCreate:)];
    [self.view addGestureRecognizer:tapViewCreate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onTapViewChoose:(UITapGestureRecognizer *)tapGestureRecognizer {
    
}

- (void)onTapViewDetect:(UITapGestureRecognizer *)tapGestureRecognizer {
    IRDetectIRViewController *irDetectVC = [[IRDetectIRViewController alloc] initWithNibName:@"IRDetectIRViewController" bundle:nil];
    [self.navigationController pushViewController:irDetectVC animated:YES];
}

- (void)onTapViewCreate:(UITapGestureRecognizer *)tapGestureRecognizer {
    IREditItemViewController *irEditVC = [[IREditItemViewController alloc] initWithNibName:@"IREditItemViewController" bundle:nil];
    [self.navigationController pushViewController:irEditVC animated:YES];
}

@end
