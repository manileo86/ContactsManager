//
//  GJContactsSyncManager.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsSyncManager.h"
#import "APIClient.h"
#import "AppDelegate.h"

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

- (void)createContactFromInfo:(NSDictionary*)contactInfo removeContactUpload:(GJContactToUpload*)contactToUpload  withCompletionBlock:(GJCompletionBlock)completionBlock;
{
    [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * context) {
        
        GJContactEntity *contactEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([GJContactEntity class]) inManagedObjectContext:context];
        [self fillContact:contactEntity fromDictionary:contactInfo];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [context deleteObject:contactToUpload];
            completionBlock();
        });
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

- (void)createContactToUploadWithImage:(UIImage*)image andInfo:(NSDictionary*)contactInfo withCompletionBlock:(GJCompletionBlock)completionBlock
{
    [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext * context) {
        
        NSData *imageData = UIImageJPEGRepresentation(image, 0.7); // 0.7 is JPG quality
        NSData *contactData = [NSKeyedArchiver archivedDataWithRootObject:contactInfo];

        GJContactToUpload *contactToUpload = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([GJContactToUpload class]) inManagedObjectContext:context];
        contactToUpload.params = contactData;
        contactToUpload.image = imageData;
        contactToUpload.isUploading = NO;
        contactToUpload.isFailed = NO;
        contactToUpload.isUploadPending = YES;
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock();
        });
    }];
}

- (void) uploadImageData:(NSData*)imageData withCompletionBlock:(ImageUploadCompletionBlock)completionBlock
{
    
    // sample response
    /*
    {
        data =     {
            "delete_key" = 6141369940031ec8;
            "img_attr" = "width=\"750\" height=\"750\"";
            "img_bytes" = 95076;
            "img_height" = 750;
            "img_name" = "nWuVa.jpg";
            "img_size" = "92.8 KB";
            "img_url" = "http://sm.uploads.im/nWuVa.jpg";
            "img_view" = "http://uploads.im/nWuVa.jpg";
            "img_width" = 750;
            resized = 0;
            source = "base64 image string";
            "thumb_height" = 360;
            "thumb_url" = "http://sm.uploads.im/t/nWuVa.jpg";
            "thumb_width" = 360;
        };
        "status_code" = 200;
        "status_txt" = OK;
     }
        */
    
    [[APIClient defaultClient] uploadImage:imageData WithCompletionBlock:^(NSError *error, id data) {
        if(!error)
        {
            NSDictionary *imageInfo = (NSDictionary*)data;
            NSDictionary *imageDataDict = imageInfo[@"data"];
            NSString *imageUrl = imageDataDict[@"img_url"];
            completionBlock(nil, imageUrl);
        }
        else
        {
            completionBlock(error, nil);
        }
        
    }];
    
}

@end
