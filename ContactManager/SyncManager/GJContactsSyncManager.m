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
                    contactEntity.contactId = [[contactInfo objectForKey:@"id"] integerValue];
                    contactEntity.firstName = [contactInfo objectForKey:@"first_name"];
                    contactEntity.lastName = [contactInfo objectForKey:@"last_name"];
                    contactEntity.imageUrl = [contactInfo objectForKey:@"profile_pic"];
                    //contactEntity.email = [contactInfo objectForKey:@""];
                    //contactEntity.phone = [contactInfo objectForKey:@""];
                    //contactEntity.isFavorite = NO;
                }
                
                [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
                
//                NSError *error = nil;
//                if (![context save:&error]) {
//                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
//                }
                
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
                                              contactEntity.contactId = [[contactInfo objectForKey:@"id"] integerValue];
                                              contactEntity.firstName = [contactInfo objectForKey:@"first_name"];
                                              contactEntity.lastName = [contactInfo objectForKey:@"last_name"];
                                              contactEntity.imageUrl = [contactInfo objectForKey:@"profile_pic"];
                                              contactEntity.email = [contactInfo objectForKey:@"email"];
                                              contactEntity.phone = [contactInfo objectForKey:@"phone_number"];
                                              //contactEntity.isFavorite = [[contactInfo objectForKey:@"favorite"] boolValue];

                                              //[(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  
                                              NSError *error = nil;
                                              if (![context save:&error]) {
                                                  NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                                              }
                                              
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
                contactEntity.contactId = [[contactInfo objectForKey:@"id"] integerValue];
                contactEntity.firstName = [contactInfo objectForKey:@"first_name"];
                contactEntity.lastName = [contactInfo objectForKey:@"last_name"];
                contactEntity.imageUrl = [contactInfo objectForKey:@"profile_pic"];
                contactEntity.email = [contactInfo objectForKey:@""];
                contactEntity.phone = [contactInfo objectForKey:@""];
                contactEntity.isFavorite = NO;
                
                [(AppDelegate *)[UIApplication sharedApplication].delegate saveContext];
                
                //                NSError *error = nil;
                //                if (![context save:&error]) {
                //                    NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                //                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                });
            }];
        }
    }];
}

@end
