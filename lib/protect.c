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