//
//  NSMutableArray+QueueStack.h
//  SmartPlug
//
//  Created by Kevin Phua on 6/7/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueStack)

-(id)queuePop;
-(void)queuePush:(id)obj;
-(id)stackPop;
-(void)stackPush:(id)obj;

@end
