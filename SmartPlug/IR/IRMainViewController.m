//
//  IRMainViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/18/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "IRMainViewController.h"
#import "DeviceItemSettingsViewController.h"
#import "UDPListenerService.h"
#import "NoTimersViewController.h"
#import "GMGridView.h"

@interface IRMainViewController ()<GMGridViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet GMGridView *gmGridView;
@property (strong, nonatomic) NSArray *irGroups;

@end

@implementation IRMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.bgView.layer.cornerRadius = CORNER_RADIUS;
    self.lblTitle.text = NSLocalizedString(@"ir_control", nil);
    self.lblTitle.backgroundColor = [Global colorWithType:COLOR_TYPE_TITLE_BG_GREEN];
    self.lblTitle.layer.cornerRadius = CORNER_RADIUS;
    
    NSInteger spacing = 10;
    _gmGridView.style = GMGridViewStyleSwap;
    _gmGridView.itemSpacing = spacing;
    _gmGridView.minEdgeInsets = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
    _gmGridView.centerGrid = YES;
    _gmGridView.dataSource = self;
    
    self.irGroups = [[SQLHelper getInstance] getIRGroups];
    [_gmGridView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [_irGroups count]+1;
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (IS_IPHONE) {
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            return CGSizeMake(170, 170);
        } else {
            return CGSizeMake(140, 140);
        }
    } else {
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            return CGSizeMake(285, 285);
        } else {
            return CGSizeMake(230, 230);
        }
    }
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];

    if (index == 0) {
        GMGridViewCell *cell = [gridView dequeueReusableCell];
        if (!cell) {
            cell = [[GMGridViewCell alloc] init];
            
            UIButton *btnAdd = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
            btnAdd.backgroundColor = [UIColor clearColor];
            btnAdd.layer.masksToBounds = NO;
            btnAdd.imageView.image = [UIImage imageNamed:@"btn_add"];
            
            cell.contentView = btnAdd;
        }
        return cell;
    } else {
        NSDictionary *icon = [_irGroups objectAtIndex:index-1];
        
        GMGridViewCell *cell = [gridView dequeueReusableCell];
        if (!cell) {
            cell = [[GMGridViewCell alloc] init];
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
            imageView.backgroundColor = [UIColor clearColor];
            imageView.layer.masksToBounds = NO;
            
            NSString *iconImagePath = [icon objectForKey:@"url"];
            [imageView sd_setImageWithURL:[NSURL URLWithString:iconImagePath] placeholderImage:nil];
            
            cell.contentView = imageView;
        }
        return cell;
    }
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
    // TODO: Add New IR Group
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
