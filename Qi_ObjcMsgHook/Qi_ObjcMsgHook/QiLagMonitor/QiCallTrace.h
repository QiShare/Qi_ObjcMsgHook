//
//  QiCallTrace.h
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QiCallTraceCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface QiCallTrace : NSObject

+ (void)start; //开始记录
+ (void)startWithMaxDepth:(int)depth;
+ (void)startWithMinCost:(double)ms;
+ (void)startWithMaxDepth:(int)depth minCost:(double)ms;
+ (void)stop; //停止记录
+ (void)save; //保存和打印记录，如果不是短时间 stop 的话使用 saveAndClean
+ (void)stopSaveAndClean; //停止保存打印并进行内存清理

@end

NS_ASSUME_NONNULL_END
