//
//  Global.h
//  PosApp
//
//  Created by Kevin Phua on 9/16/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LEFT_MENU_WIDTH               200
#define TABLEVIEW_CORNER_RADIUS       12

// User defaults
#define UD_KEY_PHONE                  @"phone"
#define UD_KEY_PASSWORD               @"password"
#define UD_KEY_LAST_LOGIN             @"last_login"
#define UD_DEVICE_TOKEN               @"device_token"

// Member info
#define INFO_KEY_VIPID                @"vip_id"
#define INFO_KEY_NAME                 @"name"
#define INFO_KEY_ZIP                  @"zip"
#define INFO_KEY_ADDRESS              @"address"
#define INFO_KEY_TELEPHONE            @"telephone"
#define INFO_KEY_SEX                  @"sex"
#define INFO_KEY_BIRTHDAY             @"birthday"
#define INFO_KEY_EMAIL                @"email"
#define INFO_KEY_MOBILE               @"mobile"
#define INFO_KEY_LAST_POINT           @"last_point"
#define INFO_KEY_LAST_AMT             @"last_amt"
#define INFO_KEY_LAST_IC_POINT        @"last_icpoint"
#define INFO_KEY_CARD                 @"card"
#define INFO_KEY_END_DATE             @"end_date"
#define INFO_KEY_ID_CARD              @"id_card"
#define INFO_KEY_ACCKEY               @"acckey"

typedef enum {
    COLOR_TYPE_TEXTBOX_BG,
    COLOR_TYPE_LINK,
    COLOR_TYPE_BUTTON_UP,
    COLOR_TYPE_BUTTON_DOWN,
    COLOR_TYPE_LIST_BG,
    COLOR_TYPE_BODY_BG
} ColorType;

extern BOOL g_IsLogin;
extern BOOL g_IsOnline;
extern NSString *g_MemberPhone;
extern NSString *g_MemberPassword;
extern NSMutableDictionary *g_MemberInfo;


@interface Global : NSObject

+ (UIColor *)colorWithType:(ColorType)type;
+ (CGImageRef)createQRImageForString:(NSString *)string size:(CGSize)size;

@end
