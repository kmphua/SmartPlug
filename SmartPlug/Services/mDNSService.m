//
//  mDNSService.m
//  SmartPlug
//
//  Created by Kevin Phua on 12/30/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import "mDNSService.h"
#import "JSmartPlug.h"
#import "UDPCommunication.h"

#define SERVICE_TYPE                    @"_http._tcp."
#define SMARTCONFIG_IDENTIFIER          @"JSPlug"

@interface mDNSService() <NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (strong, nonatomic) NSMutableArray *services;
@property (strong, nonatomic) NSMutableArray *plugs;
@property (strong, nonatomic) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic) BOOL searching;

@property (strong, nonatomic) UDPCommunication *udp;
@property (strong, nonatomic) GCDAsyncSocket *socket;

@end


@implementation mDNSService


//==================================================================
#pragma mark - Bonjour service discovery
//==================================================================

- (void)startBrowsing {
    if (self.services) {
        [self.services removeAllObjects];
    } else {
        self.services = [NSMutableArray new];
    }
    
    if (self.plugs) {
        [self.plugs removeAllObjects];
    } else {
        self.plugs = [NSMutableArray new];
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
    self.searching = NO;
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
    self.searching = YES;
}

// Sent when browsing stops
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser {
    [self stopBrowsing];
}

// Sent if browsing fails
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary *)errorDict {
    [self stopBrowsing];
    self.searching = NO;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    NSLog(@"Found domain: %@", domainString);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services addObject:service];
    // Sort Services
    [self.services sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    
    if (!moreComing) {
        [self stopBrowsing];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Update Services
    [self.services removeObject:service];

    if (!moreComing) {
        [self stopBrowsing];
    }
}

//==================================================================
#pragma mark - NSNetServiceDelegate
//==================================================================

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    
    if ([service.name compare:SMARTCONFIG_IDENTIFIER] == NSOrderedSame) {
        // Start UDP connection
        JSmartPlug *smartPlug = [JSmartPlug new];
        smartPlug.name = service.name;
        smartPlug.server = service.hostName;
        smartPlug.ip = (NSString *)[service.addresses objectAtIndex:0];
        [_udp runUdpClient:service.hostName msg:@"ID?"];  // this need to be change to Chin's protocol
        smartPlug.plugId = [_udp runUdpServer];
        //SystemClock.sleep(200);
        [_plugs addObject:smartPlug];
    }
    
    /*
     // Connect With Service
     if ([self connectWithService:service]) {
     NSLog(@"Did Connect with Service: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
     } else {
     NSLog(@"Unable to Connect with Service: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
     }
     */
}

- (void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
    [service setDelegate:nil];
}

//==================================================================
#pragma mark - Service UDP connection
//==================================================================

- (BOOL)connectWithService:(NSNetService *)service {
    BOOL _isConnected = NO;
    
    // Copy Service Addresses
    NSArray *addresses = [[service addresses] mutableCopy];
    
    if (!self.socket || ![self.socket isConnected]) {
        // Initialize Socket
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        // Connect
        while (!_isConnected && [addresses count]) {
            NSData *address = [addresses objectAtIndex:0];
            
            NSError *error = nil;
            if ([self.socket connectToAddress:address error:&error]) {
                _isConnected = YES;
                
            } else if (error) {
                NSLog(@"Unable to connect to address. Error %@ with user info %@.", error, [error userInfo]);
            }
        }
        
    } else {
        _isConnected = [self.socket isConnected];
    }
    
    return _isConnected;
}

@end
