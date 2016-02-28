//
//  Global.h
//  SmartPlug
//
//  Created by Kevin Phua on 9/16/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define CORNER_RADIUS                   12

#define SERVICE_TYPE                    @"_http._tcp."
#define SMARTCONFIG_IDENTIFIER          @"JSPlug"
#define SMARTCONFIG_BROADCAST_TIME      10  // seconds

// User defaults
#define UD_KEY_PHONE                    @"phone"
#define UD_KEY_PASSWORD                 @"password"
#define UD_KEY_LAST_LOGIN               @"last_login"
#define UD_USER_TOKEN                   @"user_token"
#define UD_DEVICE_TOKEN                 @"device_token"

// Services
#define ALARM_RELAY_SERVICE             0x1D000000
#define ALARM_NIGHTLED_SERVICE          0x1D000001

typedef enum {
    COLOR_TYPE_NAVBAR_BG,
    COLOR_TYPE_DEFAULT_BG,
    COLOR_TYPE_LINK,
    COLOR_TYPE_TITLE_BG_BLUE,
    COLOR_TYPE_TITLE_BG_GREEN,
    COLOR_TYPE_TITLE_BG_RED,
    COLOR_TYPE_TITLE_BG_YELLOW
} ColorType;

typedef enum {
    ICON_RES_1x = 0,
    ICON_RES_1_5x,
    ICON_RES_2x,
    ICON_RES_3x,
    ICON_RES_4x
} IconResolution;

extern BOOL g_IsLogin;
extern BOOL g_IsOnline;
extern NSString *g_Username;
extern NSString *g_Password;
extern NSString *g_UserToken;
extern NSString *g_DevToken;
extern NSArray *g_DeviceIcons;

// Current device
extern NSString *g_DeviceId;
extern NSString *g_DeviceIp;
extern NSString *g_DeviceName;
extern NSString *g_DeviceGivenName;
extern NSString *g_DeviceMac;

@interface Global : NSObject

+ (UIColor *)colorWithType:(ColorType)type;
+ (NSString *)getCurrentLang;
+ (IconResolution)getIconResolution;
+ (NSString *)convertIpAddressToString:(NSData *)data;

@end
