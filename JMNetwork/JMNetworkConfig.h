//
//  JMNetworkConfig.h
//  JMNetwork
//
//  Created by James.xiao on 2016/10/13.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AFSecurityPolicy;

@interface JMNetworkConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new  NS_UNAVAILABLE;

/// 返回单例
+ (JMNetworkConfig *)sharedConfig;

/// 是否打印日志信息,默认NO
@property (nonatomic, assign) BOOL             debugLogEnabled;
/// 所有请求的baseURL,默认@""
@property (nonatomic, strong) NSString         *baseUrl;
/// 所有请求的CDNURL,默认@""
@property (nonatomic, strong) NSString         *cdnUrl;
/// 访问控制
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

@end

NS_ASSUME_NONNULL_END
