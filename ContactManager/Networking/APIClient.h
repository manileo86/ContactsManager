//
//  APIClient.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

#import <Foundation/Foundation.h>

#import "APIDefinitions.h"

#import "AFNetworking.h"

//#define PS_BLOCK_SAFE_CALL(block, ...) block ? block(__VA_ARGS__) : nil

/* Types */
typedef void (^APICompletionBlock)(NSError *error, NSDictionary *data);

typedef void (^AFNSuccessBlock)(NSURLSessionDataTask *task, id responseObject);
typedef void (^AFNFailureBlock)(NSURLSessionDataTask *task, NSError *error);


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

@end
