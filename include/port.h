#include "type.h"
#include "const.h"
#ifndef _PORT_OPT_H_
#define _PORT_OPT_H_
PUBLIC void writePort( u16 port, u8 value );
PUBLIC u8 readPort( u16 port );

PUBLIC void disableIRQ(int IRQ);
PUBLIC void enableIRQ(int IRQ);
PUBLIC int seePort(char ch);
#endif

#ifndef _ENABLE_INTERRUPT_H_
#define _ENABLE_INTERRUPT_H_
PUBLIC void disableInte();
PUBLIC void enableInte();
#endif