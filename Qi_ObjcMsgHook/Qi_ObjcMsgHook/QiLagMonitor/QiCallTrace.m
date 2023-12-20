//
//  QiCallTrace.m
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import "QiCallTrace.h"
#import "QiCallLib.h"
#import "QiCallTraceTimeCostModel.h"
#import "QiLagDB.h"

@implementation QiCallTrace

#pragma mark - Trace
#pragma mark - OC Interface

+ (void)start {
    qiCallTraceStart();
}

+ (void)startWithMaxDepth:(int)depth {
    qiCallConfigMaxDepth(depth);
    [QiCallTrace start];
}

+ (void)startWithMinCost:(double)ms {
    qiCallConfigMinTime(ms * 1000);
    [QiCallTrace start];
}

+ (void)startWithMaxDepth:(int)depth minCost:(double)ms {
    qiCallConfigMaxDepth(depth);
    qiCallConfigMinTime(ms * 1000);
    [QiCallTrace start];
}

+ (void)stop {
    qiCallTraceStop();
}

+ (void)save {
    NSMutableString *mStr = [NSMutableString new];
    NSArray<QiCallTraceTimeCostModel *> *arr = [self loadRecords];
    for (QiCallTraceTimeCostModel *model in arr) {
        //记录方法路径
        model.path = [NSString stringWithFormat:@"[%@ %@]",model.className, model.methodName];
        [self appendRecord:model to:mStr];
    }
    
    NSLog(@"\n%@",mStr);
}

+ (void)stopSaveAndClean {
    [QiCallTrace stop];
    [QiCallTrace save];
    qiClearCallRecords();
}

+ (void)appendRecord:(QiCallTraceTimeCostModel *)cost to:(NSMutableString *)mStr {
    [mStr appendFormat:@"%@\n", [cost des]];
//    [mStr appendFormat:@"%@\n path%@\n", [cost des], cost.path];
    if (cost.subCosts.count < 1) {
        cost.lastCall = YES;
        //记录到数据库中
        [[QiLagDB shareInstance] addWithClsCallModel:cost];
    } else {
        for (QiCallTraceTimeCostModel *model in cost.subCosts) {
            if ([model.className isEqualToString:@"QiCallTrace"]) {
                break;
            }
            //记录方法的子方法的路径
            model.path = [NSString stringWithFormat:@"%@ - [%@ %@]",cost.path,model.className,model.methodName];
            [self appendRecord:model to:mStr];
        }
    }
    
}

+ (NSArray<QiCallTraceTimeCostModel *>*)loadRecords {
    NSMutableArray<QiCallTraceTimeCostModel *> *arr = [NSMutableArray new];
    int num = 0;
    qiCallRecord *records = qiGetCallRecords(&num);
    for (int i = 0; i < num; i++) {
        qiCallRecord *rd = &records[i];
        QiCallTraceTimeCostModel *model = [QiCallTraceTimeCostModel new];
        model.className = NSStringFromClass(rd->cls);
        model.methodName = NSStringFromSelector(rd->sel);
        model.isClassMethod = class_isMetaClass(rd->cls);
        model.timeCost = (double)rd->time / 1000000.0;
        model.callDepth = rd->depth;
        model.lr = rd->lr;
        
        if (rd->caller_record != NULL) {
            model.callerLr = rd->caller_record->lr;
        }

        [arr addObject:model];
    }
    NSUInteger count = arr.count;
    for (NSUInteger i = 0; i < count; i++) {
        QiCallTraceTimeCostModel *model = arr[i];
        if (model.callDepth > 0) {
            [arr removeObjectAtIndex:i];
            //Todo:不需要循环，直接设置下一个，然后判断好边界就行
            for (NSUInteger j = i; j < count - 1; j++) {
                // 下一个深度小的话就开始将后面的递归的往 sub array 里添加
                // ⚠️⚠️ 这里的bug：不能根据 callDepth 来判断，不然所有层级相等的深度，都在一个调用链路中了
                // 需要根据调用链路来关联
                if (arr[j].lr == model.callerLr) {
                    NSMutableArray *sub = (NSMutableArray *)arr[j].subCosts;
                    if (!sub) {
                        sub = [NSMutableArray new];
                        arr[j].subCosts = sub;
                    }
                    if (![sub containsObject:model]) {
                        [sub addObject:model];
                    }
                }
            }
            i--;
            count--;
        }
    }
    return arr;
}

@end
