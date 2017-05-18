#ifndef _OS_TYPE_H_
#define _OS_TYPE_H_
/* 定义不同bit长度的数据 */
typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;
typedef char * value_list;
typedef void (* IRQHandler) (int IRQ);
typedef void (* function);  // 指向任何函数的指针
#endif 