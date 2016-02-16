//
//  JSmartPlug+CoreDataProperties.h
//  
//
//  Created by Kevin Phua on 2/16/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "JSmartPlug.h"

NS_ASSUME_NONNULL_BEGIN

@interface JSmartPlug (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *devid;
@property (nullable, nonatomic, retain) NSString *ip;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *server;
@property (nullable, nonatomic, retain) NSString *model;
@property (nullable, nonatomic, retain) NSNumber *buildno;
@property (nullable, nonatomic, retain) NSNumber *prot_ver;
@property (nullable, nonatomic, retain) NSString *hw_ver;
@property (nullable, nonatomic, retain) NSString *fw_ver;
@property (nullable, nonatomic, retain) NSNumber *fw_date;
@property (nullable, nonatomic, retain) NSNumber *flag;
@property (nullable, nonatomic, retain) NSNumber *relay;
@property (nullable, nonatomic, retain) NSNumber *hall_sensor;
@property (nullable, nonatomic, retain) NSNumber *nightlight;
@property (nullable, nonatomic, retain) NSNumber *co_sensor;
@property (nullable, nonatomic, retain) NSString *givenName;
@property (nullable, nonatomic, retain) NSString *icon;

@end

NS_ASSUME_NONNULL_END
