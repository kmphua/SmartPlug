//
//  AppDelegate.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/12/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "Global.h"
#import "WebService.h"
#import "MainViewController.h"
#import "UDPListenerService.h"
#import "mDNSService.h"
#import "HelpPageViewController.h"
#import "AddDeviceViewController.h"

@interface AppDelegate ()<WebServiceDelegate>

@property (nonatomic, strong) UDPListenerService *udpListener;
@property (nonatomic, strong) mDNSService *mDNSService;

@end

@implementation AppDelegate

BOOL g_IsLogin;
BOOL g_IsOnline;
NSString *g_Username;
NSString *g_Password;
NSString *g_UserToken;
NSString *g_DevToken;
NSArray *g_DeviceIcons;

NSString *g_DeviceIp;
NSString *g_DeviceName;
NSString *g_DeviceMac;

int g_UdpCommand;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSLog(@"Device name = %@", [[UIDevice currentDevice] name]);
    
    // Init database
    [SQLHelper getInstance];
    
    // Init push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window = window;
    
    // Customize navigation bar
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[Global colorWithType:COLOR_TYPE_NAVBAR_BG]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    // Customize status bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];

    // Show initial view
    UINavigationController *navigationController;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    BOOL isFirstUse = [ud boolForKey:UD_KEY_FIRST_USE];
    NSString *userToken = [ud stringForKey:UD_USER_TOKEN];
    
    // Start UDP listener service
    _udpListener = [UDPListenerService getInstance];
    [_udpListener startUdpBroadcastListener];
    
    // Start mDNS service
    _mDNSService = [mDNSService getInstance];
    [_mDNSService startBrowsing];
    
    // Clear push badge
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    if (!isFirstUse) {
        HelpPageViewController *helpPageController = [[HelpPageViewController alloc] initWithNibName:@"HelpPageViewController" bundle:nil];
        helpPageController.startIndex = 0;
        navigationController = [[UINavigationController alloc] initWithRootViewController:helpPageController];

    } else if (userToken && userToken.length>0) {
        g_UserToken = userToken;
        
        // Jump to add main page
        MainViewController *mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
        
        navigationController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    } else {
        LoginViewController *loginController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        navigationController = [[UINavigationController alloc] initWithRootViewController:loginController];
    }
    
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [_udpListener stopUdpBroadcastListener];
    [_mDNSService stopBrowsing];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [_udpListener startUdpBroadcastListener];
    [_mDNSService startBrowsing];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString * deviceTokenString = [[[[deviceToken description]
                                      stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                     stringByReplacingOccurrencesOfString: @">" withString: @""]
                                    stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    NSLog(@"Device token = %@", deviceTokenString);
    g_DevToken = deviceTokenString;
    [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:UD_DEVICE_TOKEN];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Register push
    WebService *ws = [WebService new];
    ws.delegate = self;
    [ws regPush:g_UserToken lang:[Global getCurrentLang] devToken:g_DevToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self handleRemoteNotification:userInfo];
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo
{
    if (userInfo) {
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        if (aps) {
            NSNumber *badge = [aps objectForKey:@"badge"];
            NSLog(@"Push badge = %ld", [badge integerValue]);
            
            // Send push notification
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PUSH
                                                                object:self
                                                              userInfo:userInfo];
        }
    }
}

//==================================================================
#pragma WebServiceDelegate
//==================================================================
- (void)didReceiveData:(NSData *)data resultName:(NSString *)resultName {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Received data for %@: %@", resultName, dataString);
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *jsonArray = (NSArray *)jsonObject;
        NSLog(@"jsonArray - %@", jsonArray);
    } else {
        NSDictionary *jsonDict = (NSDictionary *)jsonObject;
        NSLog(@"jsonDict - %@", jsonDict);
        
        if ([resultName isEqualToString:WS_REG_PUSH]) {
            long result = [[jsonObject objectForKey:@"r"] longValue];
            if (result == 0) {
                // Success
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Register push success! %@", message);
            } else {
                NSString *message = (NSString *)[jsonObject objectForKey:@"m"];
                NSLog(@"Register push failed! %@", message);
            }
        } 
    }
}

- (void)connectFail:(NSString*)resultName {
    NSLog(@"Connect fail for %@", resultName);
}

@end
