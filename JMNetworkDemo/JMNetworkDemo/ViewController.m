//
//  ViewController.m
//  JMNetworkDemo
//
//  Created by James.xiao on 2016/10/13.
//  Copyright © 2016年 James.xiao. All rights reserved.
//

#import "ViewController.h"
#import <JMNetwork.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    JMRequest *request = [[JMRequest alloc] init];
    request.requestUrl = @"https://www.baidu.com/";
    [request startWithCompletionBlockWithSuccess:^(__kindof JMBaseRequest * _Nonnull request) {
        
    } failure:^(__kindof JMBaseRequest * _Nonnull request) {
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
