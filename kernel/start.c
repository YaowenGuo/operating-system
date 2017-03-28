#include "type.h"
#include "const.h"
#include "protect.h"
#include "string.h"

在replaecGdt()中添加idt_prt和inte_desc的关联代码。由于函数名已经不能表达他所完成的功能，将函数名改为
initDescTblPtr，别忘了同时修改kernel.c中的调用。

PUBLIC void initDescTblPtr()
{
	memCpy( descriptor, 						/* 目标地址 */
			(void *)( * ((u32 *)(&gdt_ptr[2])) ), /* 原地址 */
			*((u16*)(&gdt_ptr[0]))  			/* 长度，由于gdtr中存的长度是偏移，所以需要加1 */
			);

	/* gdt_ptr[6] 共 6 个字节：0~15:Limit  16~47:Base。用作 sgdt/lgdt 的参数。*/
	u16* p_gdt_limit = ( u16* )( &gdt_ptr[0] );
	u32* p_gdt_base  = ( u32* )( &gdt_ptr[2] );
	*p_gdt_limit     = DESCRIPTOR_NUM * sizeof( DESCRIPTOR ) - 1;
	*p_gdt_base      = ( u32 )descriptor;

	// 将idt_prt指向中断描述符inte_desc
	/* idt_ptr[6] 共 6 个字节：0~15:Limit  16~47:Base。用作 sidt/lidt 的参数。*/
	u16* p_idt_limit = ( u16* )( &idt_ptr[0] );
	u32* p_idt_base  = ( u32* )( &idt_ptr[2] );
	*p_gdt_limit     = INTE_DESC_NUM * sizeof( GATE ) - 1;
	*p_gdt_base      = ( u32 )inte_desc;
}

PUBLIC void test()
{
	dispStr("\n\n\n\n\n\n\n\n\n"
		"----------In kernel space----------"); 
}

为了能初始化