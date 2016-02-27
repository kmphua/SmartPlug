//
//  SQLHelper.h
//  SmartPlug
//
//  Created by Kevin Phua on 2/27/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SQLHelper : NSObject

+ (SQLHelper *)getInstance;
- (bool)executeCommand:(NSString *)sql;
- (bool)executeQuery:(NSString *)sql statement:(sqlite3_stmt **)statement;

@end
