//
//  APIClient.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <Foundation/Foundation.h>
#import "APIDefinitions.h"
#import "AFNetworking.h"

@interface APIClient : NSObject {
    
}

/**
 *  Current reachability status received from AFNetworkReachabilityManager
 */
@property (assign, nonatomic, readonly) AFNetworkReachabilityStatus reachabilityStatus;

/**
 *  Returns default instance of API client
 *
 *  @return Instance of APIClient with initialized session manager and sat up reachability monitoring
 */
+ (instancetype)defaultClient;

- (void)getContactsWithCompletionBlock:(APICompletionBlock)completionBlock;

- (void)getContactDetailsForId:(NSString*)contactId withCompletionBlock:(APICompletionBlock)completionBlock;

- (void)postContact:(NSDictionary*)contactInfo withImageData:(NSData*)imageData withCompletionBlock:(APICompletionBlock)completionBlock;

- (void)postContact:(NSDictionary*)contactInfo withCompletionBlock:(APICompletionBlock)completionBlock;

- (void)updateContact:(NSDictionary*)contactInfo withCompletionBlock:(APICompletionBlock)completionBlock;

- (void)postContact:(NSDictionary*)contactInfo withImageData:(NSData*)imageData withCompletionBlock:(APICompletionBlock)completionBlock;

- (void)uploadImage:(NSData*)imageData withCompletionBlock:(APICompletionBlock)completionBlock;

@end
