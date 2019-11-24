//
//  QiLagDB.h
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <fmdb/FMDB.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import "QiCallTraceTimeCostModel.h"
#import "QiCallStackModel.h"

NS_ASSUME_NONNULL_BEGIN

#define PATH_OF_APP_HOME    NSHomeDirectory()
#define PATH_OF_TEMP        NSTemporaryDirectory()
#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define CPUMONITORRATE 80
#define STUCKMONITORRATE 88

@interface QiLagDB : NSObject

+ (QiLagDB *)shareInstance;
/*------------卡顿和CPU超标堆栈---------------*/
- (RACSignal *)increaseWithStackModel:(QiCallStackModel *)model;
- (RACSignal *)selectStackWithPage:(NSUInteger)page;
- (void)clearStackData;
/*------------ClsCall方法调用频次-------------*/
//添加记录s
- (void)addWithClsCallModel:(QiCallTraceTimeCostModel *)model;
//分页查询
- (RACSignal *)selectClsCallWithPage:(NSUInteger)page;
//清除数据
- (void)clearClsCallData;

@end

NS_ASSUME_NONNULL_END
