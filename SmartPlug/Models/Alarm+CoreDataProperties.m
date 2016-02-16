//
//  Alarm+CoreDataProperties.m
//  
//
//  Created by Kevin Phua on 2/16/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Alarm+CoreDataProperties.h"

@implementation Alarm (CoreDataProperties)

@dynamic alarm_id;
@dynamic device_id;
@dynamic service_id;
@dynamic dow;
@dynamic initial_hour;
@dynamic initial_minute;
@dynamic end_hour;
@dynamic end_minute;
@dynamic snooze;

@end
