//
//  JMBaseRequest.m
//  JMNetwork
//
//  Created by James.xiao on 2016/10/13.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import "JMBaseRequest.h"
#import "JMNetworkAgent.h"
#import "JMNetworkPrivate.h"

NSString *const JMNetworkRequestValidationErrorDomain = @"jm.network.request.validation";

@interface JMBaseRequest()

@property (nonatomic, strong, readwrite)            NSURLSessionTask    *requestTask;
@property (nonatomic, strong, readwrite)            NSHTTPURLResponse   *response;
@property (nonatomic, strong, readwrite, nullable)  NSData              *responseData;
@property (nonatomic, strong, readwrite, nullable)  NSString            *responseString;
@property (nonatomic, strong, readwrite, nullable)  id                  responseObject;
@property (nonatomic, strong, readwrite, nullable)  id                  responseJSONObject;
@property (nonatomic, strong, readwrite, nullable)  NSError             *error;

@end

@implementation JMBaseRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _baseUrl                = @"";
        _requestUrl             = @"";
        _cdnUrl                 = @"";
        _isUseCDN               = NO;
        _requestTimeoutInterval = 60;
        _requestMethod          = JMRequestMethodGET;
        _requestSerializerType  = JMRequestSerializerTypeHTTP;
        _allowsCellularAccess   = YES;
        _requestPriority        = JMRequestPriorityDefault;
    }
    return self;
}

#pragma mark - Request Configuration
- (void)setCompletionBlockWithSuccess:(nullable JMRequestCompletionBlock)success
                              failure:(nullable JMRequestCompletionBlock)failure {
    _successCompletionBlock = success;
    _failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    _successCompletionBlock = nil;
    _failureCompletionBlock = nil;
}

#pragma mark - Request Action
- (void)start {
    [[JMNetworkAgent sharedAgent] addRequest:self];
}

- (void)stop {
    [[JMNetworkAgent sharedAgent] cancelRequest:self];
}

- (void)startWithCompletionBlockWithSuccess:(JMRequestCompletionBlock)success
                                    failure:(JMRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

#pragma mark - Request And Response Information
- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

#pragma mark - Public
- (BOOL)statusCodeValidator {
    NSInteger statusCode = self.response.statusCode;
    if (statusCode >= 200 && statusCode <= 299) {
        return YES;
    } else {
        return NO;
    }
}

@end
