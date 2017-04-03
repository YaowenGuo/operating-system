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

/* 系统段描述符类型值说明 */
#define DA_386IGate             0x8E    /* 386 中断门类型值 */


#define SELECTOR_KERNEL_CS        0x08   // 与loader.asm中的一样


// 打印中断请求号
void printIRQ(int irq);
#endif

