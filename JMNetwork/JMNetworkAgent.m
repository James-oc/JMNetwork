//
//  JMNetworkAgent.m
//  JMNetwork
//
//  Created by James.xiao on 2016/10/13.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import "JMNetworkAgent.h"
#import "JMNetworkPrivate.h"
#import "JMBaseRequest.h"
#import "JMNetworkConfig.h"
#import <pthread/pthread.h>

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock()   pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@implementation JMNetworkAgent {
    AFHTTPSessionManager            *_manager;
    JMNetworkConfig                 *_config;
    NSIndexSet                      *_allStatusCodes;
    dispatch_queue_t                _processingQueue;
    pthread_mutex_t                 _lock;
    NSMutableDictionary<NSNumber *, JMBaseRequest *> *_requestsRecord;
    AFJSONResponseSerializer        *_jsonResponseSerializer;
    AFXMLParserResponseSerializer   *_xmlParserResponseSerialzier;
    AFImageResponseSerializer       *_imageResponseSerialzier;
}

+ (JMNetworkAgent *)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config                     = [JMNetworkConfig sharedConfig];
        _requestsRecord             = [NSMutableDictionary dictionary];
        
        _manager                    = [AFHTTPSessionManager manager];
        _manager.securityPolicy     = _config.securityPolicy;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];

        _allStatusCodes             = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        
        _processingQueue            = dispatch_queue_create("jm.networkagent.processing", DISPATCH_QUEUE_CONCURRENT);
        _manager.completionQueue    = _processingQueue;
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes  = _allStatusCodes;
        _jsonResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html" ,@"image/png", nil];
    }
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    if (!_xmlParserResponseSerialzier) {
        _xmlParserResponseSerialzier                        = [AFXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes  = _allStatusCodes;
        _xmlParserResponseSerialzier.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html" ,@"image/png", nil];
    }
    return _xmlParserResponseSerialzier;
}

- (AFImageResponseSerializer *)imageResponseSerialzier {
    if (!_imageResponseSerialzier) {
        _imageResponseSerialzier                        = [AFImageResponseSerializer serializer];
        _imageResponseSerialzier.acceptableStatusCodes  = _allStatusCodes;
        _imageResponseSerialzier.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html" ,@"image/png", nil];
    }
    return _imageResponseSerialzier;
}

#pragma mark - Request Action
/// 发送请求
- (void)addRequest:(JMBaseRequest *)request {
    NSError * __autoreleasing requestSerializationError = nil;

    NSURLRequest *customUrlRequest= request.customUrlRequest;
    if (customUrlRequest) {
        __block NSURLSessionDataTask *dataTask = nil;
        dataTask = [_manager dataTaskWithRequest:customUrlRequest
                               completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                   [self handleRequestResult:dataTask
                                              responseObject:responseObject
                                                       error:error];
                               }];
        request.requestTask = dataTask;
    }else {
        request.requestTask = [self sessionTaskForRequest:request
                                                    error:&requestSerializationError];
    }
    
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request
                                  error:requestSerializationError];
        return;
    }
    
    // Set request task priority
    // !!Available on iOS 8 +
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case JMRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case JMRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case JMRequestPriorityDefault:
                /*!!fall through*/
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }

    JMNetworkLog(@"Add request: %@", NSStringFromClass([request class]));
    [self addRequestToRecord:request];
    [request.requestTask resume];
}

- (void)cancelRequest:(JMBaseRequest *)request {
    [request.requestTask cancel];
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequest {
    [_manager.operationQueue cancelAllOperations];
}

- (NSURLSessionTask *)sessionTaskForRequest:(JMBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    JMRequestMethod method                      = request.requestMethod;
    NSString *url                               = [self buildRequestUrl:request];
    id param                                    = request.requestArgument;
    AFConstructingBlock constructingBlock       = [request constructingBodyBlock];
    AFHTTPRequestSerializer *requestSerializer  = [self requestSerializerForRequest:request];
    
    switch (method) {
        case JMRequestMethodGET:
            return [self dataTaskWithHTTPMethod:@"GET" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case JMRequestMethodPOST:
            return [self dataTaskWithHTTPMethod:@"POST" requestSerializer:requestSerializer URLString:url parameters:param constructingBodyWithBlock:constructingBlock error:error];
        case JMRequestMethodHEAD:
            return [self dataTaskWithHTTPMethod:@"HEAD" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case JMRequestMethodPUT:
            return [self dataTaskWithHTTPMethod:@"PUT" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case JMRequestMethodDELETE:
            return [self dataTaskWithHTTPMethod:@"DELETE" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case JMRequestMethodPATCH:
            return [self dataTaskWithHTTPMethod:@"PATCH" requestSerializer:requestSerializer URLString:url parameters:param error:error];
    }
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method requestSerializer:requestSerializer URLString:URLString parameters:parameters constructingBodyWithBlock:nil error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;
    
    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method
                                                          URLString:URLString
                                                         parameters:parameters
                                          constructingBodyWithBlock:block
                                                              error:error];
    } else {
        request = [requestSerializer requestWithMethod:method
                                             URLString:URLString
                                            parameters:parameters
                                                 error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request
                           completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
                               [self handleRequestResult:dataTask responseObject:responseObject error:_error];
                           }];
    
    return dataTask;
}

#pragma mark - Private
- (void)addRequestToRecord:(JMBaseRequest *)request {
    if (request.requestTask != nil) {
        Lock();
        _requestsRecord[@(request.requestTask.taskIdentifier)] = request;
        Unlock();
    }
}

- (void)removeRequestFromRecord:(JMBaseRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
    JMNetworkLog(@"Request queue size = %zd", [_requestsRecord count]);
    Unlock();
}

- (void)handleRequestResult:(NSURLSessionTask *)task
             responseObject:(id)responseObject
                      error:(NSError *)error {
    Lock();
    JMBaseRequest *request = _requestsRecord[@(task.taskIdentifier)];
    Unlock();
    
    if (!request) {
        return;
    }
    
    JMNetworkLog(@"Finished Request: %@", NSStringFromClass([request class]));

    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError    = nil;
    NSError *requestError                        = nil;
    BOOL    succeed                              = NO;

    request.responseObject      = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData    = responseObject;
        request.responseString  = [[NSString alloc] initWithData:responseObject encoding:[JMNetworkUtils stringEncodingWithRequest:request]];

        switch (request.responseSerializerType) {
            case JMResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case JMResponseSerializerTypeJSON:
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                request.responseJSONObject = request.responseObject;
                break;
            case JMResponseSerializerTypeXMLParser:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                break;
            case JMResponseSerializerTypeImage:
                request.responseObject = [self.imageResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                break;
        }
    }
    
    if (error) {
        succeed = NO;
        requestError = error;
    }else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    }else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }

    if (succeed) {
        JMNetworkLog(@"Request:%@\nParams:%@\nResponse:%@",task.currentRequest.URL.absoluteString, request.requestArgument, request.responseJSONObject ? : request.responseString);
        [self requestDidSucceedWithRequest:request];
    } else {
        JMNetworkLog(@"Request:%@\nParams:%@\nRequestError:%@",task.currentRequest.URL.absoluteString, request.requestArgument, requestError);
        [self requestDidFailWithRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (void)requestDidSucceedWithRequest:(JMBaseRequest *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
    });
}

- (void)requestDidFailWithRequest:(JMBaseRequest *)request error:(NSError *)error {
    request.error = error;
    JMNetworkLog(@"Request %@ failed, status code = %ld, error = %@",
           NSStringFromClass([request class]), (long)request.response.statusCode, error.localizedDescription);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
    });
}

- (BOOL)validateResult:(JMBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:JMNetworkRequestValidationErrorDomain code:JMRequestValidationErrorInvalidStatusCode userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
        }
        return result;
    }
    
    id validator = nil;
    if (request.jsonValidatorBlock) {
        validator = request.jsonValidatorBlock();
    }
    
    if (validator) {
        id json = request.responseJSONObject;
        if (json) {
            result = [JMNetworkUtils validateJSON:json withValidator:validator];
            if (!result) {
                if (error) {
                    *error = [NSError errorWithDomain:JMNetworkRequestValidationErrorDomain code:JMRequestValidationErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
                }
                return result;
            }
        }
    }
    return YES;
}

- (NSString *)buildRequestUrl:(JMBaseRequest *)request {
    NSString *detailUrl = request.requestUrl;
    NSURL *temp         = [NSURL URLWithString:detailUrl];
    // 合法的Url
    if (temp && temp.host && temp.scheme) {
        return detailUrl;
    }
    
    NSString *baseUrl;
    if (request.isUseCDN) {
        if (request.cdnUrl.length > 0) {
            baseUrl = request.cdnUrl;
        } else {
            baseUrl = _config.cdnUrl;
        }
    } else {
        if (request.baseUrl.length > 0) {
            baseUrl = request.baseUrl;
        } else {
            baseUrl = _config.baseUrl;
        }
    }
    
    NSURL *url = [NSURL URLWithString:baseUrl];
    
    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(JMBaseRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == JMRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == JMRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    requestSerializer.timeoutInterval       = request.requestTimeoutInterval;
    requestSerializer.allowsCellularAccess  = request.allowsCellularAccess;
    
    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
                                                          password:authorizationHeaderFieldArray.lastObject];
    }
    
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    return requestSerializer;
}

@end
