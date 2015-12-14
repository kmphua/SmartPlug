//
//  WebService.h
//  FarGlory
//
//  Created by Kevin Phua on 9/4/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

#define MEMBER_SERVER_URL           @"http://posapp.hihost.com.tw/webservice/member/"
#define PRODUCT_SERVER_URL          @"http://posapp.hihost.com.tw/webservice/product/"
#define BASIC_SERVER_URL            @"http://posapp.hihost.com.tw/webservice/basic/"
#define TICKET_SERVER_URL           @"http://posapp.hihost.com.tw/webservice/ticket/"

#define PRODUCT_IMAGE_PATH          @"http://posapp.hihost.com.tw/public/product00/"
#define NEWS_IMAGE_PATH             @"http://posapp.hihost.com.tw/public/newsinfo/"

#define WS_LOGIN                    @"login"
#define WS_REGISTER                 @"register"
#define WS_AUTH                     @"auth"
#define WS_SET_PASSWORD             @"set_pass"
#define WS_CHANGE_PASSWORD          @"pass_change"
#define WS_REGISTER_DEVICE          @"register_device"

#define WS_GET_DEPARTMENT           @"get_department"
#define WS_UPDATE_DEPARTMENT        @"update_department"
#define WS_GET_PRODUCT              @"get_product"
#define WS_UPDATE_PRODUCT           @"update_product"
#define WS_GET_FRIEND_LIST          @"get_friend_list"
#define WS_INVITE_FRIEND            @"invite"
#define WS_FRIEND_AGREE             @"friend_agree"
#define WS_FRIEND_DENY              @"friend_deny"
#define WS_FRIEND_DELETE            @"friend_delete"

#define WS_SEARCH_LAST_POINT_VALUE  @"SearchLastPointValue"
#define WS_VIP_POINT_MOVE_SHOP      @"VipPointMove_Shop"
#define WS_GET_TICKET_LIST          @"get_ticket_list"
#define WS_TICKET_GIFT              @"ticket_gift"
#define WS_USE_TICKET               @"use_ticket"
#define WS_RECEIVE_TICKET           @"receive_ticket"
#define WS_UPDATE_TICKET_RULE       @"update_ticket_rule"
#define WS_UPDATE_TICKET            @"update_ticket"
#define WS_GET_VIP_BONUS_LIST       @"GetVipBonusList"

#define WS_GET_NEWS                 @"get_news"
#define WS_GET_MESSAGE_LIST         @"get_message_list"
#define WS_READ_MESSAGE             @"read_message"
#define WS_GET_PAGE_LIST            @"get_page_list"

@protocol WebServiceDelegate <NSObject>

@required
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName;
- (void)connectFail:(NSString *)resultName;

@end

@interface WebService : NSObject

@property (nonatomic, strong) id <WebServiceDelegate> delegate;

- (void)showWaitingView:(UIView*)parentView;
- (void)dismissWaitingView;

- (void)login:(NSString *)sid password:(NSString *)password;
- (void)registerAccount:(NSString *)sid;
- (void)authenticate:(NSString *)sid authCode:(NSString *)authCode;
- (void)setPassword:(NSString *)vipId acckey:(NSString *)acckey password:(NSString *)password;
- (void)changePassword:(NSString *)vipId acckey:(NSString *)acckey
               oldpass:(NSString *)oldpass password:(NSString *)password;
- (void)registerDevice:(NSString *)acckey deviceId:(NSString *)deviceId;

- (void)getDepartment:(NSString *)acckey;
- (void)updateDepartment:(NSString *)data;
- (void)getProduct:(NSString *)acckey deptId:(NSString *)deptId;
- (void)updateProduct:(NSString *)data;

- (void)getFriendList:(NSString *)acckey;
- (void)inviteFriend:(NSString *)acckey fId:(NSString *)fId;
- (void)friendAgree:(NSString *)acckey fId:(NSString *)fId;
- (void)friendDeny:(NSString *)acckey fId:(NSString *)fId;
- (void)friendDelete:(NSString *)acckey fId:(NSString *)fId;

- (void)searchLastPointValue:(NSString *)acckey;
- (void)vipPointMoveShop:(NSString *)acckey fId:(NSString *)fId point:(NSString *)point;
- (void)getTicketList:(NSString *)acckey;
- (void)ticketGift:(NSString *)acckey fId:(NSString *)fId serno:(NSString *)serno tkno:(NSString *)tkno;
- (void)useTicket:(NSString *)acckey tkno:(NSString *)tkno;
- (void)receiveTicket:(NSString *)acckey tkno:(NSString *)tkno;
- (void)updateTicket:(NSString *)data;
- (void)updateTicketRule:(NSString *)data;
- (void)getVipBonusList:(NSString *)acckey;

- (void)getNews:(NSString *)acckey;
- (void)getMessageList:(NSString *)acckey;
- (void)readMessage:(NSString *)acckey infoId:(NSString *)infoId;
- (void)getPageList:(NSString *)acckey;

@end

