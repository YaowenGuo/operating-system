// include/global.h
// Extern is defined as extern except in global.c
/*
以下的宏定义保证了全局变量的声明和定义仅有一份，extern关键字用于声明该变量或者函数在其他文件中。
只要将该声明导入文件，同时取消extern的修饰，就是定义了，保证了代码的唯一。
*/
#include "type.h"
#include "const.h"
#include "protect.h"
#include "process.h"

#ifdef GLOBAL_VARIABLES_HERE
#undef EXTERN
#define EXTERN
#endif

#ifndef _GLOBAL_H_
#define _GLOBAL_H_

EXTERN u32          disp_position_dw;
EXTERN u8           gdt_ptr[ DESC_POINTER_SIZE ]; // gdt pointer 0-15:limit, 16-47:Base
EXTERN DESCRIPTOR   descriptor[ DESCRIPTOR_NUM ];
EXTERN u8           idt_ptr[ DESC_POINTER_SIZE ]; // 中断描述符表的指针
EXTERN GATE         inte_desc[ INTE_DESC_NUM ];   // 中断描述符
EXTERN PCB          proc_table[ MAX_PROCESS_NUM ];// 按最多的进程数定义进程表
EXTERN PCB*         pcb_proc_ready;
EXTERN char         proc_stack[ MAX_PROCESS_NUM ][ PROC_STACK_BYTE ];
EXTERN TSS          tss;
EXTERN u32          kernel_stack_top; // 保存内核栈的栈顶
EXTERN int          schedule_reenter; // 标志调用程序是否重入了，初始值赋值-1
EXTERN IRQHandler   irqHandler[ NUM_IRQ ];

#endif