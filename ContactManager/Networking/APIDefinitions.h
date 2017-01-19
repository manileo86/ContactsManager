//
//  APIDefinitions.h
//  ContactManager
//
//  Created by Manigandan Parthasarathi on 17/01/17.
//

/* Defines */

static NSString * const APIUrlPath                         = @"https://gojek-contacts-app.herokuapp.com";

/* API*/

/* Authenticate */

static NSString * const APIClientGetContactsURLPath                    = @"contacts.json";

/* Request headers */
static NSString * const APIContentTypeHeader                         = @"application/json; charset=utf-8";
static NSString * const APIContentTypeMultipartHeader                = @"multipart/form-data";
static NSString * const APIAcceptHeader                              = @"*/*";
static NSString * const APIAcceptEncodingHeader                      = @"gzip,deflate";

/**
 *  Requests parameters
 */
/* Registration */
static NSString * const APIEmailRequestFieldKey              = @"email";
static NSString * const APIPhoneRequestFieldKey              = @"phone";
static NSString * const APICountryCodeRequestFieldKey        = @"country_code";
static NSString * const APIActivationCodeRequestFieldKey     = @"activation_code";

/**
 *  Response parameters
 */
/* Errors */
static NSString * const APIErrorResponseFieldKey             = @"error";
static NSString * const APIErrorCodeResponseFieldKey         = @"code";
static NSString * const APIErrorDesriptionFieldKey           = @"message";

/* Error handling */
static const NSUInteger CFNetworkConnectionErrorCode            = -1009;
static NSString * const APIClientErrorDomain                 = @"APIClientErrorDomain";

/* Local errors */
static const NSUInteger APIErrorOkErrorCode                  = 0;
static NSString * const APIErrorOkDescription                = @"OK";
static const NSUInteger APIHTTPErrorCode                     = 101;
static NSString * const APIHTTPErrorDescription              = @"Backend sent non-successfull HTTP status code. See NSUnderlyingError for details.";
static const NSUInteger APINoResponseErrorCode               = 102;
static NSString * const APINoResponseErrorDescription        = @"Backend didn't send any response. I'm sorry.";
static const NSUInteger APIErrorMissingErrorCode             = 103;
static NSString * const APIErrorMissingErrorDescription      = @"Backend didn't send error entity in response. That's bad.";
static const NSUInteger APINotReachableErrorCode             = 104;
static NSString * const APINotReachableErrorDescription      = @"API domain not reachable";

/* Backend errors */
static const NSUInteger APIEmailTakenErrorCode               = 9003;

/* Types */
typedef void (^APICompletionBlock)(NSError *error, id data);

typedef void (^AFNSuccessBlock)(NSURLSessionDataTask *task, id responseObject);
typedef void (^AFNFailureBlock)(NSURLSessionDataTask *task, NSError *error);

/* Notifications */
static NSString * const BackendReachabilityChangedNotification   = @"GJBackendReachabilityChangedNotification";
static NSString * const BackendReachabilityStatusKey             = @"GJBackendReachabilityStatusKey";
