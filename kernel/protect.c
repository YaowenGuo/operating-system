#include "protect.h"
#include "const.h"
#include "global.h"
#include "string.h"
#include "lib.h"

// 复制GDT到内核空间
PUBLIC void replaecGdt()
{
    memCpy( descriptor,                         /* 目标地址 */
            (void *)( * ((u32 *)(&gdt_ptr[2])) ), /* 原地址 */
            *((u16*)(&gdt_ptr[0]))              /* 长度，由于gdtr中存的长度是偏移，所以需要加1 */
            );

    /* gdt_ptr[6] 共 6 个字节：0~15:Limit  16~47:Base。用作 sgdt/lgdt 的参数。*/
    u16* p_gdt_limit = ( u16* )( &gdt_ptr[0] );
    u32* p_gdt_base  = ( u32* )( &gdt_ptr[2] );
    *p_gdt_limit     = DESCRIPTOR_NUM * sizeof( DESCRIPTOR ) - 1;
    *p_gdt_base      = ( u32 )descriptor;

    disp_position_dw = 0; // 顺便将显示位置初始化为0，否则该值为随机的

}

/*
初始化门描述符，本意能初始化所有类型的门描述符，然而调用门和其他的还没有接触，如果有不足的地方以后再修改
p_gate: 门描述符表首地址
vector: 要初始化的门描述符在表中的偏移量
funcPointer: 函数指针，即要调用的函数的地址
privilege: 特权级
*/
PRIVATE void initGateDesc( u8 vector, u8 desc_type, void (* inteHandler)(), u8 privilege)
{
    GATE * gateDesc         = &inte_desc[vector];
    u32 offset              = (u32)inteHandler;
    gateDesc->offset_low    = offset & 0xFFFF;
    gateDesc->selector      = SELECTOR_KERNEL_CS;
    gateDesc->param_count   = 0;
    gateDesc->attr          = desc_type | (privilege << 5);
    gateDesc->offset_hight  = (offset >> 16) & 0xFFFF;
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
    disp_position_dw = 80 * 2 *10;//跳过前十行之前打印的内容
    dispStr("Exception! --> ");
    dispStr(errorMsg[vectorNum]);
    dispStr("\n");
    dispStr("EFLAGS:");
    dispInt(eflags);
    dispStr("   CS:");
    dispInt(cs);
    dispStr("   EIP:");
    dispInt(eip);
    // 有错误码则打印
    if(errCode != 0xFFFFFFFF){
        dispStr("   Error code:");
        dispInt(errCode);
    }
}
// 中断／异常处理函数，其实是在kernel.asm中的一个位置标号
void divideError();
void debugException();
void nmi();
void debugInterrupt();
void overflow();
void boundsCheck();
void invalOpCode();
void coprNotAvailable();
void doubleFault();
void coprSegOverrun();
void invalTss();
void segmentNotPresent();
void stackException();
void generalProtection();
void pageFault();
void floatError();

/*
* 外部中断处理函数，也是kernel.asm中的位置标号
*/
void inteClick();
void inteKeyboard();
void inteSlaveChip();
void inteSerialPort2();
void inteSerialPort1();
void inteLPT2();
void inteFloppyDisk();
void inteLPT1();
void inteRealtimeClick();
void inteRedirect();
void inteRetain1();
void inteRetain2();
void inteMouse();
void inteFPUException();
void inteATTemperaturePlate();
void inteRetain3();

// 初始化IDT，并将idt_ptr指向idt
PUBLIC void initIDT()
{
    // 全部初始化成中断门(没有陷阱门)
    initGateDesc(INTE_VECTOR_DIVIDE, DA_386IGate, divideError, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_DEBUG, DA_386IGate, debugException, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_NMI, DA_386IGate, nmi, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_BREAKPOINT, DA_386IGate, debugInterrupt, PRIVILEGE_USER);

    initGateDesc(INTE_VECTOR_OVERFLOW, DA_386IGate, overflow, PRIVILEGE_USER);

    initGateDesc(INTE_VECTOR_BOUNDS, DA_386IGate, boundsCheck, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_INVAL_OP, DA_386IGate, invalOpCode, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_COPROC_NOT, DA_386IGate, coprNotAvailable, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_DOUBLE_FAULT, DA_386IGate, doubleFault, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_COPROC_SEG, DA_386IGate, coprSegOverrun, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_INVAL_TSS, DA_386IGate, invalTss, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_SEG_NOT, DA_386IGate, segmentNotPresent, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_STACK_FAULT, DA_386IGate, stackException, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_PROTECTION, DA_386IGate, generalProtection, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_PAGE_FAULT, DA_386IGate, pageFault, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_COPROC_ERR, DA_386IGate, floatError, PRIVILEGE_KRNL);

    /*
    * 外部中断向量初始化
    */
    initGateDesc(INTE_VECTOR_32, DA_386IGate, inteClick, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_33, DA_386IGate, inteKeyboard, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_34, DA_386IGate, inteSlaveChip, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_35, DA_386IGate, inteSerialPort2, PRIVILEGE_USER);

    initGateDesc(INTE_VECTOR_36, DA_386IGate, inteSerialPort1, PRIVILEGE_USER);

    initGateDesc(INTE_VECTOR_37, DA_386IGate, inteLPT2, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_38, DA_386IGate, inteFloppyDisk, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_39, DA_386IGate, inteLPT1, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_40, DA_386IGate, inteRealtimeClick, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_41, DA_386IGate, inteRedirect, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_42, DA_386IGate, inteRetain1, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_43, DA_386IGate, inteRetain2, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_44, DA_386IGate, inteMouse, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_45, DA_386IGate, inteFPUException, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_46, DA_386IGate, inteATTemperaturePlate, PRIVILEGE_KRNL);

    initGateDesc(INTE_VECTOR_47, DA_386IGate, inteRetain3, PRIVILEGE_KRNL);


    // 将idt_prt指向中断描述符inte_desc
    /* idt_ptr[6] 共 6 个字节：0~15:Limit  16~47:Base。用作 sidt/lidt 的参数。*/
    u16* p_idt_limit = ( u16* )( &idt_ptr[0] );
    u32* p_idt_base  = ( u32* )( &idt_ptr[2] );
    *p_idt_limit     = INTE_DESC_NUM * sizeof( GATE ) - 1;
    *p_idt_base      = ( u32 )inte_desc;

}

// 打印中断请求号
void printIRQ(int irq)
{
    dispStr("\nInterrupt Request Number: ");
    dispInt(irq);
    dispStr("\n");
}