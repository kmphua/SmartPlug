/*
 * File: CC3xUtility.m
 * Copyright © 2013, Texas Instruments Incorporated - http://www.ti.com/
 * All rights reserved.
 */

#import "CC3xUtility.h"

static CC3xUtility *_sharedObj = nil;

@implementation CC3xUtility

#pragma mark - Class Methods -

/*!!!
 Singleton instance 
 return: static allocated instance of self
 */
+ (CC3xUtility*)sharedInstance{
    if ( _sharedObj == nil ) _sharedObj = [[CC3xUtility alloc] init];
    return _sharedObj;
}

/*!!!
 Destroy the static singleton instance
 */
+(void)destroy{
    if ( _sharedObj ) [_sharedObj release];
    _sharedObj = nil;
}

#pragma mark - Instance Methods -

/* 
 Prepare a cell that is created with respect to the indexpath 
 @param cell is an object of UITableViewcell which is newly created 
 @param indexpath  is respective indexpath of the cell of the row. 
 */
-(UITableViewCell *) prepareCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    CGRect frame = CGRectMake(150.0, 8.0, 150.0, 30.0);
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
        frame = CGRectMake(300.0, 8.0, 400.0, 30.0);
    }
    UITextField *ssidField = [[UITextField alloc] initWithFrame:frame];
    [ssidField setBackgroundColor:[UIColor clearColor]];
    [ssidField setReturnKeyType:UIReturnKeyDone];
    [ssidField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [cell.contentView addSubview:ssidField];
    [ssidField release];
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    
    if ( indexPath.section == 0 ){
        if ( indexPath.row == SSID_ROW ){/// this is SSID row 
            NSString *ssidText = [FirstTimeConfig getSSID];
            [ssidField setText:ssidText];
            [ssidField setPlaceholder:@"SSID"];
            [ssidField setTag:SSID_TAG];
            cell.textLabel.text = @"SSID";
            [ssidField setUserInteractionEnabled:NO];
        }else if (indexPath.row == PASSWORD_ROW ){// this is password field 
            [ssidField setPlaceholder:@"Password"];
            cell.textLabel.text = @"Password";
            [ssidField setTag:PASSWORD_TAG];
            [ssidField setAutocorrectionType:UITextAutocorrectionTypeNo];
            [ssidField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        }else if ( indexPath.row == GATEWAY_ADDRESS_ROW ) {
            [ssidField setPlaceholder:@"Gateway IP Address"];
            cell.textLabel.text = @"Gateway IP Address";
            [ssidField setText:[FirstTimeConfig getGatewayAddress]];
            [ssidField setTag:GATEWAY_TAG];
            [ssidField setUserInteractionEnabled:NO];
            if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
                [ssidField setFrame:CGRectMake(180.0, 8.0, 120.0, 30.0)];
        }else if ( indexPath.row == KEY_ROW ) {
            [ssidField setPlaceholder:@"Key"];
            cell.textLabel.text = @"Key";
            [ssidField setTag:KEY_TAG];
        }else if ( indexPath.row == DEVICE_NAME_ROW ){
            [ssidField setText:@"CC3000"];
            [ssidField setPlaceholder:@"Device Name"];
            [ssidField setTag:DEVICE_NAME_TAG];
            cell.textLabel.text = @"Device Name";
        }
    }else { /// this is Groud ID filed
        cell.textLabel.text = @" Port No.";
    }
    return cell;
}

-(UILabel *) createLabelWithFrame:(CGRect)rect onView:(UIView *)headerView withText:(NSString *)text alignment:(UITextAlignment)textAlignment color:(UIColor *)color 
{
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFont:[UIFont fontWithName:@"Helvetica" size:15.0]];
    [label setText:text];
    [label setTextColor:color];
    [label setTextAlignment:textAlignment];
    [headerView addSubview:label];
    [label release];
    return label;
}

/*
 Roatating the spinning wheel when app starts transmitting data
 @param: Spinner which suppose to rotate with CAAnimation
 @param: The start button on which it appears 
 @param: Bool value for start or stop the animation
 */
- (void)rotateSpinner:(UIImageView*)spinner onButton:(UIButton*)button isStart:(BOOL)start{
    
    if ( start ){
        
        [spinner setHidden:NO];
        CABasicAnimation *fullRotation = [CABasicAnimation     animationWithKeyPath:@"transform.rotation"];
        fullRotation.fromValue = [NSNumber numberWithFloat:0];
        fullRotation.toValue = [NSNumber numberWithFloat:((360*M_PI)/180)];
        fullRotation.duration = 2;
        fullRotation.repeatCount = 1.7014116E+38;//1e100f;(max value for repetition of rotation to achieve continuous rotation)
        fullRotation.removedOnCompletion = NO;//should be No to avoid stopping of animation when app comes to foreground
        [spinner.layer addAnimation:fullRotation forKey:@"360"];
    }else {
        [spinner.layer removeAllAnimations];
        [spinner setHidden:YES];
    }   
}

@end
