//
//  JMNetwork.h
//  JMNetwork
//
//  Created by James.xiao on 2016/10/13.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef _JMNETWORK_
#define _JMNETWORK_

#if __has_include(<JMNetwork/JMNetwork.h>)

FOUNDATION_EXPORT double YTKNetworkVersionNumber;
FOUNDATION_EXPORT const unsigned char YTKNetworkVersionString[];

#import <JMNetwork/JMBaseRequest.h>
#import <JMNetwork/JMRequest.h>
#import <JMNetwork/JMNetworkAgent.h>
#import <JMNetwork/JMNetworkConfig.h>
#import <JMNetwork/JMNetworkReachabilityManager.h>

#else

#import "JMBaseRequest.h"
#import "JMRequest.h"
#import "JMNetworkAgent.h"
#import "JMNetworkConfig.h"
#import "JMNetworkReachabilityManager.h"

#endif

#endif
