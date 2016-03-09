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
#define ALARM_RELAY_SERVICE             0xD1000000
#define ALARM_NIGHTLED_SERVICE          0xD1000001

// UDP commands
#define UDP_CMD_DEVICE_QUERY            0x0001
#define UDP_CMD_DEVICE_ACTIVATION       0x0002
#define UDP_CMD_WIFI_SCAN               0x0003
#define UDP_CMD_WIFI_SCAN_STOP          0x0004
#define UDP_CMD_SET_WIFI_AP             0x0005
#define UDP_CMD_DEVICE_CAPABILITY       0x0006
#define UDP_CMD_GET_DEVICE_STATUS       0x0007
#define UDP_CMD_SET_DEVICE_STATUS       0x0008
#define UDP_CMD_SET_DEVICE_TIMERS       0x0009
#define UDP_CMD_GET_DEVICE_TIMERS       0x000A
#define UDP_CMD_DELAY_TIMER             0x000B
#define UDP_CMD_ADV_DEVICE_SETTINGS     0x000C

// UDP notifications
#define NOTIFICATION_DEVICE_INFO                @"device_info"
#define NOTIFICATION_SET_TIMER_DELAY            @"set_timer_delay"
#define NOTIFICATION_DEVICE_STATUS_CHANGED      @"device_status_changed"
#define NOTIFICATION_STATUS_CHANGED_UPDATE_UI   @"status_changed_update_ui"
#define NOTIFICATION_M1_UPDATE_UI               @"m1updateui"
#define NOTIFICATION_IR_FILENAME                @"ir_filename"
#define NOTIFICATION_MDNS_DEVICE_FOUND          @"mDNS_New_Device_Found"
#define NOTIFICATION_MDNS_DEVICE_REMOVED        @"mDNS_Device_Removed"

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
extern NSString *g_DeviceIp;
extern NSString *g_DeviceName;
extern NSString *g_DeviceMac;

// UDP command
extern int g_UdpCommand;

@interface Global : NSObject

+ (UIColor *)colorWithType:(ColorType)type;
+ (NSString *)getCurrentLang;
+ (IconResolution)getIconResolution;
+ (NSString *)convertIpAddressToString:(NSData *)data;

@end
