//
//  QiCallTraceTimeCostModel.m
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#import "QiCallTraceTimeCostModel.h"

@implementation QiCallTraceTimeCostModel

- (NSString *)des {
    NSMutableString *str = [NSMutableString new];
    [str appendFormat:@"%2d| ",(int)_callDepth];
    [str appendFormat:@"%6.2f|",_timeCost * 1000.0];
    for (NSUInteger i = 0; i < _callDepth; i++) {
        [str appendString:@"  "];
    }
    [str appendFormat:@"%s[%@ %@]", (_isClassMethod ? "+" : "-"), _className, _methodName];
    return str;
}

@end
