/*
初始化门描述符，本意能初始化所有类型的门描述符，然而调用门和其他的还没有接触，如果有不足的地方以后再修改
p_gate: 门描述符表首地址
index: 要初始化的门描述符在表中的偏移量
funcPointer: 函数指针，即要调用的函数的地址
privilege: 特权级
*/
PRIVATE void initGateDesc( GATE* p_gete, u8 index, u8 desc_type, funcPointer funcP, u8 privilege)
{
	GATE * gateDesc 		= &p_gete[index];
	u32 offset 				= (u32)funcP;
	gateDesc->offset_low 	= offset & 0xFFFF;
	gateDesc->selector 		= SELECTER_FLATC;
	gateDesc->param_count 	= 0;
	gateDesc->attr 			= desc_type | (privilege << 5);
	gateDesc->offset_hight 	= (offset >> 16) & 0xFFFF;
}


/* exception_handler
* 
*/
PUBLIC void exceptionHandler(int vectorNum, int errCode, int eip, int cs, int eflags)
{
	char * errorMsg[] = {
			"#DE Divide Error",
			"#DB RESERVED",
			"--  NMI Interrupt",
			"#BP Breakpoint",
			"#OF Overflow",
			"#BR BOUND Range Exceeded",
			"#UD Invalid Opcode (Undefined Opcode)",
			"#NM Device Not Available (No Math Coprocessor)",
			"#DF Double Fault",
			"    Coprocessor Segment Overrun (reserved)",
			"#TS Invalid TSS",
			"#NP Segment Not Present",
			"#SS Stack-Segment Fault",
			"#GP General Protection",
			"#PF Page Fault",
			"--  (Intel reserved. Do not use.)",
			"#MF x87 FPU Floating-Point Error (Math Fault)",
			"#AC Alignment Check",
			"#MC Machine Check",
			"#XF SIMD Floating-Point Exception"
	};
	// 打印异常信息
	disp_position_dw = 80*10;//跳过前十行之前打印的内容
	dispStr("Exception! --> ");
	dispStr(errorMsg[vectorNum]);
	dispStr("\n");
	dispStr("EFLAGS:");
	dispStr(eflags);
	dispStr("CS:");
	disp_int(cs);
	dispStr("EIP:");
	disp_int(eip);
	// 有错误码则打印
	if(err_code != 0xFFFFFFFF){
		disp_color_str("Error code:");
		disp_int(errCode);
	}
}