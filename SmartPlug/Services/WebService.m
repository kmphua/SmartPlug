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
    NSString *requestUrl = [NSString stringWithFormat:@"%@?%@", serverUrl, params];
    NSString *encodedUrl = [requestUrl stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:encodedUrl]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:20.0];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (connection) {
        self.webData = [NSMutableData data];
    } else {
        NSLog(@"Connection is NULL");
    }
}

- (void)postDataWithBody:(NSString *)serverUrl params:(NSString *)params body:(NSData *)body
{
    NSString *requestUrl = [NSString stringWithFormat:@"%@?%@", serverUrl, params];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:20.0];
    [request setHTTPBody:body];
    
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

/*=========================================================================
 * User methods
 *========================================================================*/

- (void)longPoll:(NSString *)deviceId
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_LONG_POLL];
    NSString *params = [NSString stringWithFormat:@"id=%@", deviceId];
    self.resultName = WS_LONG_POLL;
    [self postData:apiUrl params:params];
}

- (void)newUser:(NSString *)username password:(NSString *)password email:(NSString *)email lang:(NSString *)lang
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_NEW_USER];
    NSString *params = [NSString stringWithFormat:@"user=%@&pwd=%@&email=%@&hl=%@", username, password, email, lang];
    self.resultName = WS_NEW_USER;
    [self postData:apiUrl params:params];
}

- (void)verifyAcct:(NSString *)username verificationKey:(NSString *)verificationKey lang:(NSString *)lang
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_VERIFY_ACCT];
    NSString *params = [NSString stringWithFormat:@"user=%@&vk=%@&hl=%@", username, verificationKey, lang];
    self.resultName = WS_VERIFY_ACCT;
    [self postData:apiUrl params:params];
}

- (void)login:(NSString *)username password:(NSString *)password lang:(NSString *)lang
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_LOGIN];
    NSString *params = [NSString stringWithFormat:@"user=%@&pwd=%@&hl=%@", username, password, lang];
    self.resultName = WS_LOGIN;
    [self postData:apiUrl params:params];
}

- (void)changePassword:(NSString *)userToken lang:(NSString *)lang newPassword:(NSString *)newPassword
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_CHANGE_PWD];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&newpwd=%@", userToken, lang, newPassword];
    self.resultName = WS_CHANGE_PWD;
    [self postData:apiUrl params:params];
}

- (void)regPush:(NSString *)userToken lang:(NSString *)lang devToken:(NSString *)devToken
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_REG_PUSH];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&type=%@&devtoken=%@", userToken, lang, @"i", devToken];
    self.resultName = WS_REG_PUSH;
    [self postData:apiUrl params:params];
}

/*=========================================================================
 * Device methods
 *========================================================================*/

- (void)actDev:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId title:(NSString *)title model:(NSString *)model
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_ACT_DEV];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&title=%@&model=%@", userToken, lang, devId, title, model];
    self.resultName = WS_ACT_DEV;
    [self postData:apiUrl params:params];
}

- (void)devCtrl:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId send:(int)send data:(NSData *)data
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_CTRL];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&send=%d", userToken, lang, devId, send];
    self.resultName = WS_DEV_CTRL;
    [self postDataWithBody:apiUrl params:params body:data];
}

- (void)devList:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_LIST];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&res=%d", userToken, lang, iconRes];
    self.resultName = WS_DEV_LIST;
    [self postData:apiUrl params:params];
}

- (void)devGet:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes devId:(NSString *)devId
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_GET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&res=%d&devid=%@", userToken, lang, iconRes, devId];
    self.resultName = WS_DEV_GET;
    [self postData:apiUrl params:params];
}

- (void)devSet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId icon:(NSString *)icon title:(NSString *)title notifyPower:(NSString *)notifyPower notifyTimer:(NSString *)notifyTimer notifyDanger:(NSString *)notifyDanger
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&icon=%@&title=%@&notify_power=%@&notify_timer=%@&notify_danger=%@", userToken, lang, devId, icon, title, notifyPower, notifyTimer, notifyDanger];
    self.resultName = WS_DEV_SET;
    [self postData:apiUrl params:params];
}

- (void)devLog:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_LOG];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@", userToken, lang, devId];
    self.resultName = WS_DEV_LOG;
    [self postData:apiUrl params:params];
}

- (void)galleryList:(NSString *)userToken lang:(NSString *)lang iconRes:(IconResolution)iconRes
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_GALLERY_LIST];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&res=%d", userToken, lang, iconRes];
    self.resultName = WS_GALLERY_LIST;
    [self postData:apiUrl params:params];
}

- (void)newDev:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId iconRes:(IconResolution)iconRes title:(NSString *)title notifyPower:(NSString *)notifyPower notifyTimer:(NSString *)notifyTimer notifyDanger:(NSString *)notifyDanger oriTitle:(NSString *)oriTitle ip:(NSString *)ip server:(NSString *)server snooze:(NSString *)snooze relay:(NSString *)relay
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_NEW_DEV];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&icon=%d&title=%@&notify_power=%@&notify_timer=%@&notify_danger=%@&orititle=%@&ip=%@&server=%@&snooze=%@&relay=%@", userToken, lang, devId,iconRes, title, notifyPower, notifyTimer, notifyDanger, oriTitle, ip, server, snooze, relay];
    self.resultName = WS_NEW_DEV;
    [self postData:apiUrl params:params];
}

- (void)devDel:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_DEL];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@", userToken, lang, devId];
    self.resultName = WS_DEV_DEL;
    [self postData:apiUrl params:params];
}

/*=========================================================================
 * Timer methods
 *========================================================================*/

- (void)setTimerDelay:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId data:(NSData *)data
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_CTRL];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@", userToken, lang, devId];
    self.resultName = WS_DEV_CTRL;
    [self postDataWithBody:apiUrl params:params body:data];
}

/*=========================================================================
 * IR methods
 *========================================================================*/

- (void)irList:(NSString *)userToken lang:(NSString *)lang
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_IR_LIST];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@", userToken, lang];
    self.resultName = WS_IR_LIST;
    [self postData:apiUrl params:params];
}

- (void)modelList:(NSString *)userToken lang:(NSString *)lang brand:(int)brand
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_MODEL_LIST];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&brand=%d", userToken, lang, brand];
    self.resultName = WS_MODEL_LIST;
    [self postData:apiUrl params:params];
}

- (void)modelDetails:(NSString *)userToken lang:(NSString *)lang model:(int)model res:(int)res
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_MODEL_DETAILS];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&model=%d&res=%d", userToken, lang, model, res];
    self.resultName = WS_MODEL_DETAILS;
    [self postData:apiUrl params:params];    
}

- (void)devIrGet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(NSString *)serviceId res:(int)res
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_GET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&serviceid=%@&res=%d", userToken, lang, devId, serviceId, res];
    self.resultName = WS_DEV_IR_GET;
    [self postData:apiUrl params:params];
}

- (void)devIrSetGroup:(NSString *)userToken lang:(NSString *)lang res:(int)res devId:(NSString *)devId serviceId:(NSString *)serviceId groupId:(NSString *)groupId name:(NSString *)name icon:(int)icon
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&res=%d&devid=%@&serviceid=%@&res=%d&type=group&action=add&groupid=%@&name=%@&icon=%d", userToken, lang, res, devId, serviceId, res, groupId, name, icon];
    self.resultName = WS_DEV_IR_SET;
    [self postData:apiUrl params:params];
}

- (void)devIrSetButtons:(NSString *)userToken lang:(NSString *)lang res:(int)res devId:(NSString *)devId serviceId:(NSString *)serviceId buttonId:(NSString *)buttonId name:(NSString *)name icon:(int)icon
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&res=%d&devid=%@&serviceid=%@&res=%d&type=group&action=add&buttonid=%@&name=%@&icon=%d&code=base64string", userToken, lang, res, devId, serviceId, res, buttonId, name, icon];
    self.resultName = WS_DEV_IR_SET;
    [self postData:apiUrl params:params];
}

@end
