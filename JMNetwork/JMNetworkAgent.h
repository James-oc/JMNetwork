//
//  JMNetworkAgent.h
//  JMNetwork
//
//  Created by James.xiao on 2016/10/13.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class JMBaseRequest;

@interface JMNetworkAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 返回单例
+ (JMNetworkAgent *)sharedAgent;

/// 发送请求
- (void)addRequest:(JMBaseRequest *)request;

/// 取消某个请求
- (void)cancelRequest:(JMBaseRequest *)request;

/// 取消所有请求
- (void)cancelAllRequest;

@end

NS_ASSUME_NONNULL_END
