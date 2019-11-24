//
//  QiCallStackModel.h
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QiCallStackModel : NSObject

@property (nonatomic, copy) NSString *stackStr;       //完整堆栈信息
@property (nonatomic) BOOL isStuck;                   //是否被卡住
@property (nonatomic, assign) NSTimeInterval dateString;   //可展示信息

@end

NS_ASSUME_NONNULL_END
