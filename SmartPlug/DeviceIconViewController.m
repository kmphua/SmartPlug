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

@interface DeviceIconViewController ()<WebServiceDelegate, GMGridViewDataSource, UIImagePickerControllerDelegate>

@property (nonatomic, assign) IBOutlet GMGridView *gmGridView;
@property (nonatomic, strong) NSArray *icons;
@property (nonatomic, strong) UIButton *btnCamera;
@property (nonatomic, strong) UIButton *btnGallery;

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
    
    // Setup grid view
    self.gmGridView.clipsToBounds = YES;
    self.gmGridView.centerGrid = NO;
    
    // Camera button
    int navBarWidth = self.navigationController.navigationBar.frame.size.width;
    self.btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnCamera setAutoresizesSubviews:YES];
    [_btnCamera setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin];
    [_btnCamera setImage:[UIImage imageNamed:@"ic_camera.png"] forState:UIControlStateNormal];
    [_btnCamera addTarget:self action:@selector(onBtnCamera:) forControlEvents:UIControlEventTouchUpInside];
    _btnCamera.frame = CGRectMake(navBarWidth-90, 4, 35, 35);
    [_btnCamera.titleLabel setHidden:YES];
    [self.navigationController.navigationBar addSubview:_btnCamera];
    
    // Gallery button
    self.btnGallery = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnGallery setAutoresizesSubviews:YES];
    [_btnGallery setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin];
    [_btnGallery setImage:[UIImage imageNamed:@"ic_gallery.png"] forState:UIControlStateNormal];
    [_btnGallery addTarget:self action:@selector(onBtnGallery:) forControlEvents:UIControlEventTouchUpInside];
    _btnGallery.frame = CGRectMake(navBarWidth-42, 5, 35, 35);
    [_btnGallery.titleLabel setHidden:YES];
    [self.navigationController.navigationBar addSubview:_btnGallery];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws galleryList:g_UserToken lang:[Global getCurrentLang] iconRes:[Global getIconResolution]];
    [ws showWaitingView:self.view];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_btnCamera) {
        [_btnCamera removeFromSuperview];
    }
    if (_btnGallery) {
        [_btnGallery removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onBtnCamera:(id)sender {
    // Take photo
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.allowsEditing = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)onBtnGallery:(id)sender {
    // Choose from library
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
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
        return CGSizeMake(120, 120);
    } else {
        return CGSizeMake(230, 230);
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
#pragma UIImagePickerControllerDelegate
//==================================================================

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (self.delegate) {
        [self.delegate selectedImage:image];
    }
    [self.navigationController popViewControllerAnimated:YES];
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
        } else if ([resultName isEqualToString:WS_DEV_SET]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Upload image success - %@", message);
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
