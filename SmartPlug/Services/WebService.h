//
//  WebService.h
//  FarGlory
//
//  Created by Kevin Phua on 9/4/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SERVER_URL                  @"http://g-shines.com/api/"

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
#define WS_DEV_DEL                  @"devdel"

#define WS_ALARM_GET                @"alarmget"

#define WS_GALLERY_LIST             @"gallery"

#define WS_NEW_DEV                  @"newdev"

#define WS_IR_LIST                  @"irlist"
#define WS_MODEL_LIST               @"modellist"
#define WS_MODEL_DETAILS            @"modeldetails"
#define WS_DEV_IR_GET               @"devirget"
#define WS_DEV_IR_SET               @"devirset"
#define WS_IR_DETECT                @"irdetect"

#define IR_SET_ADD                  @"add"
#define IR_SET_MODIFY               @"mod"
#define IR_SET_DELETE               @"del"

@protocol WebServiceDelegate <NSObject>

@required
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName;
- (void)connectFail:(NSString *)resultName;

@end

@interface WebService : NSObject

@property (nonatomic, strong) id <WebServiceDelegate> delegate;

- (void)showWaitingView:(UIView*)parentView;
- (void)dismissWaitingView;

// User methods
- (void)longPoll:(NSString *)deviceId;
- (void)newUser:(NSString *)username password:(NSString *)password email:(NSString *)email lang:(NSString *)lang;
- (void)verifyAcct:(NSString *)username verificationKey:(NSString *)verificationKey lang:(NSString *)lang;
- (void)login:(NSString *)username password:(NSString *)password lang:(NSString *)lang;
- (void)changePassword:(NSString *)userToken lang:(NSString *)lang newPassword:(NSString *)newPassword;
- (void)regPush:(NSString *)userToken lang:(NSString *)lang devToken:(NSString *)devToken;

// Device methods
- (void)actDev:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId title:(NSString *)title model:(NSString *)model;
- (void)devCtrl:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId send:(int)send data:(NSData *)data;
- (void)devList:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes;
- (void)devGet:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes devId:(NSString *)devId;
- (void)devSet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId icon:(NSString *)icon title:(NSString *)title notifyPower:(NSString *)notifyPower notifyTimer:(NSString *)notifyTimer notifyDanger:(NSString *)notifyDanger;
- (void)devLog:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId;
- (void)galleryList:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes;

- (void)newDev:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId iconRes:(IconResolution)iconRes title:(NSString *)title notifyPower:(NSString *)notifyPower notifyTimer:(NSString *)notifyTimer notifyDanger:(NSString *)notifyDanger oriTitle:(NSString *)oriTitle ip:(NSString *)ip server:(NSString *)server snooze:(NSString *)snooze relay:(NSString *)relay;

- (void)devDel:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId;

// Timer methods
- (void)alarmGet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId;
- (void)setTimerDelay:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId send:(int)send data:(NSData *)data;

// IR methods
- (void)irList:(NSString *)userToken lang:(NSString *)lang;
- (void)modelList:(NSString *)userToken lang:(NSString *)lang brand:(int)brand;
- (void)modelDetails:(NSString *)userToken lang:(NSString *)lang model:(int)model;
- (void)devIrGet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId iconRes:(IconResolution)iconRes;
- (void)devIrSetGroup:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId action:(NSString *)action groupId:(int)groupId name:(NSString *)name icon:(int)icon iconRes:(IconResolution)iconRes;
- (void)devIrSetButtons:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId action:(NSString *)action groupId:(int)groupId buttonId:(int)buttonId name:(NSString *)name icon:(int)icon code:(int)code iconRes:(IconResolution)iconRes;
- (void)irDetect:(NSString *)userToken lang:(NSString *)lang;

@end

