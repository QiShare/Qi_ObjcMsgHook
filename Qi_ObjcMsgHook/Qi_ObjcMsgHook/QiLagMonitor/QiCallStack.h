//
//  QiCallStack.h
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QiCallLib.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, QiCallStackType) {
    QiCallStackTypeAll,     //全部线程
    QiCallStackTypeMain,    //主线程
    QiCallStackTypeCurrent  //当前线程
};


@interface QiCallStack : NSObject

+ (NSString *)callStackWithType:(QiCallStackType)type;

extern NSString *qiStackOfThread(thread_t thread);

@end

NS_ASSUME_NONNULL_END
