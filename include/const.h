#ifndef _OS_CONST_h_
#define _OS_CONST_h_

/* 函数类型 */
#define PUBLIC          /* PUBLIC is the opposite of PRIVATE */
#define PRIVATE static  /* static 修饰的函数对文件外不可见，避免了同名函数和同名变量 */

/*
* GDT和IDT中描述符的总个数
* 128 * 8 = 1024？
* 为什么需要这么多？
*/
#define DESCRIPTOR_NUM 	128  

/*
* 8259A interrupt control ports
* INTE->interrupt
* 
*/

#define INTE_MASTER_EVEN	0x20 	// Master chip even control port 
#define INTE_MASTER_ADD 	0x21 	// Master chip add control port
#define INTE_SLAVE_EVEN		0xA0	// Slave chip even control port
#define INTE_SLAVE_EVEN	 	0xA1 	// Slave chip add control port


/*
*　Interrupt vector
*/
#define INTE_VECTOR_IRQ0 	0x20 	// 
#define INTE_VECTOR_IRQ8	0x28 	// 