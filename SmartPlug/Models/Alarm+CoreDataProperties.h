//
//  Alarm+CoreDataProperties.h
//  
//
//  Created by Kevin Phua on 2/16/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Alarm.h"

NS_ASSUME_NONNULL_BEGIN

@interface Alarm (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *alarm_id;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *service_id;
@property (nullable, nonatomic, retain) NSNumber *dow;
@property (nullable, nonatomic, retain) NSNumber *initial_hour;
@property (nullable, nonatomic, retain) NSNumber *initial_minute;
@property (nullable, nonatomic, retain) NSNumber *end_hour;
@property (nullable, nonatomic, retain) NSNumber *end_minute;
@property (nullable, nonatomic, retain) NSNumber *snooze;

@end

NS_ASSUME_NONNULL_END
