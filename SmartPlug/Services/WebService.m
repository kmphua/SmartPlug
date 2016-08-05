//
//  WebService.m
//  FarGlory
//
//  Created by Kevin Phua on 9/4/15.
//  Copyright (c) 2015 hagarsoft. All rights reserved.
//

#import "WebService.h"
#import "UIWaitingView.h"

#define UPLOAD_IMAGE_QUALITY                0.6
#define UPLOAD_IMAGE_SCALE                  0.25

@interface WebService () <WebServiceDelegate>

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

- (void)postImageData:(NSString *)serverUrl params:(NSString *)params image:(UIImage *)image
{
    NSString *requestUrl = [NSString stringWithFormat:@"%@?%@", serverUrl, params];
    NSString *encodedUrl = [requestUrl stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:encodedUrl]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:20.0];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    
    // Set Content-Type in HTTP header
    NSString *boundary = @"---------------------------SmartPlug_14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // post body
    NSMutableData *body = [NSMutableData new];
    
    // add image data
    CGSize uploadImageSize;
    uploadImageSize.width = image.size.width * UPLOAD_IMAGE_SCALE;
    uploadImageSize.height = image.size.height * UPLOAD_IMAGE_SCALE;
    
    UIImage *uploadImage = [UIImage imageWithCGImage:image.CGImage scale:UPLOAD_IMAGE_SCALE orientation:image.imageOrientation];
    NSData *imageData = UIImageJPEGRepresentation(uploadImage, UPLOAD_IMAGE_QUALITY);
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", @"test"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%ld", (unsigned long)[body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
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
    [self.delegate connectFail:self.resultName webservice:self];
    [self performSelectorOnMainThread:@selector(dismissWaitingView) withObject:nil waitUntilDone:NO];
    NSLog(@"Error %@",error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"DONE. Received Bytes: %lu", (unsigned long)[self.webData length]);
    
    [self performSelectorOnMainThread:@selector(dismissWaitingView) withObject:nil waitUntilDone:NO];
    
    if (self.delegate != nil) {
        [self.delegate didReceiveData:self.webData resultName:self.resultName webservice:self];
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

- (void)changePassword:(NSString *)userToken lang:(NSString *)lang password:(NSString *)password newPassword:(NSString *)newPassword
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_CHANGE_PWD];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&pwd=%@&newpwd=%@", userToken, lang, password, newPassword];
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
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)devCtrl:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId send:(int)send data:(NSData *)data
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_CTRL];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&send=%d", userToken, lang, devId, send];
    self.resultName = WS_DEV_CTRL;
    self.devId = devId;
    
    NSLog(@"Send devctrl: %@", [Global hexStringFromData:data]);    
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
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)devSet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId icon:(NSString *)icon title:(NSString *)title notifyPower:(NSString *)notifyPower notifyTimer:(NSString *)notifyTimer notifyDanger:(NSString *)notifyDanger
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&icon=%@&title=%@&notify_power=%@&notify_timer=%@&notify_danger=%@&send=1", userToken, lang, devId, icon, title, notifyPower, notifyTimer, notifyDanger];
    self.resultName = WS_DEV_SET;
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)devSet2:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId model:(NSString *)model buildNumber:(int)buildNumber protocol:(int)protocol hardware:(NSString *)hardware firmware:(NSString *)firmware firmwareDate:(int)firmwareDate
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&model=%@&buildnumber=%d&protocol=%d&hardware=%@&firmware=%@&firmwaredate=%d&send=1", userToken, lang, devId, model, buildNumber, protocol, hardware, firmware, firmwareDate];
    self.resultName = WS_DEV_SET;
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)uploadImage:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId image:(UIImage *)image notifyPower:(NSString *)notifyPower notifyTimer:(NSString *)notifyTimer notifyDanger:(NSString *)notifyDanger
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&icon=upload&notify_power=%@&notify_timer=%@&notify_danger=%@&send=1", userToken, lang, devId, notifyPower, notifyTimer, notifyDanger];
    self.resultName = WS_DEV_SET;
    self.devId = devId;
    [self postImageData:apiUrl params:params image:image];
}

- (void)devLog:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_LOG];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@", userToken, lang, devId];
    self.resultName = WS_DEV_LOG;
    self.devId = devId;
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
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)devDel:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_DEL];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@", userToken, lang, devId];
    self.resultName = WS_DEV_DEL;
    self.devId = devId;
    [self postData:apiUrl params:params];
}

/*=========================================================================
 * Timer methods
 *========================================================================*/

- (void)alarmDel:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_ALARM_DEL];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@", userToken, lang, devId];
    self.resultName = WS_ALARM_DEL;
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)alarmGet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId
{
    self.devId = devId;
    
    if( self.delegate==nil) {
        self.delegate = self;
    }
    
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_ALARM_GET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@", userToken, lang, devId];
    self.resultName = WS_ALARM_GET;
    [self postData:apiUrl params:params];
}

- (void)setTimerDelay:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId send:(int)send data:(NSData *)data
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_CTRL];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&send=%d", userToken, lang, devId, send];
    self.resultName = WS_DEV_CTRL;
    self.devId = devId;
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
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_IR_LIST];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&brand=%d", userToken, lang, brand];
    self.resultName = WS_MODEL_LIST;
    [self postData:apiUrl params:params];
}

- (void)modelDetails:(NSString *)userToken lang:(NSString *)lang model:(int)model
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_IR_LIST];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&model=%d", userToken, lang, model];
    self.resultName = WS_MODEL_DETAILS;
    [self postData:apiUrl params:params];    
}

- (void)devIrGet:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId iconRes:(IconResolution)iconRes
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_GET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&serviceid=%d&res=%d", userToken, lang, devId, serviceId, iconRes];
    self.resultName = WS_DEV_IR_GET;
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)devIrSetGroup:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId action:(NSString *)action groupId:(int)groupId name:(NSString *)name icon:(int)icon iconRes:(IconResolution)iconRes
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&serviceid=%d&type=group&action=%@&groupid=%d&name=%@&icon=%d&res=%d", userToken, lang, devId, serviceId, action, groupId, name, icon, iconRes];
    self.resultName = WS_DEV_IR_SET;
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)devIrSetButtons:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId action:(NSString *)action groupId:(int)groupId buttonId:(int)buttonId name:(NSString *)name icon:(int)icon code:(int)code iconRes:(IconResolution)iconRes
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&serviceid=%d&type=button&action=%@&groupid=%d&buttonid=%d&name=%@&icon=%d&code=%d&res=%d", userToken, lang, devId, serviceId, action, groupId, buttonId, name, icon, code, iconRes];
    self.resultName = WS_DEV_IR_SET;
    self.devId = devId;
    [self postData:apiUrl params:params];
}

- (void)irDetect:(NSString *)userToken lang:(NSString *)lang
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_IR_DETECT];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@", userToken, lang];
    self.resultName = WS_IR_DETECT;
    [self postData:apiUrl params:params];
}

- (void)uploadIrImageGroup:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId action:(NSString *)action groupId:(int)groupId name:(NSString *)name iconRes:(IconResolution)iconRes image:(UIImage *)image
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&serviceid=%d&type=group&action=%@&groupid=%d&name=%@&icon=upload&res=%d", userToken, lang, devId, serviceId, action, groupId, name, iconRes];
    self.resultName = WS_DEV_IR_SET;
    self.devId = devId;
    [self postImageData:apiUrl params:params image:image];
}

- (void)uploadIrImageButton:(NSString *)userToken lang:(NSString *)lang devId:(NSString *)devId serviceId:(int)serviceId action:(NSString *)action groupId:(int)groupId buttonId:(int)buttonId name:(NSString *)name iconRes:(IconResolution)iconRes image:(UIImage *)image
{
    NSString *apiUrl = [NSString stringWithFormat:@"%@%@", SERVER_URL, WS_DEV_IR_SET];
    NSString *params = [NSString stringWithFormat:@"token=%@&hl=%@&devid=%@&serviceid=%d&type=group&action=%@&groupid=%d&buttonid=%d&name=%@&icon=upload&res=%d", userToken, lang, devId, serviceId, action, groupId, buttonId, name, iconRes];
    self.resultName = WS_DEV_IR_SET;
    self.devId = devId;
    [self postImageData:apiUrl params:params image:image];
}

#pragma mark - WebServiceDelegate

- (void)handleUpdateAlarm:(NSData *)data {
    NSMutableArray *alarms = [NSMutableArray array];
    if(![[SQLHelper getInstance] removeAlarms:_devId]) {
        NSLog(@"ALARM WAS NOT ABLE TO BE REMOVED WITH DEVID: %@", _devId);
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:_devId forKey:@"macId"];

    if (!data || data.length == 0) {
        NSLog(@"NULL alarm data!!!");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_ALARM_SERVICE_DONE object:nil userInfo:userInfo];
        return;
    }
    
    uint8_t array[512];
    memset(array, 0, 512);
    //I need to delete all the alarms
    [data getBytes:array length:data.length];
    
    for (int i = 0; i < data.length ; i+=12) {
        int serviceId = [Global process_long:array[i] b:array[i+1] c:array[i+2] d:array[i+3]];
        
        if(serviceId != 0) {
            Alarm *a = [Alarm new];
            a.device_id = _devId;
            if(serviceId == RELAY_SERVICE) {
                a.service_id = RELAY_SERVICE;
            } else if(serviceId == NIGHTLED_SERVICE){
                a.service_id = NIGHTLED_SERVICE;
            } else if(serviceId == IR_SERVICE){
                a.service_id = IR_SERVICE;
            }
            
            NSLog(@"SERVICE FROM SERVER: %d", a.service_id);
            
            a.init_ir = array[i + 5];
            a.end_ir = array[i + 6];
            a.dow = array[i + 7];
            a.initial_hour = array[i + 8];
            a.initial_minute = array[i + 9];
            a.end_hour = array[i + 10];
            a.end_minute = array[i + 11];
            NSLog(@"ALARM GET CONTROL - Service Id: %d, DOW: %d, Init Hour: %d, Init Minute: %d, End Hour: %d, End Minute: %d", a.service_id, a.dow, a.initial_hour, a.initial_minute, a.end_hour, a.end_minute);
            [alarms addObject:a];
        }
    }
    
    if (alarms.count > 0) {
        //[[SQLHelper getInstance] removeAlarms:_devId];
        for(int i = 0; i < alarms.count; i++){
            Alarm *a = [alarms objectAtIndex:i];
            if ([[SQLHelper getInstance] insertAlarm:a]) {
                //NSLog(@"ALARM INSERTED");
            } else {
                //NSLog(@"ALARM INSERTION FAILURE");
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_ALARM_SERVICE_DONE object:nil userInfo:userInfo];
}

- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName webservice:(WebService *)ws {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received data for %@: %@", resultName, dataString);
    
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        NSLog(@"Error received: %@", [error localizedDescription]);
    }
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *jsonArray = (NSArray *)jsonObject;
        NSLog(@"jsonArray - %@", jsonArray);
    } else {
        NSDictionary *jsonDict = (NSDictionary *)jsonObject;
        NSLog(@"jsonDict - %@", jsonDict);
        
        if ([resultName isEqualToString:WS_ALARM_GET]) {
            if (data) {
            [self handleUpdateAlarm:data];
            }
        }

    }
}

- (void)connectFail:(NSString*)resultName webservice: (WebService *)ws {
    NSLog(@"Connect fail for %@", resultName);
}


@end
