#ifndef _OS_PROTECT_H_
#define _OS_PROTECT_H_

/* 
* 用于定义段描述符/系统段描述符 
* 共8个字节
*/
typedef struct s_descriptor
{
	u16	limit_low;
	u16 base_low;
	u8	base_mid;
	u8 	attr1;
	u8	limit_high_attr2;
	u8	base_high;
} DESCRIPTOR, * GDT;


/*
* 定义门描述符，包括中断门，陷阱门，任务门和调用门
*/
typedef struct s_gate
{
	u16	offset_low;		// 偏移的低１６位
	u16 selector; 		// 选择子
	u8  param_count; 	/* 该字段只有在调用门时有效。如果在利用调用门调用子程序时引起特权级的转移和堆栈的改变
						* 需要将外层堆栈中的参数复制到内层堆栈，该计数字段就是用于说明这种情况发生时需要复制的
						* 双字个数
						*/
	u8  attr; 			// attribute 属性
	u16 offset_hight; 	// 偏移的高１６位
}GATE;

#endif

