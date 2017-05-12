#include "type.h"
#include "const.h"

#ifndef _PORT_OPT_H_
#define _PORT_OPT_H_

/* VGA */
#define CRTC_ADDR_REG   0x3D4   /* CRT Controller Registers - Addr Register */
#define CRTC_DATA_REG   0x3D5   /* CRT Controller Registers - Data Register */
#define START_ADDR_H    0xC /* reg index of video mem start addr (MSB) */
#define START_ADDR_L    0xD /* reg index of video mem start addr (LSB) */
#define CURSOR_H    0xE /* reg index of cursor position (MSB) */
#define CURSOR_L    0xF /* reg index of cursor position (LSB) */
#define V_MEM_BASE  0xB8000 /* base of color video memory */
#define V_MEM_SIZE  0x8000  /* 32K: B8000H -> BFFFFH */

PUBLIC void writePort( u16 port, u8 value );
PUBLIC u8 readPort( u16 port );

PUBLIC void disableIRQ(int IRQ);
PUBLIC void enableIRQ(int IRQ);

#endif

#ifndef _ENABLE_INTERRUPT_H_
#define _ENABLE_INTERRUPT_H_

PUBLIC void disableInte();
PUBLIC void enableInte();

#endif