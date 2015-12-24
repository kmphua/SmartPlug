//
//  WebService.h
//  FarGlory
//
//  Created by Kevin Phua on 9/4/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SERVER_URL                  @"http://182.234.253.236:7001/api/"

#define WS_LONG_POLL                @"longpoll"

#define WS_NEW_USER                 @"newuser"
#define WS_VERIFY_ACCT              @"verifyacct"
#define WS_LOGIN                    @"login"
#define WS_CHANGE_PWD               @"changepwd"
#define WS_REG_PUSH                 @"regpush"
#define WS_ACT_DEV                  @"actdev"

#define WS_DEV_CTRL                 @"devctrl"
#define WS_DEV_LIST                 @"devlist"
#define WS_DEV_GET                  @"devget"
#define WS_DEV_SET                  @"devset"
#define WS_DEV_LOG                  @"devlog"

#define WS_GALLERY_LIST             @"gallery"

typedef enum {
    ICON_RES_1x = 0,
    ICON_RES_1_5x,
    ICON_RES_2x,
    ICON_RES_3x,
    ICON_RES_4x
} IconResolution;

@protocol WebServiceDelegate <NSObject>

@required
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName;
- (void)connectFail:(NSString *)resultName;

@end

@interface WebService : NSObject

@property (nonatomic, strong) id <WebServiceDelegate> delegate;

- (void)showWaitingView:(UIView*)parentView;
- (void)dismissWaitingView;

- (void)longPoll:(NSString *)deviceId;

- (void)newUser:(NSString *)username password:(NSString *)password email:(NSString *)email lang:(NSString *)lang;
- (void)verifyAcct:(NSString *)username verificationKey:(NSString *)verificationKey lang:(NSString *)lang;
- (void)login:(NSString *)username password:(NSString *)password lang:(NSString *)lang;
- (void)changePassword:(NSString *)username oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword lang:(NSString *)lang;
- (void)regPush:(NSString *)userToken lang:(NSString *)lang devToken:(NSString *)devToken;
- (void)actDev:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId;

- (void)devCtrl:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId isReply:(BOOL)isReply;
- (void)devList:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes;
- (void)devGet:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes;
- (void)devSet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId icon:(NSString *)icon title:(NSString *)title notifyPower:(NSString *)notifyPower notifyTimer:(NSString *)notifyTimer notifyDanger:(NSString *)notifyDanger;
- (void)devLog:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId;
- (void)galleryList:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes;

@end

