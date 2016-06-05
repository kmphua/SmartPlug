//
//  mDNSService.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/30/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "mDNSService.h"
#import "FirstTimeConfig.h"
#import "Reachability.h"
#import "JSmartPlug.h"
#import "UDPCommunication.h"
#include <arpa/inet.h>

#define SMARTCONFIG_IDENTIFIER      @"JSPlug"

@interface mDNSService()<NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (strong, nonatomic) NSMutableArray *services;
@property (strong, nonatomic) NSNetServiceBrowser *serviceBrowser;

@end

@implementation mDNSService

static mDNSService *instance;

+ (mDNSService *)getInstance
{
    @synchronized(self) {
        if (instance == nil)
            instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.services = [NSMutableArray new];
        self.plugs = [NSMutableArray new];
    }
    return self;
}

//==================================================================
#pragma mark - Bonjour service discovery
//==================================================================

- (void)startBrowsing {
    if (self.services) {
        [self.services removeAllObjects];
    } else {
        self.services = [NSMutableArray new];
    }
    
    // Initialize Service Browser
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    
    // Configure Service Browser
    [self.serviceBrowser setDelegate:self];
    [self.serviceBrowser searchForServicesOfType:SERVICE_TYPE inDomain:@"local."];
}

- (void)stopBrowsing {
    if (self.serviceBrowser) {
        [self.serviceBrowser stop];
        [self.serviceBrowser setDelegate:nil];
        [self setServiceBrowser:nil];
    }
    self.isSearching = NO;
}

// Error handling code
- (void)handleError:(NSNumber *)error {
    NSString *errorMsg = [NSString stringWithFormat:@"An error occurred.\nNSNetServicesErrorCode = %d", [error intValue]];
    // Handle error here
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)                                                                    message:errorMsg
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

//==================================================================
#pragma mark - NSNetServiceBrowserDelegate
//==================================================================

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser {
    self.isSearching = YES;
}

// Sent when browsing stops
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser {
    [self stopBrowsing];
}

// Sent if browsing fails
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary *)errorDict {
    [self stopBrowsing];
    self.isSearching = NO;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    NSLog(@"Found domain: %@", domainString);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services addObject:service];
    
    NSLog(@"Found service %@", service.name);

    // Resolve service
    [service setDelegate:self];
    [service resolveWithTimeout:30.0];

    // Sort Services
    [self.services sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    
    if (!moreComing) {
        //[self stopBrowsing];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services removeObject:service];
    
    NSLog(@"Removed service %@", service.name);
    
    if ([service.name containsString:SMARTCONFIG_IDENTIFIER]) {
        [self.plugs removeAllObjects];

        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MDNS_DEVICE_REMOVED
                                                            object:self
                                                          userInfo:nil];
    }
    
    if (!moreComing) {
        [self stopBrowsing];
    }
}

//==================================================================
#pragma mark - NSNetServiceDelegate
//==================================================================

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    
    if ([service.name containsString:SMARTCONFIG_IDENTIFIER]) {
        NSString *serviceIp = [self getNetServiceAddress:service.addresses];
        if (serviceIp) {
            NSLog(@"Resolved address for service %@, ip %@", service.name, serviceIp);
            
            // Add new plug
            BOOL addPlug = YES;
            for (JSmartPlug *plug in self.plugs) {
                // Check if plug exists
                if ([plug.name isEqualToString:service.name]) {
                    addPlug = NO;
                    break;
                }
            }
            
            if (addPlug) {
                JSmartPlug *newPlug = [JSmartPlug new];
                newPlug.name = service.name;
                newPlug.server = service.hostName;
                newPlug.ip = serviceIp;
                
                [self.plugs addObject:newPlug];
                
                NSLog(@"New device added");
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          newPlug.name, @"name",
                                          newPlug.ip, @"ip",
                                          nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MDNS_DEVICE_FOUND
                                                                    object:self
                                                                  userInfo:userInfo];
            } else {
                NSLog(@"Device already in the list");
            }
        }
    }
}

- (void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
    [service setDelegate:nil];
}

- (NSString *)getNetServiceAddress:(NSArray *)addresses
{
    NSData *myData = nil;
    if (!addresses || addresses.count == 0) {
        return nil;
    }
    myData = [addresses objectAtIndex:0];
    
    NSString *addressString;
    int port=0;
    struct sockaddr *addressGeneric;
    //struct sockaddr_in addressClient;
    
    addressGeneric = (struct sockaddr *) [myData bytes];
    
    switch ( addressGeneric->sa_family ) {
        case AF_INET:
            {
                struct sockaddr_in *ip4;
                char dest[INET_ADDRSTRLEN];
                ip4 = (struct sockaddr_in *) [myData bytes];
                port = ntohs(ip4->sin_port);
                addressString = [NSString stringWithFormat:@"%s", inet_ntop(AF_INET, &ip4->sin_addr, dest, sizeof dest)];
                //addressString = [NSString stringWithFormat: @"IP4: %s Port: %d", inet_ntop(AF_INET, &ip4->sin_addr, dest, sizeof dest),port];
            }
            break;
            
        case AF_INET6:
            {
                struct sockaddr_in6 *ip6;
                char dest[INET6_ADDRSTRLEN];
                ip6 = (struct sockaddr_in6 *) [myData bytes];
                port = ntohs(ip6->sin6_port);
                addressString = [NSString stringWithFormat:@"%s", inet_ntop(AF_INET6, &ip6->sin6_addr, dest, sizeof dest)];
                //addressString = [NSString stringWithFormat: @"IP6: %s Port: %d",  inet_ntop(AF_INET6, &ip6->sin6_addr, dest, sizeof dest),port];
            }
            break;

        default:
            addressString = nil;
            break;
    }
    
    return addressString;
}

@end
