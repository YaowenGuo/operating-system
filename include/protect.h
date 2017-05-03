#ifndef _OS_PROTECT_H_
#define _OS_PROTECT_H_

#include "type.h"
#include "const.h"
/*
* 用于定义段描述符/系统段描述符 
* 共8个字节
*/
typedef struct s_descriptor
{
    u16 limit_low;
    u16 base_low;
    u8  base_mid;
    u8  attr1;
    u8  limit_high_attr2;
    u8  base_high;
} DESCRIPTOR, * GDT;


/*
* 定义门描述符，包括中断门，陷阱门，任务门和调用门
*/
typedef struct s_gate
{
    u16 offset_low;     // 偏移的低１６位
    u16 selector;       // 选择子
    u8  param_count;    /* 该字段只有在调用门时有效。如果在利用调用门调用子程序时引起特权级的转移和堆栈的改变
                        * 需要将外层堆栈中的参数复制到内层堆栈，该计数字段就是用于说明这种情况发生时需要复制的
                        * 双字个数
                        */
    u8  attr;           // attribute 属性
    u16 offset_hight;   // 偏移的高１６位
}GATE;

typedef struct s_tss
{
    u32 backlink;
    u32 esp0;   /* stack pointer to use during interrupt */
    u32 ss0;    /*   "   segment  "  "    "        "     */
    u32 esp1;
    u32 ss1;
    u32 esp2;
    u32 ss2;
    u32 gr3;
    u32 eip;
    u32 eflags;
    u32 eax;
    u32 ecx;
    u32 edx;
    u32 ebx;
    u32 esp;
    u32 ebp;
    u32 esi;
    u32 edi;
    u32 es;
    u32 cs;
    u32 ss;
    u32 ds;
    u32 fs;
    u32 gs;
    u32 ldt;
    u16 trap;
    u16 iobase; /* I/O位图基址大于或等于TSS段界限，就表示没有I/O许可位图 */
}TSS;

/* TSS中数据偏移量 */
#define TSS_ESP0    offsetof(TSS, esp0)
#define TSS_SS0     offsetof(TSS, ss0)
/* 中断向量 */
#define INTE_VECTOR_DIVIDE       0x0
#define INTE_VECTOR_DEBUG        0x1
#define INTE_VECTOR_NMI          0x2
#define INTE_VECTOR_BREAKPOINT   0x3
#define INTE_VECTOR_OVERFLOW     0x4
#define INTE_VECTOR_BOUNDS       0x5
#define INTE_VECTOR_INVAL_OP     0x6
#define INTE_VECTOR_COPROC_NOT   0x7
#define INTE_VECTOR_DOUBLE_FAULT 0x8
#define INTE_VECTOR_COPROC_SEG   0x9
#define INTE_VECTOR_INVAL_TSS    0xA
#define INTE_VECTOR_SEG_NOT      0xB
#define INTE_VECTOR_STACK_FAULT  0xC
#define INTE_VECTOR_PROTECTION   0xD
#define INTE_VECTOR_PAGE_FAULT   0xE
#define INTE_VECTOR_COPROC_ERR   0x10


/*
* 外部中断向量号，由于用户自定义向量从32号开始，就将外部中断定为从
* 32号向量开始。
*/
#define INTE_VECTOR_32          0x20
#define INTE_VECTOR_33          0x21
#define INTE_VECTOR_34          0x22
#define INTE_VECTOR_35          0x23
#define INTE_VECTOR_36          0x24
#define INTE_VECTOR_37          0x25
#define INTE_VECTOR_38          0x26
#define INTE_VECTOR_39          0x27
#define INTE_VECTOR_40          0x28
#define INTE_VECTOR_41          0x29
#define INTE_VECTOR_42          0x2A
#define INTE_VECTOR_43          0x2B
#define INTE_VECTOR_44          0x2C
#define INTE_VECTOR_45          0x2D
#define INTE_VECTOR_46          0x2E
#define INTE_VECTOR_47          0x2F

#define INTE_VECTOR_SYS_CALL    0x80

/* 系统段描述符类型值说明 */
#define DA_386IGate             0x8E    /* 386 中断门类型值 */


#define SELECTOR_KERNEL_CS      0x08   // 与loader.asm中的一样
#define SELECTOR_KERNEL_DS      0x10
#define SELECTOR_KERNEL_GS      0x18
#define SELECTOR_TSS            0x20   // TSS描述符的选择子
#define SELECTOR_RPL_MASK       0xFFFC
#define SELECTOR_TI_MASK        0xFFFD

/*
 * 基地址和偏移地址求线性（虚拟）地址
 */
#define base2virtual(base, offset) (u32)((u32)base + (u32)(offset))
// 由选择子找出偏移量
PUBLIC u32 sele2base(u16 selector);

// 打印中断请求号
void printIRQ(int irq);
// 设置描述符
void setDescraptor(DESCRIPTOR * p_desc, u32 base, u32 limit, u16 attribute);

// 初始化TSS
void initTSS();
#endif

