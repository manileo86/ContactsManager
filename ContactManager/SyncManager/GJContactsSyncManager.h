//
//  GJContactsSyncManager.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <Foundation/Foundation.h>

static NSString * const GJContactsFetchDidBeginNotification = @"GJContactsFetchDidBeginNotification";
static NSString * const GJContactsFetchDidEndNotification = @"GJContactsFetchDidEndNotification";
static NSString * const GJContactsFetchDidFailNotification = @"GJContactsFetchDidFailNotification";

typedef void (^ContactDetailsFetchCompletionBlock)();
typedef void (^ContactCreateCompletionBlock)(NSError *error, NSDictionary *data);
typedef void (^ContactUpdateCompletionBlock)(NSError *error, NSDictionary *data);

@interface GJContactsSyncManager : NSObject

+ (BOOL) isContactsFetchDone;
+ (instancetype) defaultManager;

- (void) fetchContacts;
- (void) getContactDetailsForId:(NSString*)contactId withCompletionBlock:(ContactDetailsFetchCompletionBlock)completionBlock;
- (void) postContactDetails:(NSDictionary*)contactInfo withCompletionBlock:(ContactCreateCompletionBlock)completionBlock;
- (void) updateContactDetails:(NSDictionary*)contactInfo withCompletionBlock:(ContactUpdateCompletionBlock)completionBlock;


@end
