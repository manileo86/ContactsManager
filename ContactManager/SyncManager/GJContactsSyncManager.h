//
//  GJContactsSyncManager.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GJContactEntity+CoreDataClass.h"
#import "GJContactToUpload+CoreDataClass.h"

static NSString * const GJContactsFetchDidBeginNotification = @"GJContactsFetchDidBeginNotification";
static NSString * const GJContactsFetchDidEndNotification = @"GJContactsFetchDidEndNotification";
static NSString * const GJContactsFetchDidFailNotification = @"GJContactsFetchDidFailNotification";

typedef void (^GJCompletionBlock)();
typedef void (^ContactCreateCompletionBlock)(NSError *error, NSDictionary *data);
typedef void (^ContactUpdateCompletionBlock)(NSError *error, NSDictionary *data);
typedef void (^ImageUploadCompletionBlock)(NSError *error, NSString *imageUrl);

@interface GJContactsSyncManager : NSObject

+ (BOOL) isContactsFetchDone;
+ (instancetype) defaultManager;

- (void) fetchContacts;
- (void) getContactDetailsForId:(NSString*)contactId withCompletionBlock:(GJCompletionBlock)completionBlock;
- (void) updateContactDetails:(NSDictionary*)contactInfo withCompletionBlock:(ContactUpdateCompletionBlock)completionBlock;
- (void) postContactDetails:(NSDictionary*)contactInfo withCompletionBlock:(ContactCreateCompletionBlock)completionBlock;
- (void) uploadImageData:(NSData*)imageData withCompletionBlock:(ImageUploadCompletionBlock)completionBlock;
- (void)createContactToUploadWithImage:(UIImage*)image andInfo:(NSDictionary*)contactInfo withCompletionBlock:(GJCompletionBlock)completionBlock;

- (void)createContactFromInfo:(NSDictionary*)contactInfo removeContactUpload:(GJContactToUpload*)contactToUpload  withCompletionBlock:(GJCompletionBlock)completionBlock;

@end
