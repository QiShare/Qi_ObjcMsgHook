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

typedef struct qiCallRecord {
    __unsafe_unretained Class cls;
    SEL sel;
    uint64_t time; // us (1/1000 ms)
    int depth;
    // 在计算机体系结构中，lr 通常代表 "Link Register"。Link Register 是一个特殊的寄存器，用于存储函数或子程序调用的返回地址。当一个函数或子程序被调用时，返回地址（即调用指令后的下一条指令的地址）被保存到 Link Register 中，以便在函数执行完毕后可以返回到调用点继续执行。
    // 在 ARM 架构中，lr 是一个常见的寄存器名，表示 Link Register。在其他架构中，可能有不同的寄存器或方法来保存返回地址。
    // 在多线程环境中，thread_call_record 可能是一个结构体或记录，用于保存线程调用的相关信息，包括线程的状态、调用堆栈、寄存器值等。在这个上下文中，lr 可能是该记录中的一个字段，用于保存线程当前函数调用的 Link Register 值。这对于调试、性能分析或线程状态恢复等操作是非常有用的。
    // Link Register (lr) 的值并不是每个方法唯一的。lr 存储的是函数或方法调用时的返回地址，这个地址指向的是调用该函数后应当执行的下一条指令。因此，lr 的值取决于函数被调用的具体位置。
    uintptr_t lr; // link register
    struct qiCallRecord *caller_record;
} qiCallRecord;

extern void qiCallTraceStart(void);
extern void qiCallTraceStop(void);

extern void qiCallConfigMinTime(uint64_t us); //default 1000
extern void qiCallConfigMaxDepth(int depth);  //default 3

extern qiCallRecord *qiGetCallRecords(int *num);
extern void qiClearCallRecords(void);

#endif /* QiCallTraceCore_h */
