/*
 * File: CC3xAPManager.m
 * Copyright © 2013, Texas Instruments Incorporated - http://www.ti.com/
 * All rights reserved.
 */

#import "CC3xAPManager.h"


static CC3xAPManager *_shared = Nil;
@implementation CC3xAPManager

#pragma mark * Utilities

/*!!!
 Returns a dotted decimal string for the specified address (a (struct sockaddr) 
 within the address NSData).
 @param: the address which is need to be convert
 */
- (NSString *) displayAddressForAddress:(NSData *) address
{
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];
    
    result = nil;
    
    if (address != nil) {
        err = getnameinfo([address bytes], (socklen_t) [address length], hostStr, sizeof(hostStr), NULL, 0, NI_DGRAM);
        if (err == 0) {
            result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
            assert(result != nil);
        }
    }
    
    return result;
}

#pragma mark - method

/*!!!!!!!!!! SIngleton Instance !!!!!!!!*/
+ (CC3xAPManager*)sharedInstance{
    if ( _shared == Nil ){
        _shared = [[CC3xAPManager alloc] init];
    }
    return _shared;
}

/*!!!!!!!!! 
    return the status of the process for sending the data
 !!!!!!!!!*/
- (CC3xProcessStatus)processStatus{
    return _status;
}

/*!!!!!!!!!!!!! 
retrieving the IP Address from the connected WiFi 
 @return value: the wifi address of currently connected wifi
 */
- (NSString *)getIPAddress {
    
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String for IP
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
//                    NSLog(@"subnet mask == %@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)]);
//                    
//                    NSLog(@"dest mask == %@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)]);
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free/release memory 
    freeifaddrs(interfaces);
    return address;
} 

/*!!!!!!!!!!!! 
 retriving the SSID of the connected network 
 @return value: the SSID of currently connected wifi
 '!!!!!!!!!!*/
- (NSString*)ssidForConnectedNetwork{
    
    NSArray *interfaces = (NSArray*)CNCopySupportedInterfaces();
    NSDictionary *info = nil;
    for (NSString *ifname in interfaces) {
        info = (NSDictionary*)CNCopyCurrentNetworkInfo((CFStringRef)ifname);
        if (info && [info count]) {
            break;
        }
        [info release];
        info = nil;
    }
    [interfaces release];
    
    NSLog(@"SSID == %@  info === %@",[info objectForKey:@"SSID"],info);
    
    NSString *ssid = nil;
    if ( info ){
        ssid = [[info objectForKey:@"SSID"] retain];//CFDictionaryGetValue((CFDictionaryRef)info, kCNNetworkInfoKeySSID);
        [info release];
    }
    return ssid ? [ssid autorelease]:@"";
}


@end
