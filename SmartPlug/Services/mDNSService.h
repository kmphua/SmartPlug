//
//  mDNSService.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/30/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface mDNSService : NSObject

@property (strong, nonatomic) NSMutableArray *plugs;
@property (nonatomic) BOOL isSearching;

+ (mDNSService *)getInstance;

- (void)startBrowsing;
- (void)stopBrowsing;

@end
