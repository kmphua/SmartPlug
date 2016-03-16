//
//  Icon.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Icon : NSObject

@property (nonatomic, assign) NSString *sid;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) int size;

@end
