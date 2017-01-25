//
//  GJContactsSyncManager.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsSyncManager.h"
#import "APIClient.h"
#import "AppDelegate.h"
#import "GJContactEntity+CoreDataClass.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation GJContactsSyncManager

static NSDateFormatter * _dateFormatter = nil;

- (NSPersistentContainer *)persistentContainer {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).persistentContainer;
}

+ (instancetype) defaultManager
{
    static GJContactsSyncManager * syncManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        syncManager = [GJContactsSyncManager new];
    });
    
    return syncManager;
}

+ (BOOL) isContactsFetchDone
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"contactsFetched"];
}

#pragma mark - Contacts API

- (void) fetchContacts {
    
    if([GJContactsSyncManager isContactsFetchDone])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:GJContactsFetchDidEndNotification object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:GJContactsFetchDidBeginNotification object:nil];
        [self syncContacts];
    }
}

- (void) syncContacts
{
    [[APIClient defaultClient] getContactsWithCompletionBlock:^(NSError *error, id data) {
        
        if(error)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:GJContactsFetchDidFailNotification object:nil];
        }
        else
        {
            [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * context) {
                
                NSArray *contacts = (NSArray*)data;
                for(NSDictionary *contactInfo in contacts)
                {
                    GJContactEntity *contactEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([GJContactEntity class]) inManagedObjectContext:context];
                    [self fillContact:contactEntity fromDictionary:contactInfo];
                }
                
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"contactsFetched"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:GJContactsFetchDidEndNotification object:nil];
                });
            }];
        }
    }];
}

- (void) getContactDetailsForId:(NSString*)contactId withCompletionBlock:(ContactDetailsFetchCompletionBlock)completionBlock
{
    [[APIClient defaultClient] getContactDetailsForId:contactId
                                  withCompletionBlock:^(NSError *error, id data) {
                                      if(error)
                                      {
                                          [[NSNotificationCenter defaultCenter] postNotificationName:GJContactsFetchDidFailNotification object:nil];
                                      }
                                      else
                                      {
                                          [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * context) {
                                              
                                              NSDictionary *contactInfo = (NSDictionary*)data;
                                              
                                              NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contactId == %@", contactId];
                                              NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([GJContactEntity class])
                                                                                        inManagedObjectContext:context];
                                              NSFetchRequest *request = [[NSFetchRequest alloc] init];
                                              request.entity = entity;
                                              request.predicate = predicate;
                                              request.fetchLimit = 1;
                                              
                                              NSError *requestError = nil;
                                              NSArray *result = [context executeFetchRequest:request
                                                                                       error:&requestError];
                                              
                                              GJContactEntity *contactEntity = result[0];
                                              [self fillContact:contactEntity fromDictionary:contactInfo];
                                              contactEntity.isInfoFetched = YES;
                                              
                                              NSError *error = nil;
                                              if (![context save:&error]) {
                                                  NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                                              }
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  completionBlock();
                                              });
                                          }];
                                      }
                                  }];
}

-(void)postContactDetails:(NSDictionary *)contactInfo withCompletionBlock:(ContactCreateCompletionBlock)completionBlock
{
    [[APIClient defaultClient] postContact:contactInfo WithCompletionBlock:^(NSError *error, id data) {
               
        if(!error)
        {
            [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * context) {
                
                NSDictionary *contactInfo = (NSDictionary*)data;
                GJContactEntity *contactEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([GJContactEntity class]) inManagedObjectContext:context];
                [self fillContact:contactEntity fromDictionary:contactInfo];
                contactEntity.isInfoFetched = YES;
                
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                });
            }];
        }
    }];
}

- (void) updateContactDetails:(NSDictionary*)contactInfo withCompletionBlock:(ContactUpdateCompletionBlock)completionBlock
{
    [[APIClient defaultClient] updateContact:contactInfo WithCompletionBlock:^(NSError *error, id data) {
        
        if(!error)
        {
            [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * context) {
                
                NSDictionary *contactInfo = (NSDictionary*)data;
                GJContactEntity *contactEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([GJContactEntity class]) inManagedObjectContext:context];
                [self fillContact:contactEntity fromDictionary:contactInfo];                
                
                NSError *error = nil;
                if (![context save:&error]) {
                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                });
            }];
        }
    }];
}

- (void)fillContact:(GJContactEntity*)contactEntity fromDictionary:(NSDictionary*)contactInfo
{
    contactEntity.contactId = [NULL_TO_NIL([contactInfo objectForKey:@"id"]) integerValue];
    contactEntity.firstName = NULL_TO_NIL([contactInfo objectForKey:@"first_name"]);
    contactEntity.lastName = NULL_TO_NIL([contactInfo objectForKey:@"last_name"]);
    contactEntity.imageUrl = NULL_TO_NIL([contactInfo objectForKey:@"profile_pic"]);
    contactEntity.email = NULL_TO_NIL([contactInfo objectForKey:@"email"]);
    contactEntity.phone = NULL_TO_NIL([contactInfo objectForKey:@"phone_number"]);
    contactEntity.isFavorite = NULL_TO_NIL([contactInfo objectForKey:@"favorite"])?YES:NO;
    
    NSString *createdAt = NULL_TO_NIL([contactInfo objectForKey:@"created_at"]);
    NSDataDetector *detector = nil;
    if(createdAt)
    {
        detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeDate error:nil];
        [detector enumerateMatchesInString:createdAt
                                   options:kNilOptions
                                     range:NSMakeRange(0, [createdAt length])
                                usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
         {
             contactEntity.createdAt = result.date;
         }];
    }
    
    NSString *updatedAt = NULL_TO_NIL([contactInfo objectForKey:@"updated_at"]);
    if(updatedAt)
    {
        if(!detector)
        {
            detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeDate error:nil];
        }
        [detector enumerateMatchesInString:updatedAt
                                   options:kNilOptions
                                     range:NSMakeRange(0, [createdAt length])
                                usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
         {
             contactEntity.updatedAt = result.date;
         }];
    }
}

@end
