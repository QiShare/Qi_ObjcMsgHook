//
//  QiCallTraceCore.h
//  Qi_ObjcMsgHook
//
//  Created by liusiqi on 2019/11/20.
//  Copyright © 2019 QiShare. All rights reserved.
//

#ifndef QiCallTraceCore_h
#define QiCallTraceCore_h

#include <stdio.h>
#include <objc/objc.h>

typedef struct {
    __unsafe_unretained Class cls;
    SEL sel;
    uint64_t time; // us (1/1000 ms)
    int depth;
} qiCallRecord;

extern void qiCallTraceStart(void);
extern void qiCallTraceStop(void);

extern void qiCallConfigMinTime(uint64_t us); //default 1000
extern void qiCallConfigMaxDepth(int depth);  //default 3

extern qiCallRecord *qiGetCallRecords(int *num);
extern void qiClearCallRecords(void);

#endif /* QiCallTraceCore_h */
