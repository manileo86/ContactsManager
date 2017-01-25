//
//  GJContactsRetryManager.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import "GJContactsRetryManager.h"
#import "GJContactsSyncManager.h"
#import "AppDelegate.h"
#import "GJContactEntity+CoreDataClass.h"

@implementation GJContactsRetryManager

+ (instancetype) defaultManager
{
    static GJContactsRetryManager * syncManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        syncManager = [GJContactsRetryManager new];
    });
    
    return syncManager;
}

- (void)upload
{
    
}

@end
