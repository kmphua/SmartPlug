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
#define SMARTCONFIG_BROADCAST_TIME      30  // seconds

#define DEFAULT_ICON_PATH               @"http://flutehuang-001-site2.ctempurl.com/Images/see_Electric_ight_1_white_bkgnd.png"
#define DEFAULT_IR_ICON_PATH            @"http://rgbetanco.com/jiEE/icons/btn_power_pressed.png"

// User defaults
#define UD_KEY_PHONE                    @"phone"
#define UD_KEY_PASSWORD                 @"password"
#define UD_KEY_LAST_LOGIN               @"last_login"
#define UD_USER_TOKEN                   @"user_token"
#define UD_DEVICE_TOKEN                 @"device_token"
#define UD_KEY_FIRST_USE                @"first_use"

// Services
#define RELAY_SERVICE                   0xD1000000
#define NIGHTLED_SERVICE                0xD1000001
#define CO_SERVICE                      0xD1000002
#define IR_SERVICE                      0xD1000003

#define SERVICE_FLAGS_NORMAL            0x00000000       // not problems reported by service
#define SERVICE_FLAGS_ERROR             0x00000001       // service is in error
#define SERVICE_FLAGS_WARNING           0x00000002       // service has warning
#define SERVICE_FLAGS_DISABLED          0x00000004

// Protocol
#define PROTOCOL_HTTP                   0
#define PROTOCOL_UDP                    1

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
#define NOTIFICATION_DEVICE_STATUS_SET          @"device_status_set"
#define NOTIFICATION_STATUS_CHANGED_UPDATE_UI   @"status_changed_update_ui"
#define NOTIFICATION_M1_UPDATE_UI               @"m1updateui"
#define NOTIFICATION_IR_FILENAME                @"ir_filename"
#define NOTIFICATION_MDNS_DEVICE_FOUND          @"mDNS_New_Device_Found"
#define NOTIFICATION_MDNS_DEVICE_REMOVED        @"mDNS_Device_Removed"
#define NOTIFICATION_PUSH                       @"push_notification"
#define NOTIFICATION_TIMERS_SENT_SUCCESS        @"timers_sent_successfully"
#define NOTIFICATION_HTTP_DEVICE_STATUS         @"http_device_status"
#define NOTIFICATION_TIMER_CRASH_REACHED        @"timer_crash_reached"
#define NOTIFICATION_ALARM_LIST_CHANGED         @"alarm_list_changed"
#define NOTIFICATION_DEVICE_NOT_REACHED         @"device_not_reached"
#define NOTIFICATION_REPEATING_TASK_DONE        @"repeating_task_done"
#define NOTIFICATION_OTA_SENT                   @"ota_sent"
#define NOTIFICATION_DELETE_SENT                @"delete_sent"
#define NOTIFICATION_OTA_FINISHED               @"ota_finished"
#define NOTIFICATION_UPDATE_ALARM_SERVICE_DONE  @"updateAlarmServiceDone"
#define NOTIFICATION_ADAPTER_ON_CLICK           @"adapaterOnClick"
#define NOTIFICATION_BROADCASTED_PRESENCE       @"broadcasted_presence"

typedef enum {
    COLOR_TYPE_NAVBAR_BG,
    COLOR_TYPE_DEFAULT_BG,
    COLOR_TYPE_LINK,
    COLOR_TYPE_TITLE_BG_BLUE,
    COLOR_TYPE_TITLE_BG_GREEN,
    COLOR_TYPE_TITLE_BG_RED,
    COLOR_TYPE_TITLE_BG_YELLOW,
    COLOR_TYPE_ICON_BG
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

@interface Global : NSObject

+ (BOOL)isNetworkReady;
+ (UIColor *)colorWithType:(ColorType)type;
+ (UIColor *)colorWithHelpPage:(int)pageNo;
+ (NSString *)getCurrentLang;
+ (IconResolution)getIconResolution;
+ (NSString *)convertIpAddressToString:(NSData *)data;
+ (NSString *)hexStringFromData:(NSData *)data;
+ (int)process_long:(uint8_t)a b:(uint8_t)b c:(uint8_t)c d:(uint8_t)d;
+ (short)process_short:(uint8_t)a b:(uint8_t)b;
+ (UIImage *)squareCropImageToSideLength:(UIImage *)sourceImage sideLength:(CGFloat)sideLength;

@end
