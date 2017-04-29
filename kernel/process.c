#include "global.h"
#include "string.h"
#include "process.h"
void wakeupProc();
void testVideo();

// 创建进程
PUBLIC void creatProcess()
{
    PCB * p_proc = proc_table;
    p_proc->ldtSelect = SELE_FIRST_PROC; // 保存进程的描述符表选择子
    // 设置进程的代码段描述符，由于现在还不知道怎么计算函数的长度，所以先给一个较大的值，虽然这是有风险的。
    setDescraptor(&(p_proc->ldts[0]), /*(u32)procA*/0, (u32)0xFFFFF,
            DESC_32BIT_BASE | DESC_PRISENT | DESC_PRIVILAGE1 |
            DESC_TYPE_R | DESC_DATA_CODE); //代码段：粒度４Ｋ、32位段、在内存、权限1、可读可执行 
    // memCpy(&p_proc->ldts[0], &descriptor[SELECTOR_KERNEL_CS>>3], sizeof(DESCRIPTOR));
    // p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5; // change the DPL

    // 设置进程的代码段选择子
    p_proc->regs.cs = (0 * sizeof(DESCRIPTOR)) | SELECTOR_LOCAL | PRIVILEGE_PROC;
    // 设置其余选择子使用同一个描述符，由于数据段和视频段都是使用该描述符，所以要设置的长点，
    // 由于在Loader中获取的内存长度并没有保存，所以这里直接写个最长的。虽然知道这样太不严谨。
    // 并不方便去获取其他的。，也只有这样了。因为其他的什么都没有写呢。再一个对如何设置能够更好
    // 我也没有一个很好的方案，只有照着先写了
    // 现在的程序都被加载到0x30400到１M之间的地方，所以先给长度位1M以内的内存
    // *注意,这里的基地址不能随便填，我原来打算填0x30400，结果出错了。这是因为虽然基地址改了，但是其他地址的偏移都是
    // 按照内核段基地址为0，计算得到的，所以，再加上0x30400之后，就得出一个错误的线性地址
    setDescraptor(&(p_proc->ldts[1]), 0, 0xFFFFF, DESC_32BIT_BASE | 
        DESC_PRISENT | DESC_PRIVILAGE1 | DESC_TYPE_RW | DESC_DATA_CODE); //0数据段：粒度４Ｋ,32位段、在内存、权限1、可读可写
    p_proc->regs.ss = (1 * sizeof(DESCRIPTOR)) | SELECTOR_LOCAL | PRIVILEGE_PROC;
    p_proc->regs.ds = (1 * sizeof(DESCRIPTOR)) | SELECTOR_LOCAL | PRIVILEGE_PROC;
    p_proc->regs.es = (1 * sizeof(DESCRIPTOR)) | SELECTOR_LOCAL | PRIVILEGE_PROC;
    p_proc->regs.fs = (1 * sizeof(DESCRIPTOR)) | SELECTOR_LOCAL | PRIVILEGE_PROC;
    p_proc->regs.gs = (SELECTOR_KERNEL_GS & SELECTOR_RPL_MASK) | PRIVILEGE_USER;// 使用GDT中的选择子，将特权级设为３
    // 执行点
    p_proc->regs.eip = (u32)procA;
    p_proc->regs.esp = (u32)proc_stack + PROC_STACK_BYTE;// 栈底
    p_proc->regs.eflags = 0x1202;  // IF=1：retd后开中断，IOPL=1：可以使用I/O指令，bit2 is always 1
    // 一下两项现在初始化有点多余，根本没有用到
    p_proc->pid = 1024; // 前1024个进程号留给内核
    memCpy(&p_proc->p_name, "procA", sizeof("procA"));

    // 指向LDT的描述符
    // 注意，因为此时使用的内核的数据段基地址是０，才能使用p_proc->ldts作为ldt的基地址，
    // 如果不是，则只是个偏移，需要将偏移与LDT中的基地址相加，才能得到线性地址。
    setDescraptor(&(descriptor[DESC_FIRST_PROC_INDEX]), 
            base2virtual(sele2base(SELECTOR_KERNEL_DS), p_proc->ldts),
            LDT_SIZE * sizeof(DESCRIPTOR) -1,DESC_LDT);// DESC_LDT与内核的描述符的权限相差这么大?,S为0:指向的内容为描述符或门描述符

    pcb_proc_ready = proc_table;
    wakeupProc();
}

// 一个最简单的进程
void procA()
{
    while( TRUE )
    {
        dispStr("A ");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}

// 一个粗略的延迟函数，调节内部的循环条件，以使打印速度在合理的范围
PUBLIC void delay(int time)
{
    for(int i = 0; i < time; ++i){
        for(int j = 0; j < 1000; ++j){
            for(int k = 0; k < 100; ++k);
        }
    }
}


void taskSchedule(){
    dispStr("*");
    delay(1);
}

