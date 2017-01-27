//
//  GJContactsRetryManager.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GJContactEntity+CoreDataClass.h"
#import "GJContactToUpload+CoreDataClass.h"

static NSString * const GJContactUploadNotification = @"GJContactUploadNotification";

typedef enum ContactUpload_State
{
    ContactUpload_Began = 0,
    ContactUpload_Updating,
    ContactUpload_End,
    ContactUpload_Failed
}ContactUploadState;

@interface GJContactsRetryManager : NSObject

+ (instancetype) sharedManager;
- (GJContactToUpload*)currentContactToUpload;

- (void)checkAndStartUpload;

@end
