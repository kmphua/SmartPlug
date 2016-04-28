//
//  DeviceIconViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 2/28/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "DeviceIconViewController.h"
#import "GMGridView.h"
#import "UIImageView+WebCache.h"

@interface DeviceIconViewController ()<WebServiceDelegate, GMGridViewDataSource>

@property (nonatomic, assign) IBOutlet GMGridView *gmGridView;
@property (nonatomic, strong) NSArray *icons;

@end

@implementation DeviceIconViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSInteger spacing = 10;
    _gmGridView.style = GMGridViewStyleSwap;
    _gmGridView.itemSpacing = spacing;
    _gmGridView.minEdgeInsets = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
    _gmGridView.centerGrid = YES;
    _gmGridView.dataSource = self;
    _gmGridView.backgroundColor = [UIColor colorWithRed:134.0/255.0 green:211.0/255.0 blue:209.0/255.0 alpha:1.0];
    
    self.view.backgroundColor = [UIColor colorWithRed:134.0/255.0 green:211.0/255.0 blue:209.0/255.0 alpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws galleryList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
    [ws showWaitingView:self.view];
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
    return [_icons count];
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
    
    NSDictionary *icon = [_icons objectAtIndex:index];
    
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


- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return NO;
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    NSDictionary *icon = [_icons objectAtIndex:position];
    NSString *selectedIconUrl = [icon objectForKey:@"url"];
    NSLog(@"Selected icon id=%@", selectedIconUrl);
    [self.delegate selectedIcon:selectedIconUrl];
    [self.navigationController popViewControllerAnimated:YES];
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
        
        if ([resultName isEqualToString:WS_GALLERY_LIST]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                //NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSArray *icons = (NSArray *)[jsonObject objectForKey:@"icons"];
                if (icons) {
                    NSLog(@"Total %ld icons", icons.count);
                    _icons = icons;
                    [_gmGridView reloadData];
                }
            } else {
                // Failure
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
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
}

@end
