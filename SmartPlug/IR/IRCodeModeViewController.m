//
//  IRCodeModeViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 3/1/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRCodeModeViewController.h"
#import "IREditModeViewController.h"
#import "DeviceIconViewController.h"
#import "GMGridView.h"

#import "IRRecordViewController.h"
#import "IRCustomViewController.h"
#import "UDPCommunication.h"

@interface IRCodeModeViewController()<GMGridViewDataSource, GMGridViewActionDelegate>

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet GMGridView *gmGridView;
@property (nonatomic, strong) NSArray *codes;
@property (nonatomic, strong) IrGroup *group;
@property (nonatomic) BOOL isEditMode;
@property (strong, nonatomic) UIButton *btnAddNew;
@property (strong, nonatomic) UIBarButtonItem *rightBarBtn;

@end

@implementation IRCodeModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    NSArray *groups = [[SQLHelper getInstance] getIRGroup:_groupId];
    if (groups && groups.count>0) {
        _group = [groups firstObject];
        self.lblTitle.text = _group.name;
    }
    
    // Add navigation buttons
    self.rightBarBtn = [[UIBarButtonItem alloc]
                                    initWithImage:[UIImage imageNamed:@"ic_edit"]
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(onRightBarButton:)];
    self.navigationItem.rightBarButtonItem = self.rightBarBtn;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _codes = [[SQLHelper getInstance] getIRCodesByGroup:_groupId];
    [_gmGridView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onRightBarButton:(id)sender {
    if (_isEditMode) {
        _isEditMode = NO;
        [_rightBarBtn setImage:[UIImage imageNamed:@"ic_edit"]];
    } else {
        _isEditMode = YES;
        [_rightBarBtn setImage:[UIImage imageNamed:@"ic_edit_pressed"]];
    }
    [_gmGridView reloadData];
}

- (void)onBtnAddNew:(id)sender {
    IRCustomViewController *irCustomVC = [[IRCustomViewController alloc] initWithNibName:@"IRCustomViewController" bundle:nil];
    irCustomVC.groupId = _groupId;
    [self.navigationController pushViewController:irCustomVC animated:YES];
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [_codes count]+1;
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return CGSizeMake(120, 120);
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    if (!cell) {
        cell = [[GMGridViewCell alloc] init];
    }

    if (index == 0) {
        _btnAddNew = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width/2, 8, 56, 56)];
        [_btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add.png"] forState:UIControlStateNormal];
        [_btnAddNew setBackgroundImage:[UIImage imageNamed:@"btn_add_pressed.png"] forState:UIControlStateSelected];
        [_btnAddNew addTarget:self action:@selector(onBtnAddNew:) forControlEvents:UIControlEventTouchUpInside];
        cell.contentView = _btnAddNew;
    } else {
        IrCode *code = [_codes objectAtIndex:index-1];
        
        // Create ir button
        UIView *viewIr = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
        viewIr.layer.cornerRadius = 10;
        [viewIr setUserInteractionEnabled:YES];
        
        // Modify cell background according to row position
        int row = (index-1) % 4;
        switch (row) {
            case 0:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_RED];
                break;
            case 1:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
                break;
            case 2:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_YELLOW];
                break;
            case 3:
                viewIr.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_BLUE];
                break;
            default:
                break;
        }
        
        UIButton *btnIr = [[UIButton alloc] initWithFrame:CGRectMake(25, 25, 70, 70)];
        btnIr.tag = code.code_id;
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        //__weak IRCodeModeViewController *weakself = self;
        [manager downloadImageWithURL:[NSURL URLWithString:code.icon]
                              options:0
                             progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                 // progression tracking code
                                 NSLog(@"Received image %ld of %ld bytes", receivedSize, expectedSize);
                             }
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                if (image) {
                                    NSLog(@"Received image width=%.1f, height=%.lf", image.size.width, image.size.height);
                                    [btnIr setBackgroundImage:image forState:UIControlStateNormal];
                                }
                            }];
        
        [btnIr addTarget:self action:@selector(onBtnIr:) forControlEvents:UIControlEventTouchUpInside];
        [viewIr addSubview:btnIr];
        
        UILabel *lblIr = [[UILabel alloc] initWithFrame:CGRectMake(0, 98, 120, 20)];
        lblIr.textColor = [UIColor whiteColor];
        lblIr.text = code.name;
        lblIr.font = [UIFont systemFontOfSize:15];
        lblIr.textAlignment = NSTextAlignmentCenter;
        lblIr.adjustsFontSizeToFitWidth = YES;
        [viewIr addSubview:lblIr];
        
        if (_isEditMode) {
            UIButton *btnDelete = [[UIButton alloc] initWithFrame:CGRectMake(90, 0, 30, 30)];
            [btnDelete setBackgroundImage:[UIImage imageNamed:@"btn_warn_close"] forState:UIControlStateNormal];
            [btnDelete addTarget:self action:@selector(onBtnDelete:) forControlEvents:UIControlEventTouchUpInside];
            btnDelete.tag = code.code_id;
            [viewIr addSubview:btnDelete];
        }
        
        cell.contentView = viewIr;
    }
    
    return cell;
}

- (void)onBtnIr:(id)sender {
    UIButton *btnIr = (UIButton *)sender;
    int codeId = (int)btnIr.tag;
    
    for (IrCode *code in _codes) {
        if (code.code_id == codeId) {
            [[UDPCommunication getInstance] sendIRFileName:code.filename];
            NSLog(@"Sending IR filename %d", code.filename);
            break;
        }
    }
}

- (void)onBtnDelete:(id)sender {
    UIButton *btnDelete = (UIButton *)sender;
    int codeId = (int)btnDelete.tag;
    [[SQLHelper getInstance] deleteIRCode:codeId];
    
    _codes = [[SQLHelper getInstance] getIRCodesByGroup:_groupId];
    [_gmGridView reloadData];
}

- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return NO;
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    //IrCode *code = [_codes objectAtIndex:position-1];
    //[[UDPCommunication getInstance] sendIRFileName:code.filename];
    //NSLog(@"Sending IR filename %d", code.filename);
}

- (void)GMGridViewDidTapOnEmptySpace:(GMGridView *)gridView
{
    NSLog(@"Tap on empty space");
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Are you sure you want to delete this item?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    
    [alert show];
    
    //_lastDeleteItemIndexAsked = index;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        //[_currentData removeObjectAtIndex:_lastDeleteItemIndexAsked];
        //[_gmGridView removeObjectAtIndex:_lastDeleteItemIndexAsked withAnimation:GMGridViewItemAnimationFade];
    }
}


@end
