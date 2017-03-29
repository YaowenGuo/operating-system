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

PUBLIC void initIDT()
{
	init_8259A();

	// 全部初始化成中断门(没有陷阱门)
	init_idt_desc(INT_VECTOR_DIVIDE,	DA_386IGate,
		      divide_error,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_DEBUG,		DA_386IGate,
		      single_step_exception,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_NMI,		DA_386IGate,
		      nmi,			PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_BREAKPOINT,	DA_386IGate,
		      breakpoint_exception,	PRIVILEGE_USER);

	init_idt_desc(INT_VECTOR_OVERFLOW,	DA_386IGate,
		      overflow,			PRIVILEGE_USER);

	init_idt_desc(INT_VECTOR_BOUNDS,	DA_386IGate,
		      bounds_check,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_INVAL_OP,	DA_386IGate,
		      inval_opcode,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_COPROC_NOT,	DA_386IGate,
		      copr_not_available,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_DOUBLE_FAULT,	DA_386IGate,
		      double_fault,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_COPROC_SEG,	DA_386IGate,
		      copr_seg_overrun,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_INVAL_TSS,	DA_386IGate,
		      inval_tss,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_SEG_NOT,	DA_386IGate,
		      segment_not_present,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_STACK_FAULT,	DA_386IGate,
		      stack_exception,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_PROTECTION,	DA_386IGate,
		      general_protection,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_PAGE_FAULT,	DA_386IGate,
		      page_fault,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_COPROC_ERR,	DA_386IGate,
		      copr_error,		PRIVILEGE_KRNL);
}