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

@interface GJContactsSyncManager : NSObject

+ (BOOL) isContactsFetchDone;
+ (instancetype) defaultManager;

- (void) fetchContacts;
- (void) getContactDetailsForId:(NSString*)contactId withCompletionBlock:(ContactDetailsFetchCompletionBlock)completionBlock;

@end
