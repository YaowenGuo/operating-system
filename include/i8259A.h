#include "type.h"

#ifndef _I8259A_H_
#define _I8259A_H_

PUBLIC void init8259A();
// 打印中断请求号
PUBLIC void printIRQ(int irq);

PUBLIC void setIRQHandler(int IRQ, IRQHandler hanler);

#endif