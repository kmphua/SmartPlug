//
//  Global.h
//  SmartPlug
//
//  Created by Kevin Phua on 9/16/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CORNER_RADIUS       12

// User defaults
#define UD_KEY_PHONE                  @"phone"
#define UD_KEY_PASSWORD               @"password"
#define UD_KEY_LAST_LOGIN             @"last_login"
#define UD_USER_TOKEN                 @"user_token"
#define UD_DEVICE_TOKEN               @"device_token"

typedef enum {
    COLOR_TYPE_NAVBAR_BG,
    COLOR_TYPE_DEFAULT_BG,
    COLOR_TYPE_LINK,
    COLOR_TYPE_TITLE_BG_BLUE,
    COLOR_TYPE_TITLE_BG_GREEN,
    COLOR_TYPE_TITLE_BG_RED,
    COLOR_TYPE_TITLE_BG_YELLOW
} ColorType;

extern BOOL g_IsLogin;
extern BOOL g_IsOnline;
extern NSString *g_Username;
extern NSString *g_Password;
extern NSString *g_UserToken;
extern NSString *g_DevToken;
extern NSMutableDictionary *g_AppInfo;

@interface Global : NSObject

+ (UIColor *)colorWithType:(ColorType)type;
+ (CGImageRef)createQRImageForString:(NSString *)string size:(CGSize)size;
+ (NSString *)getCurrentLang;

@end
