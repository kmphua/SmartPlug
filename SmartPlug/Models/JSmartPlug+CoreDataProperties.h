//
//  JSmartPlug+CoreDataProperties.h
//  
//
//  Created by Kevin Phua on 12/30/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "JSmartPlug.h"

NS_ASSUME_NONNULL_BEGIN

@interface JSmartPlug (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *server;
@property (nullable, nonatomic, retain) NSNumber *plugId;
@property (nullable, nonatomic, retain) NSString *ip;

@end

NS_ASSUME_NONNULL_END