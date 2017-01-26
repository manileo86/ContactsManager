//
//  GJContactsRetryManager.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsRetryManager.h"
#import "APIClient.h"
#import "AppDelegate.h"
#import "GJContactsSyncManager.h"

@interface GJContactsRetryManager ()<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *contactToUploadFRC;
@property (strong, nonatomic) GJContactToUpload *contactToUpload;

@end

@implementation GJContactsRetryManager

static NSDateFormatter * _dateFormatter = nil;

- (NSPersistentContainer *)persistentContainer {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).persistentContainer;
}

+ (instancetype) defaultManager
{
    static GJContactsRetryManager * retryManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        retryManager = [GJContactsRetryManager new];
        [retryManager subscribeForNotifications];
        [retryManager loadContactsToUpload];
    });
    
    return retryManager;
}

- (void)subscribeForNotifications
{
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)loadContactsToUpload
{
    if(!self.contactToUploadFRC)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([GJContactToUpload class])];
        fetchRequest.sortDescriptors = @[];
        self.contactToUploadFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self persistentContainer].viewContext sectionNameKeyPath:nil cacheName:nil];
        self.contactToUploadFRC.delegate = self;
    }
    [self.contactToUploadFRC performFetch:nil];
    self.contactToUpload = [self.contactToUploadFRC.fetchedObjects firstObject];
    
    if(self.contactToUpload.isUploadPending)
    {
        _contactToUpload.isUploadPending = NO;
        [self saveContactToUpload];
        [self checkAndStartUpload];
    }
}

- (GJContactToUpload*)currentContactToUpload
{
    return self.contactToUpload;
}

- (void)checkAndStartUpload
{
    NSLog(@"CONTACT UPLOAD STARTED");
    [self loadContactsToUpload];
    if(self.contactToUpload)
    {
        if(self.contactToUpload.isUploading)
        {
            NSLog(@"CONTACT IS ALREEADY UPLOADING");
            if(self.contactToUpload.isFailed)
            {
                // error case handling
                [self startPostingContact];
            }
        }
        else
        {
            [self startPostingContact];
        }
    }
    else
    {
        NSLog(@"CONTACT TO UPLOAD NIL");
    }
}

- (void)startPostingContact
{
    self.contactToUpload.isUploading = YES;
    self.contactToUpload.isFailed = NO;
    self.contactToUpload.isUploadPending = NO;
    [self saveContactToUpload];
    
    // check for image
    if(_contactToUpload.image)
    {
        [self uploadImage];
        //[self postContactWithImage];
    }
    else
    {
        // post the contact
        [self postContact];
    }
}

- (void)uploadImage
{
    if(_contactToUpload.image)
    {
        NSLog(@"IMAGE UPLOAD STARTED");
        // Upload Image
        [[GJContactsSyncManager defaultManager] uploadImageData:_contactToUpload.image withCompletionBlock:^(NSError *error, NSString *imageId) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!error)
                {
                    NSLog(@"IMAGE UPLOAD SUCCEDED");
                    NSMutableDictionary *updatedInfo = [[NSKeyedUnarchiver unarchiveObjectWithData:_contactToUpload.params] mutableCopy];
                    // Upload Image Succeeded
                    [updatedInfo setObject:imageId forKey:@"profile_pic"];
                    _contactToUpload.params = [NSKeyedArchiver archivedDataWithRootObject:updatedInfo];                    
                    [self saveContactToUpload];
                    // Post Contact
                    [self postContact];
                }
                else
                {
                    NSLog(@"IMAGE UPLOAD FAILED");
                    // Upload Image Failed
                    _contactToUpload.isFailed = YES;
                    _contactToUpload.isUploading = NO;
                    NSError *error = nil;
                    if (![_contactToUpload.managedObjectContext save:&error]) {
                        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                    }
                    [self sendUpdateNotification];
                }
            });
        }];
    }
    else
    {
        // post the contact
        [self postContact];
    }
}

- (void)postContactWithImage
{
    __block NSDictionary *contactInfo = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:_contactToUpload.params];
    // Post Contact
    NSLog(@"POST CONTACT STARTED");
    [[GJContactsSyncManager defaultManager] postContactDetails:contactInfo withImageData:_contactToUpload.image withCompletionBlock:^(NSError *error, NSDictionary *data) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!error)
            {
                NSLog(@"POST CONTACT SUCCEDED");
                // Post Contact Succeded
                NSDictionary *contactInfoFromResponse = (NSDictionary*)data;
                [[GJContactsSyncManager defaultManager] createContactFromInfo:contactInfoFromResponse removeContactUpload:_contactToUpload withCompletionBlock:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"CONTACT CREATED");
                        [self clearContactToUpload];
                        self.contactToUpload = nil;
                        [self sendUpdateNotification];
                        if([self isUploadCleanedUp])
                            NSLog(@"CONTACT NOT CLEARED");
                        else
                            NSLog(@"CONTACT CLEARED SUCCESSFULLY");
                    });
                }];
            }
            else
            {
                NSLog(@"POST CONTACT FAILED");
                // Post Contact Failed
                _contactToUpload.isFailed = YES;
                _contactToUpload.isUploading = NO;
                [self saveContactToUpload];
            }
        });
    }];
}

- (void)postContact
{
    __block NSDictionary *contactInfo = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:_contactToUpload.params];
    // Post Contact
    NSLog(@"POST CONTACT STARTED");
    [[GJContactsSyncManager defaultManager] postContactDetails:contactInfo withCompletionBlock:^(NSError *error, NSDictionary *data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!error)
            {
                NSLog(@"POST CONTACT SUCCEDED");
                // Post Contact Succeded
                NSDictionary *contactInfoFromResponse = (NSDictionary*)data;
                [[GJContactsSyncManager defaultManager] createContactFromInfo:contactInfoFromResponse removeContactUpload:_contactToUpload withCompletionBlock:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"CONTACT CREATED");
                        [self clearContactToUpload];
                        self.contactToUpload = nil;
                        [self sendUpdateNotification];
                        if([self isUploadCleanedUp])
                            NSLog(@"CONTACT NOT CLEARED");
                        else
                            NSLog(@"CONTACT CLEARED SUCCESSFULLY");
                    });
                }];
            }
            else
            {
                NSLog(@"POST CONTACT FAILED");
                // Post Contact Failed
                _contactToUpload.isFailed = YES;
                _contactToUpload.isUploading = NO;
                [self saveContactToUpload];
            }
        });
    }];
}

- (void)saveContactToUpload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        if (![_contactToUpload.managedObjectContext save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        [self sendUpdateNotification];
    });
}

- (void)clearContactToUpload
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([GJContactToUpload class])];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
    
    NSError *deleteError = nil;
    [[self persistentContainer].persistentStoreCoordinator executeRequest:delete withContext:[self persistentContainer].viewContext error:&deleteError];
    self.contactToUpload = nil;
}

- (BOOL)isUploadCleanedUp
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([GJContactToUpload class])];
    fetchRequest.sortDescriptors = @[];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self persistentContainer].viewContext sectionNameKeyPath:nil cacheName:nil];
    [frc performFetch:nil];
    return frc.fetchedObjects.count>0;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self sendUpdateNotification];
}

#pragma mark - Notifications

- (void)sendUpdateNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:GJContactUploadNotification object:self.contactToUpload];
    });
}

@end
