//
//  APIClient.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//


#import "APIClient.h"

#define PS_SAFE_BLOCK(block, ...) block ? block(__VA_ARGS__) : nil
#define PS_WEAK_SELF __weak __typeof(self)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


/**
 *  Comment this macro to turn off API requests logging
 */
//#define PS_NETWORK_LOGGING 1

static APIClient *defaultClient = nil;

@interface APIClient() {
    
}

/**
 *  Session manager configured to json requests, used for almost all requests. Exception is user info update.
 */
@property (strong, nonatomic) AFHTTPSessionManager *jsonSessionManager;

/**
 *  Session manager configured to use key-value parameters in requests. Used to update user info.
 */
@property (strong, nonatomic) AFHTTPSessionManager *keyedSessionManager;

/* Setup */
- (void)setupSessionManager;
- (void)buildRequestHeaders;
- (void)setupReachabilityManager;

/* Accessors */
- (void)setReachabilityStatus:(AFNetworkReachabilityStatus)reachabilityStatus;
- (void)updateReachabilityStatus;

/* Tools */
- (void)populateError:(out NSError **)error withTask:(NSURLSessionDataTask *)task response:(id)response underlyingError:(NSError *)underlyingError;
- (AFNSuccessBlock)wrapSuccessBlock:(APICompletionBlock)completionBlock;
- (AFNFailureBlock)wrapFailureBlock:(APICompletionBlock)completionBlock;

/**
 *  Appends passed path to the backend base URL
 *
 *  @param endpointPath NSString URL to append to base URL of backemd
 *
 *  @return NSString full path for call
 */
- (NSString *)requestPathWithEndpointPath:(NSString *)endpointPath;

/* Networking */
/**
 *  Checks current reachability status
 *
 *  @param completionBlock Block called only if status is unreachable or unknown. Do not call it in such case on your own
 *  @return Returns YES in case status is reachable via Wi-Fi or WWAN, otherwise returns NO
 */
- (BOOL)apiDomainReachable:(APICompletionBlock)completionBlock;

/* HTTP method based requests */
- (void)runPOSTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock;
- (void)runGETRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock;
- (void)runPUTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock;

@end

@implementation APIClient

+ (instancetype)defaultClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultClient = [[self alloc] init];
        
        if (defaultClient) {
            [defaultClient setupSessionManager];
        }
    });
    
    return defaultClient;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _reachabilityStatus = AFNetworkReachabilityStatusUnknown;
    }
    
    return self;
}

#pragma mark - Setup

- (void)setupSessionManager
{
    NSURL *baseAPIURL = [NSURL URLWithString:APIUrlPath];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.jsonSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseAPIURL sessionConfiguration:sessionConfiguration];
    self.jsonSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableIndexSet *statusCodes = [[NSMutableIndexSet alloc] init];
    [statusCodes addIndex:200];  // Generic OK status
    [statusCodes addIndex:201];  // 'Created' status, for example for sign up request for new user
    [statusCodes addIndex:422];  // RoR sends this by default on any logic errors, for example when trying to sign up already existent user
    [self.jsonSessionManager.responseSerializer setAcceptableStatusCodes:statusCodes];
    
    AFHTTPRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    self.jsonSessionManager.requestSerializer = requestSerializer;
    
    // Setup keyed session manager
    self.keyedSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseAPIURL sessionConfiguration:sessionConfiguration];
    self.keyedSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.keyedSessionManager.responseSerializer setAcceptableStatusCodes:statusCodes];
    
    [self buildRequestHeaders];
    [self setupReachabilityManager];
}

- (void)buildRequestHeaders
{
    // JSON serialized request headers
    if (self.jsonSessionManager.requestSerializer) {
        [self.jsonSessionManager.requestSerializer setValue:APIContentTypeHeader forHTTPHeaderField:@"Content-Type"];
        [self.jsonSessionManager.requestSerializer setValue:APIAcceptHeader forHTTPHeaderField:@"Accept"];
        [self.jsonSessionManager.requestSerializer setValue:APIAcceptEncodingHeader forHTTPHeaderField:@"Accept-Encoding"];
        //[self.jsonSessionManager.requestSerializer setValue:[self.settings userToken] forHTTPHeaderField:@"Access-Token"];
        //[self.jsonSessionManager.requestSerializer setValue:[self.settings getUUID] forHTTPHeaderField:@"device-id"];
    }
    
    // Key-value serialized request headers
    if (self.keyedSessionManager.requestSerializer) {
        [self.keyedSessionManager.requestSerializer setValue:APIContentTypeMultipartHeader forHTTPHeaderField:@"Content-Type"];
        [self.keyedSessionManager.requestSerializer setValue:APIAcceptHeader forHTTPHeaderField:@"Accept"];
        [self.keyedSessionManager.requestSerializer setValue:APIAcceptEncodingHeader forHTTPHeaderField:@"Accept-Encoding"];
        //[self.keyedSessionManager.requestSerializer setValue:[self.settings userToken] forHTTPHeaderField:@"Access-Token"];
        //[self.keyedSessionManager.requestSerializer setValue:[self.settings getUUID] forHTTPHeaderField:@"device-id"];
    }
}

- (void)setupReachabilityManager
{
    __weak APIClient *weakClient = self;
    if (!self.jsonSessionManager.reachabilityManager) {
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager managerForDomain:APIUrlPath];
        [self.jsonSessionManager setReachabilityManager:manager];
    }
    
    [self.jsonSessionManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [weakClient setReachabilityStatus:status];
        [[NSNotificationCenter defaultCenter] postNotificationName:BackendReachabilityChangedNotification object:nil userInfo:@{BackendReachabilityStatusKey: @(status)}];
    }];
    [self.jsonSessionManager.reachabilityManager startMonitoring];
}

- (void)setReachabilityStatus:(AFNetworkReachabilityStatus)reachabilityStatus
{
    _reachabilityStatus = reachabilityStatus;
}

- (void)updateReachabilityStatus
{
    _reachabilityStatus = [self.jsonSessionManager.reachabilityManager networkReachabilityStatus];
}

#pragma mark - Tools

- (void)populateError:(out NSError **)error withTask:(NSURLSessionDataTask *)task response:(id)response underlyingError:(NSError *)underlyingError
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    /* Assume we don't have any response by default */
    NSUInteger errorCode = APIErrorOkErrorCode;
    NSString *errorDescription = APIErrorOkDescription;
    
    /* We have response, checking for error info inside */
    if (response && [response isKindOfClass:[NSDictionary class]]) {
        if (response[APIErrorResponseFieldKey]) {
            errorCode = [response[APIErrorResponseFieldKey][0][APIErrorCodeResponseFieldKey] integerValue];
            errorDescription = response[APIErrorResponseFieldKey][0][APIErrorDesriptionFieldKey];
            
            userInfo[NSLocalizedDescriptionKey] = errorDescription;
            *error = [NSError errorWithDomain:APIClientErrorDomain code:errorCode userInfo:userInfo];
            
        } else {
            errorCode = APIErrorOkErrorCode;
            errorDescription = APIErrorOkDescription;
        }
    }
    
    /* Setting underlying error */
    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        if (errorCode == APIErrorOkErrorCode) {
            if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                errorCode = response.statusCode;
            } else {
                errorCode = underlyingError.code;
            }
            errorDescription = underlyingError.userInfo[NSLocalizedDescriptionKey];
            if (!errorDescription) {
                errorCode = APINotReachableErrorCode;
                errorDescription = APINotReachableErrorDescription;
            }
        }
        
        userInfo[NSLocalizedDescriptionKey] = errorDescription;
        *error = [NSError errorWithDomain:APIClientErrorDomain code:errorCode userInfo:userInfo];
    }
}

- (AFNSuccessBlock)wrapSuccessBlock:(APICompletionBlock)completionBlock
{
    AFNSuccessBlock successBlock = ^(NSURLSessionDataTask *task, id responseObject) {
        NSError *requestError = nil;
        [self populateError:&requestError withTask:task response:responseObject underlyingError:nil];
        PS_SAFE_BLOCK(completionBlock, requestError, responseObject);
    };
    
    return successBlock;
}

- (AFNFailureBlock)wrapFailureBlock:(APICompletionBlock)completionBlock
{
    AFNFailureBlock failureBlock = ^(NSURLSessionDataTask *task, NSError *error) {
        NSError *requestError = nil;
        [self populateError:&requestError withTask:task response:nil underlyingError:error];
        PS_SAFE_BLOCK(completionBlock, requestError, nil);
    };
    
    return failureBlock;
}

- (NSString *)requestPathWithEndpointPath:(NSString *)endpointPath
{
    return [APIUrlPath stringByAppendingPathComponent:endpointPath];
}

#pragma mark - Networking

- (BOOL)apiDomainReachable:(APICompletionBlock)completionBlock
{
    [self updateReachabilityStatus];
    if (self.reachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi ||
        self.reachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN) {
        return YES;
    }
    
    NSError *reachabilityError = [NSError errorWithDomain:APIClientErrorDomain code:APINotReachableErrorCode userInfo:@{NSLocalizedDescriptionKey : APINotReachableErrorDescription}];
    completionBlock(reachabilityError, nil);
    
    return NO;
}

- (void)runPOSTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    [self.jsonSessionManager POST:requestPath parameters:parameters progress:nil success:[self wrapSuccessBlock:completionBlock] failure:[self wrapFailureBlock:completionBlock]];
    
#ifdef PS_NETWORK_LOGGING
    NSLog(@"APIClient: POST request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runPOSTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters bodyConstructingBlock:(void (^)(id <AFMultipartFormData> formData))body completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    [self.jsonSessionManager POST:requestPath parameters:parameters constructingBodyWithBlock:body progress:nil success:[self wrapSuccessBlock:completionBlock] failure:[self wrapFailureBlock:completionBlock]];
    
#ifdef PS_NETWORK_LOGGING
    NSLog(@"APIClient: POST request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runPUTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters bodyConstructingBlock:(void (^)(id <AFMultipartFormData> formData))body completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    NSMutableURLRequest *request = [self.keyedSessionManager.requestSerializer multipartFormRequestWithMethod:@"PUT" URLString:requestPath parameters:parameters constructingBodyWithBlock:body error:nil];
    
    NSURLSessionDataTask *dataTask = [self.keyedSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        PS_SAFE_BLOCK(completionBlock, error, responseObject);
    }];
    
    [dataTask resume];
    
#ifdef PS_NETWORK_LOGGING
    NSLog(@"APIClient: PUT request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runGETRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    [self.jsonSessionManager GET:requestPath parameters:parameters progress:nil success:[self wrapSuccessBlock:completionBlock] failure:[self wrapFailureBlock:completionBlock]];
    
#ifdef PS_NETWORK_LOGGING
    NSLog(@"APIClient: GET request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runPUTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock
{
    if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    [self.jsonSessionManager PUT:requestPath parameters:parameters success:[self wrapSuccessBlock:completionBlock] failure:[self wrapFailureBlock:completionBlock]];
    
#ifdef PS_NETWORK_LOGGING
    NSLog(@"APIClient: PUT request: %@\n%@", requestPath, parameters);
#endif
}

#pragma mark - API Calls

- (void)getContactsWithCompletionBlock:(APICompletionBlock)completionBlock
{
    [self runGETRequestWithEndpoint:APIClientContactsURLPath parameters:nil completion:
     ^(NSError *error, NSDictionary *data) {
         if(data)
         {
             if(error)
             {
                 NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Contact Details Fetch Failed"}];
                 completionBlock(errorInfo, nil);
             }
             else
             {
                 completionBlock(nil, data);
             }
         }
         else if(error)
         {
             NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Contact Details Fetch Failed"}];
             completionBlock(errorInfo, nil);
         }
         else
         {
             completionBlock(nil, nil);
         }
     }];
}

- (void)getContactDetailsForId:(NSString*)contactId withCompletionBlock:(APICompletionBlock)completionBlock
{
    NSString *path = [NSString stringWithFormat:APIClientGetContactDetailsURLPath, contactId];
    
    [self runGETRequestWithEndpoint:path parameters:nil completion:
     ^(NSError *error, NSDictionary *data) {
         if(data)
         {
             if(error)
             {
                 NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Contact Details Fetch Failed"}];
                 completionBlock(errorInfo, nil);
             }
             else
             {
                 completionBlock(nil, data);
             }
         }
         else if(error)
         {
             NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Contact Details Fetch Failed"}];
             completionBlock(errorInfo, nil);
         }
         else
         {
             completionBlock(nil, nil);
         }
     }];
}

- (void)postContact:(NSDictionary*)contactInfo WithCompletionBlock:(APICompletionBlock)completionBlock
{
    [self runPOSTRequestWithEndpoint:APIClientContactsURLPath parameters:contactInfo completion:
     ^(NSError *error, NSDictionary *data) {
         if(data)
         {
             NSArray *errors = (NSArray*)[data objectForKey:@"errors"];
             if(errors)
             {
                 NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Contact Create Failed : %@", [errors componentsJoinedByString:@","]]}];
                 completionBlock(errorInfo, nil);
             }
             else
             {
                 completionBlock(nil, data);
             }
         }
         else if(error)
         {
             NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Contact Create Failed"}];
             completionBlock(errorInfo, nil);
         }
         else
         {
             completionBlock(nil, nil);
         }
     }];
}

@end
