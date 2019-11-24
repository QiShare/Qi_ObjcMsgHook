//
//  QiLagMonitor.h
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QiLagMonitor : NSObject

+ (instancetype)shareInstance;

@property (nonatomic) BOOL isMonitoring;

- (void)beginMonitor; //开始监视卡顿
- (void)endMonitor;   //停止监视卡顿

@end

NS_ASSUME_NONNULL_END
