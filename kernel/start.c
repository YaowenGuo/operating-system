#include "type.h"
#include "const.h"
#include "protect.h"
#include "string.h"

PUBLIC u8 	gdt_ptr[6];    // gdt pointer 0-15:limit, 16-47:Base
PUBLIC DESCRIPTOR  descriptor[DESCRIPTOR_NUM];

PUBLIC void replaceGdt()
{
	memCpy( descriptor, 						/* 目标地址 */
		(void *)( * ((u32 *)(&gdt_ptr[2])) ), 	/* 原地址 */
		*((u16*)(&gdt_ptr[0]))  				/* 长度，由于gdtr中存的长度是偏移，所以需要加1 */
		);
	u16* p_gdt_limit = (u16*)(&gdt_ptr[0]);
	u32* p_gdt_base = (u32*)(&gdt_ptr[2]);
	*p_gdt_limit = DESCRIPTOR_NUM * sizeof( DESCRIPTOR ) - 1;
	*p_gdt_base = (u32)descriptor;
}

PUBLIC void test()
{
	dispStr("\n\n\n\n\n\n\n\n\n"
		"----------In kernel space----------"); 
}
