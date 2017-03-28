// include/global.h
// Extern is defined as extern except in global.c
/*
以下的宏定义保证了全局变量的声明和定义仅有一份，extern关键字用于声明该变量或者函数在其他文件中。
只要将该声明导入文件，同时取消extern的修饰，就是定义了，保证了代码的唯一。
*/
#ifdef GLOBAL_VARIABLES_HERE
#undef EXTERN
#define EXTERN
#endif


EXTERN u32 			disp_position_dw;
EXTERN u8 			gdt_ptr[6];    // gdt pointer 0-15:limit, 16-47:Base
EXTERN DESCRIPTOR  	descriptor[DESCRIPTOR_NUM];
EXTERN u8 			idt_ptr[6];				  // 中断描述符表的指针
EXTERN gate 		inte_desc[INTE_DESC_NUM]; // 中断描述符