//
//  JMBaseRequest.h
//  JMNetwork
//
//  Created by James.xiao on 2016/10/13.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AFHTTPSessionManager;

FOUNDATION_EXPORT NSString *const JMNetworkRequestValidationErrorDomain;

/// 请求响应验证错误类型.
NS_ENUM(NSInteger) {
    JMRequestValidationErrorInvalidStatusCode = -8,
    JMRequestValidationErrorInvalidJSONFormat = -9,
};
    
/// 请求方法.
typedef NS_ENUM(NSInteger, JMRequestMethod) {
    JMRequestMethodGET = 0,
    JMRequestMethodPOST,
    JMRequestMethodHEAD,
    JMRequestMethodPUT,
    JMRequestMethodDELETE,
    JMRequestMethodPATCH,
};

/// 请求序列化器类型.
typedef NS_ENUM(NSInteger, JMRequestSerializerType) {
    JMRequestSerializerTypeHTTP = 0,
    JMRequestSerializerTypeJSON,
};

/// 响应序列化器类型.
typedef NS_ENUM(NSInteger, JMResponseSerializerType) {
    JMResponseSerializerTypeHTTP,
    JMResponseSerializerTypeJSON,
    JMResponseSerializerTypeXMLParser,
    JMResponseSerializerTypeImage,
};
    
/// 请求优先级.
typedef NS_ENUM(NSInteger, JMRequestPriority) {
    JMRequestPriorityLow        = -4L,
    JMRequestPriorityDefault    = 0,
    JMRequestPriorityHigh       = 4,
};
    
@protocol AFMultipartFormData;
    
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);

@interface JMBaseRequest : NSObject

typedef void(^JMRequestCompletionBlock)(__kindof JMBaseRequest *request);
typedef _Nullable id(^JMJsonValidatorBlock)(void);

#pragma mark - Request Configuration
/// 请求的baseURL(此设置优先于JMNetworkConfig的baseUrl),默认@"".
@property (nonatomic, strong)               NSString                *baseUrl;

/// 请求的Url,如果是合法的url,那么baseUrl将被忽略.
@property (nonatomic, strong)               NSString                *requestUrl;

/// 请求的cdnUrl(此设置优先于JMNetworkConfig的cdnUrl),默认@"".
@property (nonatomic, strong)               NSString                *cdnUrl;

/// 请求是否使用CDN.
@property (nonatomic, assign)               BOOL                    isUseCDN;

/// 请求超时时间,默认60s.
@property (nonatomic, assign)               NSTimeInterval          requestTimeoutInterval;

/// 请求方法,默认JMRequestMethodGET.
@property (nonatomic, assign)               JMRequestMethod         requestMethod;

/// 请求序列化器,默认JMRequestSerializerTypeHTTP.
@property (nonatomic, assign)               JMRequestSerializerType requestSerializerType;

/// 请求参数.
@property (nonatomic, strong, nullable)     id                      requestArgument;

/// Post请求可设置,默认nil
@property (nonatomic, copy, nullable)       AFConstructingBlock     constructingBodyBlock;

/// 请求授权,格式必须是@[@"Username",@"Password"].
@property (nonatomic, strong, nullable)     NSArray<NSString *>     *requestAuthorizationHeaderFieldArray;

/// 请求头部设置.
@property (nonatomic, strong, nullable)     NSDictionary<NSString *, NSString *> *requestHeaderFieldValueDictionary;

/// 请求是否允许使用蜂窝网络,默认YES.
@property (nonatomic, assign)               BOOL                    allowsCellularAccess;

/// 自定义NSURLRequest,当不为空时,以下属性的设置将被忽略.
/// 'baseUrl','requestUrl','cdnUrl','isUseCDN','requestTimeoutInterval','requestMethod','requestSerializerType','requestArgument'
@property (nonatomic, strong, nullable)     NSURLRequest            *customUrlRequest;

/// 自定义AFHTTPSessionManager,默认为nil.
@property (nonatomic, strong, nullable)     AFHTTPSessionManager    *customManager;

///  请求优先级,需要iOS8以上版本,默认`JMRequestPriorityDefault`.
@property (nonatomic, assign)               JMRequestPriority       requestPriority;

/// 请求成功处理Block.
@property (nonatomic, copy, nullable) JMRequestCompletionBlock successCompletionBlock;

/// 请求失败处理Block.
@property (nonatomic, copy, nullable) JMRequestCompletionBlock failureCompletionBlock;

/// 设置请求结果处理Block.
- (void)setCompletionBlockWithSuccess:(nullable JMRequestCompletionBlock)success
                              failure:(nullable JMRequestCompletionBlock)failure;

/// 清除请求结果处理Block.
- (void)clearCompletionBlock;

#pragma mark - Request Action
/// 开始请求.
- (void)start;

/// 停止请求.
- (void)stop;

/// 开始请求.
- (void)startWithCompletionBlockWithSuccess:(JMRequestCompletionBlock)success
                                    failure:(JMRequestCompletionBlock)failure;

#pragma mark - Request And Response Information
/// 响应序列化器.
@property (nonatomic, assign)               JMResponseSerializerType    responseSerializerType;

/// 请求任务.
@property (nonatomic, strong, readonly)     NSURLSessionTask            *requestTask;

/// 请求响应'requestTask.response'.
@property (nonatomic, strong, readonly)     NSHTTPURLResponse           *response;

/// 请求响应返回NSData类型数据.
@property (nonatomic, strong, readonly, nullable) NSData                *responseData;

/// 请求响应返回NSData类型数据转字符串数据.
@property (nonatomic, strong, readonly, nullable) NSString              *responseString;

/// 请求响应返回对象.
@property (nonatomic, strong, readonly, nullable) id                    responseObject;

/// 请求响应返回Json对象(使用'JMResponseSerializerTypeJSON'时,否则为nil).
@property (nonatomic, strong, readonly, nullable) id                    responseJSONObject;

/// 请求响应错误信息.
@property (nonatomic, strong, readonly, nullable) NSError               *error;

/// 返回json数据验证.
@property (nonatomic, copy, nullable) JMJsonValidatorBlock              jsonValidatorBlock;

#pragma mark - Public
- (BOOL)statusCodeValidator;

@end

NS_ASSUME_NONNULL_END
