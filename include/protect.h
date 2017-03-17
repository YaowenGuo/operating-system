#ifndef _OS_PROTECT_H_
#define _OS_PROTECT_H_

/* 
* 用于定义段描述符/系统段描述符 
* 共8个字节
*/
typedef struct descriptor
{
	u16	limit_low;
	u16 base_low;
	u8	base_mid;
	u8 	attr1;
	u8	limit_high_attr2;
	u8	base_high;
} DESCRIPTOR, * GDT;

#endif

