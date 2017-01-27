//
//  APIClient.m
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//


#import "APIClient.h"
#import "NSData+Base64.h"

#define GJ_SAFE_BLOCK(block, ...) block ? block(__VA_ARGS__) : nil
#define GJ_WEAK_SELF __weak __typeof(self)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

/**
 *  Comment this macro to turn off API requests logging
 */
//#define GJ_NETWORK_LOGGING 1

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
    [statusCodes addIndex:422];  // Validation Errors
    [statusCodes addIndex:500];  // Internal Server Error
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
    }
    
    // Key-value serialized request headers
    if (self.keyedSessionManager.requestSerializer) {
        [self.keyedSessionManager.requestSerializer setValue:APIContentTypeMultipartHeader forHTTPHeaderField:@"Content-Type"];
        [self.keyedSessionManager.requestSerializer setValue:APIAcceptHeader forHTTPHeaderField:@"Accept"];
        [self.keyedSessionManager.requestSerializer setValue:APIAcceptEncodingHeader forHTTPHeaderField:@"Accept-Encoding"];
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
        GJ_SAFE_BLOCK(completionBlock, requestError, responseObject);
    };
    
    return successBlock;
}

- (AFNFailureBlock)wrapFailureBlock:(APICompletionBlock)completionBlock
{
    AFNFailureBlock failureBlock = ^(NSURLSessionDataTask *task, NSError *error) {
        NSError *requestError = nil;
        [self populateError:&requestError withTask:task response:nil underlyingError:error];
        GJ_SAFE_BLOCK(completionBlock, requestError, nil);
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
    
#ifdef GJ_NETWORK_LOGGING
    NSLog(@"APIClient: POST request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runPOSTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters bodyConstructingBlock:(void (^)(id <AFMultipartFormData> formData))body completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    //NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    //[self.jsonSessionManager POST:endpointPath parameters:parameters constructingBodyWithBlock:body progress:nil success:[self wrapSuccessBlock:completionBlock] failure:[self wrapFailureBlock:completionBlock]];
    
    NSString *requestPath = endpointPath;
    NSMutableURLRequest *request = [self.keyedSessionManager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:requestPath parameters:parameters constructingBodyWithBlock:body error:nil];
    
    NSURLSessionDataTask *dataTask = [self.keyedSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        GJ_SAFE_BLOCK(completionBlock, error, responseObject);
    }];
    
    [dataTask resume];
    
#ifdef GJ_NETWORK_LOGGING
    NSLog(@"APIClient: POST request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runPUTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters bodyConstructingBlock:(void (^)(id <AFMultipartFormData> formData))body completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    NSMutableURLRequest *request = [self.keyedSessionManager.requestSerializer multipartFormRequestWithMethod:@"PUT" URLString:requestPath parameters:parameters constructingBodyWithBlock:body error:nil];
    
    NSURLSessionDataTask *dataTask = [self.keyedSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        GJ_SAFE_BLOCK(completionBlock, error, responseObject);
    }];
    
    [dataTask resume];
    
#ifdef GJ_NETWORK_LOGGING
    NSLog(@"APIClient: PUT request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runGETRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    [self.jsonSessionManager GET:requestPath parameters:parameters progress:nil success:[self wrapSuccessBlock:completionBlock] failure:[self wrapFailureBlock:completionBlock]];
    
#ifdef GJ_NETWORK_LOGGING
    NSLog(@"APIClient: GET request: %@\n%@", requestPath, parameters);
#endif
}

- (void)runPUTRequestWithEndpoint:(NSString *)endpointPath parameters:(id)parameters completion:(APICompletionBlock)completionBlock
{
    //if (![self apiDomainReachable:completionBlock]) return;
    
    NSString *requestPath = [self requestPathWithEndpointPath:endpointPath];
    [self.jsonSessionManager PUT:requestPath parameters:parameters success:[self wrapSuccessBlock:completionBlock] failure:[self wrapFailureBlock:completionBlock]];
    
    NSLog(@"APIClient: PUT request: %@\n%@", requestPath, parameters);
}

#pragma mark - API Calls

- (void)getContactsWithCompletionBlock:(APICompletionBlock)completionBlock
{
    [self runGETRequestWithEndpoint:APIClientContactsURLPath parameters:nil completion:
     ^(NSError *error, NSDictionary *data) {
         if(data)
         {
             if([data isKindOfClass:[NSDictionary class]])
             {
                 NSArray *errors = (NSArray*)[data objectForKey:@"errors"];
                 if(errors)
                 {
                     NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Contacts Fetch Failed : %@", [errors componentsJoinedByString:@","]]}];
                     completionBlock(errorInfo, nil);
                 }
                 else
                 {
                     completionBlock(nil, data);
                 }
             }
             else
             {
                 completionBlock(nil, data);
             }
         }
         else if(error)
         {
             completionBlock(error, nil);
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
             completionBlock(error, nil);
         }
         else
         {
             completionBlock(nil, nil);
         }
     }];
}

- (void)postContact:(NSDictionary*)contactInfo withCompletionBlock:(APICompletionBlock)completionBlock
{
    NSString *requestPath = [self requestPathWithEndpointPath:APIClientContactsURLPath];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [manager POST:requestPath parameters:contactInfo progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionBlock(nil, (NSDictionary*)responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",errResponse);
        completionBlock(error, nil);
    }];
}

//- (void)postContact:(NSDictionary*)contactInfo withImageData:(NSData*)imageData withCompletionBlock:(APICompletionBlock)completionBlock
//{
//    NSString *requestPath = [self requestPathWithEndpointPath:@"contacts"];
//    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
//    manager.requestSerializer = [AFJSONRequestSerializer serializer];
//    [manager.requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
//    
//    [manager POST:requestPath parameters:contactInfo constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//        [formData appendPartWithFileData:imageData name:@"profile_pic" fileName:@"profile.png" mimeType:@"image/png"];}
//         progress:nil
//          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//              completionBlock(nil, responseObject);
//          }
//          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//              completionBlock(error, nil);
//          }];
//}

- (void)postContact:(NSDictionary*)contactInfo withImageData:(NSData*)imageData withCompletionBlock:(APICompletionBlock)completionBlock
{
    NSString *requestPath = [self requestPathWithEndpointPath:@"contacts"];
    NSMutableDictionary *body = [contactInfo mutableCopy];
    NSString *imageString = [imageData base64EncodedStringWithOptions:0];
    [body setValue:imageString forKey:@"profile_pic"];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:requestPath parameters:nil error:nil];
    
    req.timeoutInterval= [[[NSUserDefaults standardUserDefaults] valueForKey:@"timeoutInterval"] longValue];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [[manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        if (!error) {
            NSLog(@"Reply JSON: %@", responseObject);
            completionBlock(nil, responseObject);
        } else {
            NSLog(@"Error: %@, %@, %@", error, response, responseObject);
            completionBlock(error, nil);
        }
    }] resume];
}

//- (void)postContact:(NSDictionary *)contactInfo withImageData:(NSData *)imageData withCompletionBlock:(APICompletionBlock)completionBlock
//{
//    NSString *requestPath = [self requestPathWithEndpointPath:APIClientContactsURLPath];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestPath]];
//    
//    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
//    [request setHTTPShouldHandleCookies:NO];
//    [request setTimeoutInterval:60];
//    [request setHTTPMethod:@"POST"];
//    
//    NSString *boundary = @"9A308E53-3D8C-47EF-B2B7-4DFF9AE74A0E";
//    
//    // set Content-Type in HTTP header
//    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
//    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
//    
//    // post body
//    NSMutableData *body = [NSMutableData data];
//    
//    [contactInfo enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
//        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
//    }];
//    
//    // add image data
//    if (imageData) {
//        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=imageName.jpg\r\n", @"imageFormKey"] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:imageData];
//        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    }
//    
//    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    // setting the body of the post to the reqeust
//    [request setHTTPBody:body];
//    
//    // set the content-length
//    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
//    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//    
//    
//    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
//        
//        if (!error) {
//            NSError *jsonError = nil;
//            NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
//            if (jsonError)
//            {
//                NSLog(@"Error parsing JSON.");
//            }
//            else
//            {
//                NSLog(@"Response: %@", responseObject);
//            }
//            
//            completionBlock(nil, responseObject);
//        }
//        else
//        {
//            NSLog(@"Error: %@, %@", error, response);
//            completionBlock(error, nil);
//        }
//    }];
//}

- (void)updateContact:(NSDictionary*)contactInfo withCompletionBlock:(APICompletionBlock)completionBlock
{
    NSString *path = [NSString stringWithFormat:APIClientGetContactDetailsURLPath, [contactInfo objectForKey:@"id"]];
    
    [self runPUTRequestWithEndpoint:path parameters:contactInfo completion:
     ^(NSError *error, NSDictionary *data) {
         
         NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
         NSLog(@"%@",errResponse);
         
         if(data)
         {
             NSArray *errors = (NSArray*)[data objectForKey:@"errors"];
             if(errors)
             {
                 NSError *errorInfo = [NSError errorWithDomain:@"GJ" code:1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Contact Update Failed : %@", [errors componentsJoinedByString:@","]]}];
                 completionBlock(errorInfo, nil);
             }
             else
             {
                 completionBlock(nil, data);
             }
         }
         else if(error)
         {
             completionBlock(error, nil);
         }
         else
         {
             completionBlock(nil, nil);
         }
     }];
}

- (void)uploadImage:(NSData *)imageData withCompletionBlock:(APICompletionBlock)completionBlock
{   
    [self runPOSTRequestWithEndpoint:APIUploadImageURLPath parameters:nil bodyConstructingBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"upload" fileName:@"profile.jpg" mimeType:@"image/jpeg"];        
        NSData *daysData = [@"7" dataUsingEncoding:NSUTF8StringEncoding];
        [formData appendPartWithFormData:daysData name:@"data[days]"];
        
    } completion:^(NSError *error, id data) {
        if(data)
        {
            completionBlock(nil, data);
        }
        else if(error)
        {
            completionBlock(error, nil);
        }
        else
        {
            completionBlock(nil, nil);
        }
    }];
}

@end
