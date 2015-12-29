/*
 * File: CC3xAPManager.h
 * Copyright © 2013, Texas Instruments Incorporated - http://www.ti.com/
 * All rights reserved.
 */

#import <UIKit/UIKit.h>
#include <sys/socket.h>
#include <netdb.h>
#include <AssertMacros.h>
#import <CFNetwork/CFNetwork.h>
#include <netinet/in.h>
#include <errno.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

#import <SystemConfiguration/CaptiveNetwork.h>

typedef enum {
  
    CC3xSending = 1,
    CC3xStopped
}CC3xProcessStatus;


@interface CC3xAPManager : NSObject{
    
    CC3xProcessStatus _status;
}

+ (CC3xAPManager*)sharedInstance;

/*!!!!!!!!! return thr status of the process !!!!!!!!!*/
- (CC3xProcessStatus)processStatus;

/* Printing the address of pinged AP
 * @param destination address
 */
- (NSString *) displayAddressForAddress:(NSData *) address;

/*!!!!!!!!!!!!! retrieving the IP Address from the connected WiFi */
- (NSString *)getIPAddress ;

/*!!!!!!!!!!!! retriving the SSID of the connected network !!!!!!!!!!*/
- (NSString*)ssidForConnectedNetwork;
@end
