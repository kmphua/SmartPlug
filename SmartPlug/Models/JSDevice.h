//
//  JSDevice.h
//  SmartPlug
//
//  Created by Kevin Phua on 12/29/15.
//  Copyright © 2015 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSDevice : NSObject

@property (nonatomic, strong) NSString *deviceTitle;
@property (nonatomic, strong) NSString *iconUrl;
@property (nonatomic, strong) NSString *fullPicUrl;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *deviceKey;
@property (nonatomic) BOOL hasTimer;
@property (nonatomic) BOOL hasWarning;

@end
