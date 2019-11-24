//
//  QiLagMonitor.m
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import "QiLagMonitor.h"
#import "QiCallStack.h"
#import "QiCallStackModel.h"
#import "QiCPUMonitor.h"
#import "QiLagDB.h"

@interface QiLagMonitor() {
    int timeoutCount;
    CFRunLoopObserverRef runLoopObserver;
    @public
    dispatch_semaphore_t dispatchSemaphore;
    CFRunLoopActivity runLoopActivity;
}
@property (nonatomic, strong) NSTimer *cpuMonitorTimer;
@end

@implementation QiLagMonitor

#pragma mark - Interface
+ (instancetype)shareInstance {
    static id instance = nil;
    static dispatch_once_t dispatchOnce;
    dispatch_once(&dispatchOnce, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)beginMonitor {
    self.isMonitoring = YES;
    //监测 CPU 消耗
    self.cpuMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                             target:self
                                                           selector:@selector(updateCPUInfo)
                                                           userInfo:nil
                                                            repeats:YES];
    //监测卡顿
    if (runLoopObserver) {
        return;
    }
    dispatchSemaphore = dispatch_semaphore_create(0); //Dispatch Semaphore保证同步
    //创建一个观察者
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    runLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                              kCFRunLoopAllActivities,
                                              YES,
                                              0,
                                              &runLoopObserverCallBack,
                                              &context);
    //将观察者添加到主线程runloop的common模式下的观察中
    CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes);
    
    //创建子线程监控
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //子线程开启一个持续的loop用来进行监控
        while (YES) {
            long semaphoreWait = dispatch_semaphore_wait(self->dispatchSemaphore, dispatch_time(DISPATCH_TIME_NOW, STUCKMONITORRATE * NSEC_PER_MSEC));
            if (semaphoreWait != 0) {
                if (!self->runLoopObserver) {
                    self->timeoutCount = 0;
                    self->dispatchSemaphore = 0;
                    self->runLoopActivity = 0;
                    return;
                }
                //两个runloop的状态，BeforeSources和AfterWaiting这两个状态区间时间能够检测到是否卡顿
                if (self->runLoopActivity == kCFRunLoopBeforeSources || self->runLoopActivity == kCFRunLoopAfterWaiting) {
                    //出现三次出结果
                    if (++self->timeoutCount < 3) {
                        continue;
                    }
//                    NSLog(@"monitor trigger");
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        NSString *stackStr = [QiCallStack callStackWithType:QiCallStackTypeMain];
                        QiCallStackModel *model = [[QiCallStackModel alloc] init];
                        model.stackStr = stackStr;
                        model.isStuck = YES;
                        [[[QiLagDB shareInstance] increaseWithStackModel:model] subscribeNext:^(id x) {}];
                    });
                } //end activity
            }// end semaphore wait
            self->timeoutCount = 0;
        }// end while
    });
    
}

- (void)endMonitor {
    self.isMonitoring = NO;
    [self.cpuMonitorTimer invalidate];
    if (!runLoopObserver) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes);
    CFRelease(runLoopObserver);
    runLoopObserver = NULL;
}

#pragma mark - Private
- (void)updateCPUInfo {
    [QiCPUMonitor updateCPU];
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    QiLagMonitor *lagMonitor = (__bridge QiLagMonitor*)info;
    lagMonitor->runLoopActivity = activity;
    
    dispatch_semaphore_t semaphore = lagMonitor->dispatchSemaphore;
    dispatch_semaphore_signal(semaphore);
}
@end
