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
@property (weak, nonatomic) IBOutlet UIView *viewRecord;
@property (weak, nonatomic) IBOutlet UILabel *lblChoose;
@property (weak, nonatomic) IBOutlet UILabel *lblDetect;
@property (weak, nonatomic) IBOutlet UILabel *lblRecord;


@end

@implementation IRAddNewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"title_add_new", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    self.viewChoose.layer.cornerRadius = CORNER_RADIUS;
    self.viewDetect.layer.cornerRadius = CORNER_RADIUS;
    self.viewRecord.layer.cornerRadius = CORNER_RADIUS;
    
    self.lblChoose.text = NSLocalizedString(@"btn_chooseBrand", nil);
    self.lblDetect.text = NSLocalizedString(@"btn_detectBrand", nil);
    self.lblRecord.text = NSLocalizedString(@"btn_recordCustom", nil);
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.viewChoose attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.viewDetect attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0]];
    
    UITapGestureRecognizer *tapViewChoose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapViewChoose:)];
    [self.viewChoose addGestureRecognizer:tapViewChoose];

    UITapGestureRecognizer *tapViewDetect = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapViewDetect:)];
    [self.viewDetect addGestureRecognizer:tapViewDetect];

    UITapGestureRecognizer *tapViewRecord = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapViewRecord:)];
    [self.viewRecord addGestureRecognizer:tapViewRecord];
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

- (void)onTapViewRecord:(UITapGestureRecognizer *)tapGestureRecognizer {
    IREditItemViewController *irEditVC = [[IREditItemViewController alloc] initWithNibName:@"IREditItemViewController" bundle:nil];
    [self.navigationController pushViewController:irEditVC animated:YES];
}

@end
