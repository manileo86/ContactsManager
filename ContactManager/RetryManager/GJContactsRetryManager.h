//
//  GJContactsRetryManager.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <Foundation/Foundation.h>

@interface GJContactsRetryManager : NSObject

+ (instancetype) defaultManager;

- (void) upload;

@end
