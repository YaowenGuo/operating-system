#ifndef _I8259A_H_
#define _I8259A_H_
PUBLIC void init8259A();
PUBLIC void setIRQHandler(int IRQ, IRQHandler hanler);

#endif