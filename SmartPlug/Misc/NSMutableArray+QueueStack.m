//
//  NSMutableArray+QueueStack.m
//  SmartPlug
//
//  Created by Kevin Phua on 6/7/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "NSMutableArray+QueueStack.h"

@implementation NSMutableArray (QueueStack)

// Queues are first-in-first-out, so we remove objects from the head
-(id)queuePop {
    @synchronized(self)
    {
        if ([self count] == 0) {
            return nil;
        }
        
        id queueObject = [self objectAtIndex:0];
        
        [self removeObjectAtIndex:0];
        
        return queueObject;
    }
}

// Add to the tail of the queue
-(void)queuePush:(id)anObject {
    @synchronized(self)
    {
        [self addObject:anObject];
    }
}

//Stacks are last-in-first-out.
-(id)stackPop {
    @synchronized(self)
    {
        id lastObject = [self lastObject];
        
        if (lastObject)
            [self removeLastObject];
        
        return lastObject;
    }
}

-(void)stackPush:(id)obj {
    @synchronized(self)
    {
        [self addObject: obj];
    }
}

@end
