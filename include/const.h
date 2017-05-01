#ifndef _OS_CONST_H_
#define _OS_CONST_H_

#define TRUE 1
#define FALSE 0

/* 函数类型 */
#define PUBLIC          /* PUBLIC is the opposite of PRIVATE */
#define PRIVATE static  /* static 修饰的函数对文件外不可见，避免了同名函数和同名变量 */

#define EXTERN extern   // 引用外界变量

// GDT_PTR 和 IDT_PTR的长度
#define DESC_POINTER_SIZE 6

/*
* GDT和IDT中描述符的总个数
* 128 * 8 = 1024？
* 为什么需要这么多？
*/
#define DESCRIPTOR_NUM  128
// 以及定义不同描述符的下标，
#define DESC_TSS_INDEX  4
#define DESC_FIRST_PROC_INDEX 5
#define SELE_FIRST_PROC DESC_FIRST_PROC_INDEX * sizeof(DESCRIPTOR) + PRIVILEGE_KRNL

/*
 * 描述符中的修饰部分，这里将所有的的描述符都定义了
 * 这里定义的除第一个以外，剩余几个在门描述符中也可以用，因为两种描述符的第五个字节
 * 的结构和含义是一样的。只是注意剩余属性并不是同一个字节，在复制函数编写时要特别注意
 */
#define DESC_32BIT_BASE 0xC000 // 粒度为４K,32位地址或32位操作数，不在内存
#define DESC_PRISENT    0x80   // 在内存中
#define DESC_PRIVILAGE0 0x00
#define DESC_PRIVILAGE1 0x20
#define DESC_PRIVILAGE2 0x40
#define DESC_PRIVILAGE3 0x60
#define DESC_DAGE       0x10


#define DESC_DATA_CODE 0x10 // 指向的是数据段/代码段
#define DESC_STEM_GATE 0x00 // 指向的是描述符表/门描述符
/* 
 * 局部描述符表段类型值
 * 段粒度为字节，应该是段比较短吧
 * 段最大长度为64KB，指向LDT的段不用太大
 * 在内存中
 * 特权级0
 * 普通描述符，而非门描述符
 * 可读可写
 */
#define DESC_LDT        0x82

/*
 * E execute
 * W write
 * R read
 * A Accesed
 */
#define DESC_TYPE_R     0x8
#define DESC_TYPE_RW    0x2
#define DESC_TYPE_EA    0x9

/*
* IDT num
*/
#define INTE_DESC_NUM 256

// 外部中断数量
#define NUM_IRQ     16
#define CLICK_IQR   0
/*
* 8259A interrupt control ports
* INTE->interrupt
* 
*/
#define INTE_MASTER_EVEN    0x20    // Master chip even control port 
#define INTE_MASTER_ADD     0x21    // Master chip add control port
#define INTE_SLAVE_EVEN     0xA0    // Slave chip even control port
#define INTE_SLAVE_ADD      0xA1    // Slave chip add control port


/*
*　Interrupt vector
*/
#define INTE_VECTOR_IRQ0    0x20    // 
#define INTE_VECTOR_IRQ8    0x28    // 

#define SELECTOR_LOCAL  4
/* 权限 */
#define PRIVILEGE_KRNL  0
#define PRIVILEGE_PROC  1
#define PRIVILEGE_USER  3

// 进程相关
#define LDT_SIZE 2
#define MAX_PROCESS_NUM 3


#endif