//
//  CrashCountDown.h
//  SmartPlug
//
//  Created by Kevin Phua on 3/16/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrashCountDown : NSObject

+ (CrashCountDown *)getInstance;

- (void)startTimer;
- (void)stopTimer;

@end
