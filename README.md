# Qi_ObjcMsgHook
QiLagMonitor is an iOS  performance detection tool, which can monitor method time and method call stack through hook objc_msgsend.


#### 一、什么是hook？

定义：`hook`是指在原有方法开始执行时，换成你指定的方法。或在原有方法的执行前后，添加执行你指定的方法。从而达到改变指定方法的目的。

例如：
- 使用`runtime` 的 `Method Swizzle`。
- 使用`Facebook`所开源的[fishhook](https://github.com/facebook/fishhook)框架。

前者是`ObjC`运行时提供的“方法交换”能力。
后者是对`Mach-O`二进制文件的符号进行动态的“重新绑定”，已达到方法交换的目的。

##### 问题1： fishhook的大致实现思路是什么？

在[《iOS App启动优化（一）—— 了解App的启动流程》](https://www.jianshu.com/p/024b3d847fe0)中我们提到，动态链接器dyld会根据Mach-O二进制可执行文件的符号表来绑定符号。而通过符号表及符号名就可以知道指针访问的地址，再通过更改指针访问的地址就能替换指定的方法实现了。


#####  问题2：为什么hook了objc_msgSend就可以掌握所有objc方法的耗时？

因为`objc_msgSend`是所有`Objective-C`方法调用的必经之路，所有的`Objective-C`方法都会调用到运行时底层的`objc_msgSend`方法。所以只要我们可以`hook objc_msgSend`，我们就可以掌握所有`objc`方法的耗时。（更多详情可看我之前写的[《iOS 编写高质量Objective-C代码（二）》的第六点 —— 理解objc_msgSend（对象的消息传递机制）](https://www.jianshu.com/p/0702a8b59a4e)）

另外，`objc_msgSend`本身是用汇编语言写的，苹果已经开源了`objc_msgSend`的源码。可在官网上下载查看：[objc_msgSend源码](https://opensource.apple.com/source/objc4/objc4-723/runtime/Messengers.subproj/)。


#### 二、如何hook底层objc_msgSend？


##### 第一阶段：与fishhook框架类似，我们先要拥有hook的能力。

- 首先，设计两个结构体：
一个是用来记录符号的结构体，一个是用来记录符号表的链表。

```
struct rebinding {
    const char *name;
    void *replacement;
    void **replaced;
};

struct rebindings_entry {
    struct rebinding *rebindings;
    size_t rebindings_nel;
    struct rebindings_entry *next;
};
```

- 其次，遍历动态链接器`dyld`内所有的`image`，取出其中的`header`和`slide`。
以便我们接下来拿到符号表。

```
static int fish_rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel) {
    int retval = prepend_rebindings(&_rebindings_head, rebindings, rebindings_nel);
    if (retval < 0) {
        return retval;
    }
    // If this was the first call, register callback for image additions (which is also invoked for
    // existing images, otherwise, just run on existing images
    //首先是遍历 dyld 里的所有的 image，取出 image header 和 slide。注意第一次调用时主要注册 callback
    if (!_rebindings_head->next) {
        _dyld_register_func_for_add_image(_rebind_symbols_for_image);
    } else {
        uint32_t c = _dyld_image_count();
        // 遍历所有dyld的image
        for (uint32_t i = 0; i < c; i++) {
            _rebind_symbols_for_image(_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i)); // 读取image内的header和slider
        }
    }
    return retval;
}
```

- 上一步，我们在`dyld`内拿到了所有`image`。
接下来，我们从`image`内找到符号表内相关的`segment_command_t`，遍历符号表找到所要替换的`segname`，再进行下一步方法替换。方法实现如下：

```
static void rebind_symbols_for_image(struct rebindings_entry *rebindings,
                                     const struct mach_header *header,
                                     intptr_t slide) {
    Dl_info info;
    if (dladdr(header, &info) == 0) {
        return;
    }
    
    // 找到符号表相关的command，包括 linkedit_segment command、symtab command 和 dysymtab command。
    segment_command_t *cur_seg_cmd;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command* symtab_cmd = NULL;
    struct dysymtab_command* dysymtab_cmd = NULL;
    
    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            }
        } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command*)cur_seg_cmd;
        } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
            dysymtab_cmd = (struct dysymtab_command*)cur_seg_cmd;
        }
    }
    
    if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment ||
        !dysymtab_cmd->nindirectsyms) {
        return;
    }

    // 获得base符号表以及对应地址
    uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    nlist_t *symtab = (nlist_t *)(linkedit_base + symtab_cmd->symoff);
    char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);
    
    // 获得indirect符号表
    uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);
    
    cur = (uintptr_t)header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0 &&
                strcmp(cur_seg_cmd->segname, SEG_DATA_CONST) != 0) {
                continue;
            }
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect =
                (section_t *)(cur + sizeof(segment_command_t)) + j;
                if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab);
                }
                if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
                    perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab);
                }
            }
        }
    }
}
```


- 最后，通过符号表以及我们所要替换的方法的实现，进行指针地址替换。
这是相关方法实现：

```
static void perform_rebinding_with_section(struct rebindings_entry *rebindings,
                                           section_t *section,
                                           intptr_t slide,
                                           nlist_t *symtab,
                                           char *strtab,
                                           uint32_t *indirect_symtab) {
    uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;
    void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);
    for (uint i = 0; i < section->size / sizeof(void *); i++) {
        uint32_t symtab_index = indirect_symbol_indices[i];
        if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
            symtab_index == (INDIRECT_SYMBOL_LOCAL   | INDIRECT_SYMBOL_ABS)) {
            continue;
        }
        uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
        char *symbol_name = strtab + strtab_offset;
        if (strnlen(symbol_name, 2) < 2) {
            continue;
        }
        struct rebindings_entry *cur = rebindings;
        while (cur) {
            for (uint j = 0; j < cur->rebindings_nel; j++) {
                if (strcmp(&symbol_name[1], cur->rebindings[j].name) == 0) {
                    if (cur->rebindings[j].replaced != NULL &&
                        indirect_symbol_bindings[i] != cur->rebindings[j].replacement) {
                        *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i];
                    }
                    indirect_symbol_bindings[i] = cur->rebindings[j].replacement;
                    goto symbol_loop;
                }
            }
            cur = cur->next;
        }
    symbol_loop:;
    }
}
```


到这里，通过调用下面的方法，我们就拥有了`hook`的基本能力。
```
static int fish_rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel);
```


##### 第二阶段：通过汇编语言编写出我们的`hook_objc_msgSend`方法

因为`objc_msgSend`是通过汇编语言写的，我们想要替换`objc_msgSend`方法还需要从汇编语言下手。

既然我们要做一个监控方法耗时的工具。这时想想我们的目的是什么？

我们的目的是：通过`hook`原`objc_msgSend`方法，在`objc_msgSend`方法前调用打点计时操作，在`objc_msgSend`方法调用后结束打点和计时操作。通过计算时间差，我们就能精准的拿到方法调用的时长。

因此，我们要在原有的`objc_msgSend`方法的调用前后需要加上`before_objc_msgSend `和`after_objc_msgSend `方法，以便我们后期的打点计时操作。


arm64 有 31 个 64 bit 的整数型寄存器，分别用 x0 到 x30 表示。主要的实现思路是：
- 入栈参数，参数寄存器是 x0~ x7。对于 objc_msgSend 方法来说，x0 第一个参数是传入对象，x1 第二个参数是选择器 _cmd。syscall 的 number 会放到 x8 里。
- 交换寄存器中保存的参数，将用于返回的寄存器 lr 中的数据移到 x1 里。
- 使用 bl label 语法调用 pushCallRecord 函数。
- 执行原始的 objc_msgSend，保存返回值。
- 使用 bl label 语法调用 popCallRecord 函数。
- 返回

里面涉及到的一些汇编指令：

指令 | 含义
---|---
stp | 同时写入两个寄存器。
mov | 将值赋值到一个寄存器。
ldp | 同时读取两个寄存器。
sub | 将两个寄存器的值相减
add | 将两个寄存器的值相加
ret | 从子程序返回主程序

详细代码如下：
```
#define call(b, value) \
__asm volatile ("stp x8, x9, [sp, #-16]!\n"); \
__asm volatile ("mov x12, %0\n" :: "r"(value)); \
__asm volatile ("ldp x8, x9, [sp], #16\n"); \
__asm volatile (#b " x12\n");

#define save() \
__asm volatile ( \
"stp x8, x9, [sp, #-16]!\n" \
"stp x6, x7, [sp, #-16]!\n" \
"stp x4, x5, [sp, #-16]!\n" \
"stp x2, x3, [sp, #-16]!\n" \
"stp x0, x1, [sp, #-16]!\n");

#define load() \
__asm volatile ( \
"ldp x0, x1, [sp], #16\n" \
"ldp x2, x3, [sp], #16\n" \
"ldp x4, x5, [sp], #16\n" \
"ldp x6, x7, [sp], #16\n" \
"ldp x8, x9, [sp], #16\n" );

#define link(b, value) \
__asm volatile ("stp x8, lr, [sp, #-16]!\n"); \
__asm volatile ("sub sp, sp, #16\n"); \
call(b, value); \
__asm volatile ("add sp, sp, #16\n"); \
__asm volatile ("ldp x8, lr, [sp], #16\n");

#define ret() __asm volatile ("ret\n");

__attribute__((__naked__))
static void hook_objc_msgSend() {
    // Save parameters.
    save() // stp入栈指令 入栈参数，参数寄存器是 x0~ x7。对于 objc_msgSend 方法来说，x0 第一个参数是传入对象，x1 第二个参数是选择器 _cmd。syscall 的 number 会放到 x8 里。
    
    __asm volatile ("mov x2, lr\n");
    __asm volatile ("mov x3, x4\n");
    
    // Call our before_objc_msgSend.
    call(blr, &before_objc_msgSend)
    
    // Load parameters.
    load()
    
    // Call through to the original objc_msgSend.
    call(blr, orig_objc_msgSend)
    
    // Save original objc_msgSend return value.
    save()
    
    // Call our after_objc_msgSend.
    call(blr, &after_objc_msgSend)
    
    // restore lr
    __asm volatile ("mov lr, x0\n");
    
    // Load original objc_msgSend return value.
    load()
    
    // return
    ret()
}
```

这时候，每当底层调用`hook_objc_msgSend`方法时，会先调用`before_objc_msgSend`方法，再调用`hook_objc_msgSend`方法，最后调用`after_objc_msgSend`方法。

单个方法调用，流程如下图：

![](https://upload-images.jianshu.io/upload_images/3407530-32b68f14b19d9ba3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

举一反“三”，然后多层方法调用的流程，就变成了下图：

![](https://upload-images.jianshu.io/upload_images/3407530-2fffca55a5f136a0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


这样，我们就能拿到每一层方法调用的耗时了。


#### 三、如何使用这个工具？

第一步，在项目中，导入[QiLagMonitor]()类库。

第二步，在所需要监控的控制器中，导入`QiCallTrace.h`头文件。

```swift
  [QiCallTrace start]; // 1. 开始

  // your codes（你所要测试的代码区间）

  [QiCallTrace stop]; // 2. 停止
  [QiCallTrace save]; // 3. 保存并打印方法调用栈以及具体方法耗时。
```

PS：目前该工具只能`hook`所有`objc`方法，并计算出区间内的所有方法耗时。暂不支持swift方法的监听。


本文源码：[Demo](https://github.com/QiShare/Qi_ObjcMsgHook)
