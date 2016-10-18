//
//  JMNetworkPrivate.h
//  JMNetwork
//
//  Created by James.xiao on 2016/10/14.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMBaseRequest.h"
#import "JMNetworkConfig.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void JMNetworkLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@interface JMNetworkUtils : NSObject

+ (NSStringEncoding)stringEncodingWithRequest:(JMBaseRequest *)request;
+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;

@end

@interface JMBaseRequest(Setter)

@property (nonatomic, strong, readwrite)            NSURLSessionTask    *requestTask;
@property (nonatomic, strong, readwrite)            NSHTTPURLResponse   *response;
@property (nonatomic, strong, readwrite, nullable)  NSData              *responseData;
@property (nonatomic, strong, readwrite, nullable)  NSString            *responseString;
@property (nonatomic, strong, readwrite, nullable)  id                  responseObject;
@property (nonatomic, strong, readwrite, nullable)  id                  responseJSONObject;
@property (nonatomic, strong, readwrite, nullable)  NSError             *error;

@end

@interface JMNetworkPrivate : NSObject

@end

NS_ASSUME_NONNULL_END
