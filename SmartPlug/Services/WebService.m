//
//  WebService.m
//  FarGlory
//
//  Created by Kevin Phua on 9/4/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "WebService.h"
#import "UIWaitingView.h"

@interface WebService ()

@property (nonatomic, strong) NSMutableData *webData;
@property (nonatomic, strong) UIWaitingView *waitingView;
@property (nonatomic) NSString *resultName;

@end

@implementation WebService

@synthesize delegate;

- (id)init
{
	if (self = [super init]) {
		self.resultName = @"";
	}	
   
	return self;
}

- (void)postData:(NSString *)serverUrl params:(NSString *)params
{
    NSData *postData = [params dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverUrl]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setTimeoutInterval:20.0];
    [request setHTTPBody:postData];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (connection) {
        self.webData = [NSMutableData data];
    } else {
        NSLog(@"Connection is NULL");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.webData setLength: 0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"ERROR with theConenction");
    [self.delegate connectFail:self.resultName];
    [self performSelectorOnMainThread:@selector(dismissWaitingView) withObject:nil waitUntilDone:NO];
    NSLog(@"Error %@",error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"DONE. Received Bytes: %lu", (unsigned long)[self.webData length]);
    
    [self performSelectorOnMainThread:@selector(dismissWaitingView) withObject:nil waitUntilDone:NO];
    
    if (self.delegate != nil) {
        [self.delegate didReceiveData:self.webData resultName:self.resultName];
    }
}

- (void)showWaitingView:(UIView*)parentView
{
    self.waitingView = [[UIWaitingView alloc] init];
    [self.waitingView show:parentView];
}

- (void)dismissWaitingView
{
    if (self.waitingView) {
        [self.waitingView dismiss];
        self.waitingView = nil;
    }
}

#pragma mark - WebService functions

- (void)login:(NSString *)sid password:(NSString *)password
{
    self.resultName = WS_LOGIN;
    NSString *params = [NSString stringWithFormat:@"op=login&sId=%@&password=%@", sid, password];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)registerAccount:(NSString *)sid
{
    self.resultName = WS_REGISTER;
    NSString *params = [NSString stringWithFormat:@"op=register&sId=%@", sid];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)authenticate:(NSString *)sid authCode:(NSString *)authCode
{
    self.resultName = WS_AUTH;
    NSString *params = [NSString stringWithFormat:@"op=auth&sId=%@&auth_code=%@", sid, authCode];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)setPassword:(NSString *)vipId acckey:(NSString *)acckey password:(NSString *)password
{
    self.resultName = WS_SET_PASSWORD;
    NSString *params = [NSString stringWithFormat:@"op=set_pass&sId=%@&acckey=%@&password=%@", vipId, acckey, password];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)changePassword:(NSString *)vipId acckey:(NSString *)acckey
               oldpass:(NSString *)oldpass password:(NSString *)password
{
    self.resultName = WS_CHANGE_PASSWORD;
    NSString *params = [NSString stringWithFormat:@"op=pass_change&sId=%@&acckey=%@&opass=%@&password=%@", vipId, acckey, oldpass, password];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)registerDevice:(NSString *)acckey deviceId:(NSString *)deviceId
{
    self.resultName = WS_REGISTER_DEVICE;
    NSString *params = [NSString stringWithFormat:@"op=register_device&acckey=%@&ostype=ios&deviceid=%@", acckey, deviceId];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)getDepartment:(NSString *)acckey
{
    self.resultName = WS_GET_DEPARTMENT;
    NSString *params = [NSString stringWithFormat:@"op=get_department&acckey=%@", acckey];
    [self postData:PRODUCT_SERVER_URL params:params];
}

- (void)updateDepartment:(NSString *)data
{
    self.resultName = WS_UPDATE_DEPARTMENT;
    NSString *params = [NSString stringWithFormat:@"op=%@&data=%@", WS_UPDATE_DEPARTMENT, data];
    [self postData:PRODUCT_SERVER_URL params:params];
}

- (void)getProduct:(NSString *)acckey deptId:(NSString *)deptId
{
    self.resultName = WS_GET_PRODUCT;
    NSString *params = [NSString stringWithFormat:@"op=get_product&acckey=%@&dep_id=%@", acckey, deptId];
    [self postData:PRODUCT_SERVER_URL params:params];
}

- (void)updateProduct:(NSString *)data
{
    self.resultName = WS_UPDATE_PRODUCT;
    NSString *params = [NSString stringWithFormat:@"op=%@&data=%@", WS_UPDATE_PRODUCT, data];
    [self postData:PRODUCT_SERVER_URL params:params];
}

- (void)getFriendList:(NSString *)acckey
{
    self.resultName = WS_GET_FRIEND_LIST;
    NSString *params = [NSString stringWithFormat:@"op=get_friend_list&acckey=%@", acckey];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)inviteFriend:(NSString *)acckey fId:(NSString *)fId
{
    self.resultName = WS_INVITE_FRIEND;
    NSString *params = [NSString stringWithFormat:@"op=invite&acckey=%@&fId=%@", acckey, fId];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)friendAgree:(NSString *)acckey fId:(NSString *)fId
{
    self.resultName = WS_FRIEND_AGREE;
    NSString *params = [NSString stringWithFormat:@"op=friend_agree&acckey=%@&fId=%@", acckey, fId];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)friendDeny:(NSString *)acckey fId:(NSString *)fId
{
    self.resultName = WS_FRIEND_DENY;
    NSString *params = [NSString stringWithFormat:@"op=friend_deny&acckey=%@&fId=%@", acckey, fId];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)friendDelete:(NSString *)acckey fId:(NSString *)fId
{
    self.resultName = WS_FRIEND_DELETE;
    NSString *params = [NSString stringWithFormat:@"op=friend_delete&acckey=%@&fId=%@", acckey, fId];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)searchLastPointValue:(NSString *)acckey
{
    self.resultName = WS_SEARCH_LAST_POINT_VALUE;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@", WS_SEARCH_LAST_POINT_VALUE, acckey];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)vipPointMoveShop:(NSString *)acckey fId:(NSString *)fId point:(NSString *)point
{
    self.resultName = WS_VIP_POINT_MOVE_SHOP;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@&fId=%@&point=%@", WS_VIP_POINT_MOVE_SHOP, acckey, fId, point];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)getTicketList:(NSString *)acckey
{
    self.resultName = WS_GET_TICKET_LIST;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@", WS_GET_TICKET_LIST, acckey];
    [self postData:TICKET_SERVER_URL params:params];
    }

- (void)ticketGift:(NSString *)acckey fId:(NSString *)fId serno:(NSString *)serno tkno:(NSString *)tkno
{
    self.resultName = WS_TICKET_GIFT;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@&fId=%@&serno=%@&tkno=%@", WS_TICKET_GIFT, acckey, fId, serno, tkno];
    [self postData:TICKET_SERVER_URL params:params];
}

- (void)useTicket:(NSString *)acckey tkno:(NSString *)tkno
{
    self.resultName = WS_USE_TICKET;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@&tkno=%@", WS_USE_TICKET, acckey, tkno];
    [self postData:TICKET_SERVER_URL params:params];
}

- (void)receiveTicket:(NSString *)acckey tkno:(NSString *)tkno
{
    self.resultName = WS_RECEIVE_TICKET;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@&tkno=%@", WS_RECEIVE_TICKET, acckey, tkno];
    [self postData:TICKET_SERVER_URL params:params];
}

- (void)updateTicket:(NSString *)data
{
    self.resultName = WS_UPDATE_TICKET;
    NSString *params = [NSString stringWithFormat:@"op=%@&data=%@", WS_UPDATE_TICKET, data];
    [self postData:TICKET_SERVER_URL params:params];
}

- (void)updateTicketRule:(NSString *)data
{
    self.resultName = WS_UPDATE_TICKET_RULE;
    NSString *params = [NSString stringWithFormat:@"op=%@&data=%@", WS_UPDATE_TICKET_RULE, data];
    [self postData:TICKET_SERVER_URL params:params];
}

- (void)getVipBonusList:(NSString *)acckey
{
    self.resultName = WS_GET_VIP_BONUS_LIST;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@", WS_GET_VIP_BONUS_LIST, acckey];
    [self postData:MEMBER_SERVER_URL params:params];
}

- (void)getNews:(NSString *)acckey
{
    self.resultName = WS_GET_NEWS;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@", WS_GET_NEWS, acckey];
    [self postData:BASIC_SERVER_URL params:params];
}

- (void)getMessageList:(NSString *)acckey
{
    self.resultName = WS_GET_MESSAGE_LIST;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@&ostype=ios", WS_GET_MESSAGE_LIST, acckey];
    [self postData:BASIC_SERVER_URL params:params];
}

- (void)readMessage:(NSString *)acckey infoId:(NSString *)infoId
{
    self.resultName = WS_READ_MESSAGE;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@&infoid=%@", WS_READ_MESSAGE, acckey, infoId];
    [self postData:BASIC_SERVER_URL params:params];
}

- (void)getPageList:(NSString *)acckey
{
    self.resultName = WS_GET_PAGE_LIST;
    NSString *params = [NSString stringWithFormat:@"op=%@&acckey=%@", WS_GET_PAGE_LIST, acckey];
    [self postData:BASIC_SERVER_URL params:params];
}

@end
