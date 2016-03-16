//
//  Global.m
//  SmartPlug
//
//  Created by Kevin Phua on 9/16/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Global.h"
#include <sys/socket.h>
#include <netdb.h>

@implementation Global

+ (UIColor *)colorWithType:(ColorType)type
{
    UIColor *color;
    switch (type) {
        case COLOR_TYPE_NAVBAR_BG:
        {
            color = [UIColor colorWithRed:79/255.0f green:171/255.0f blue:167/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_DEFAULT_BG:
        {
            color = [UIColor colorWithRed:239/255.0f green:244/255.0f blue:244/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_LINK:
        {
            color = [UIColor darkGrayColor];
            break;
        }
        case COLOR_TYPE_TITLE_BG_BLUE:
        {
            color = [UIColor colorWithRed:91/255.0f green:181/255.0f blue:206/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_TITLE_BG_RED:
        {
            color = [UIColor colorWithRed:253/255.0f green:98/255.0f blue:94/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_TITLE_BG_GREEN:
        {
            color = [UIColor colorWithRed:136/255.0f green:186/255.0f blue:63/255.0f alpha:1.0f];
            break;
        }
        case COLOR_TYPE_TITLE_BG_YELLOW:
        {
            color = [UIColor colorWithRed:255/255.0f green:190/255.0f blue:21/255.0f alpha:1.0f];
            break;
        }
        default:
            break;
    }
    return color;
}

+ (UIColor *)colorWithHelpPage:(int)pageNo
{
    UIColor *color;
    switch (pageNo) {
        case 0:
        {
            // #e8b646
            color = [UIColor colorWithRed:232/255.0f green:182/255.0f blue:70/255.0f alpha:1.0f];
            break;
        }
        case 1:
        {
            // #ea794f
            color = [UIColor colorWithRed:234/255.0f green:121/255.0f blue:79/255.0f alpha:1.0f];
            break;
        }
        case 2:
        {
            // #de5360
            color = [UIColor colorWithRed:222/255.0f green:83/255.0f blue:96/255.0f alpha:1.0f];
            break;
        }
        case 3:
        {
            // #b7c45a
            color = [UIColor colorWithRed:183/255.0f green:196/255.0f blue:90/255.0f alpha:1.0f];
            break;
        }
        case 4:
        {
            // #52b66b
            color = [UIColor colorWithRed:82/255.0f green:182/255.0f blue:107/255.0f alpha:1.0f];
            break;
        }
        case 5:
        {
            // #54b6d0
            color = [UIColor colorWithRed:84/255.0f green:182/255.0f blue:208/255.0f alpha:1.0f];
            break;
        }
        case 6:
        {
            // #b491c1
            color = [UIColor colorWithRed:180/255.0f green:145/255.0f blue:193/255.0f alpha:1.0f];
            break;
        }
        default:
            break;
    }
    return color;
}

+ (NSString *)getCurrentLang {
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([language containsString:@"zh-Hant"]) {
        return @"zh";
    } else if ([language containsString:@"zh-Hans"]) {
        return @"zh-CN";
    }
    return @"en";
}

+ (IconResolution)getIconResolution {
    if (IS_IPHONE_4_OR_LESS) {
        return ICON_RES_1x;
    } else if (IS_IPHONE_5 || IS_IPHONE_6) {
        return ICON_RES_2x;
    } else if (IS_IPHONE_6P) {
        return ICON_RES_3x;
    }
    return ICON_RES_1_5x;
}

+ (NSString *)convertIpAddressToString:(NSData *)data {
    // Copy data to a "sockaddr_storage" structure.
    struct sockaddr_storage sa;
    socklen_t salen = sizeof(sa);
    [data getBytes:&sa length:salen];
    
    // Get host from socket address as C string:
    char host[NI_MAXHOST];
    getnameinfo((struct sockaddr *)&sa, salen, host, sizeof(host), NULL, 0, NI_NUMERICHOST);
    
    // Convert C string to NSString:
    NSString *ipAddress = [[NSString alloc] initWithBytes:host length:strlen(host) encoding:NSUTF8StringEncoding];
    return ipAddress;
}

@end
