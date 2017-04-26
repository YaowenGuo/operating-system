#ifndef _OS_PROCESS_H_
#define _OS_PROCESS_H_

#include "type.h"
#include "const.h"

#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER) 
#define PCB_LDT_SELE_OFFSET offsetof(PCB, ldtSelect)
#define PCB_STACK_BUTTOM offsetof(PCB, ldtSelect)


// 进程栈字节
#define PROC_STACK_BYTE    0x8000

typedef struct s_stackframe {
    u32 gs;         // . 段寄存器应该是使用了双字对齐，才是定义成32位的。
    u32 fs;         // | 保存剩余的寄存器，进程运行的点的状态
    u32 es;         // |
    u32 ds;         // |
    u32 edi;        // |
    u32 esi;        // |
    u32 ebp;        // |
    u32 kernel_esp; // ?
    u32 ebx;        // .
    u32 edx;        // | 由指令popad弹出，顺序固定
    u32 ecx;        // |
    u32 eax;        // /
    u32 retaddr;    // kernel.asm::save()的返回地址
    u32 eip;        // . 这部分的顺序是固定的，因为它们是被调用门压栈
    u32 cs;         // | 自动放置的，而不是我们手动保存的。
    u32 eflags;     // | 
    u32 esp;        // |
    u32 ss;         // /
} STACK_FRAME;


typedef struct s_proc {
    STACK_FRAME regs;           /* process registers saved in stack frame */
    u16 ldtSelect;              /* gdt selector giving ldt base and limit */
    DESCRIPTOR ldts[LDT_SIZE];  /* local descriptors for code and data */
    int ticks;                  /* remained ticks */
    int priority;
    u32 pid;                    /* process id passed in from MM */
    char p_name[16];            /* name of the process */
} PCB;


// 一个粗略的延迟函数，调节内部的循环条件，以使打印速度在合理的范围
PUBLIC void delay(int time);

// 创建进程
PUBLIC void creatProcess();

// 一个最简单的进程
void procA();
#endif

