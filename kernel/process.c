#include "global.h"
#include "string.h"
#include "i8259A.h"
#include "port.h"
#include "lib.h"
#include "systemcall.h"
#include "process.h"
void wakeupProc();

// 创建进程
PUBLIC void creatProcess(){
    setIRQHandler(CLICK_IQR, taskSchedule); // 设置时钟中断的处理函数
    enableIRQ(CLICK_IQR); // 打开时钟中断

    // 给不同进程不同优先级分配不同的运行时间
    proc_table[0].ticks = proc_table[0].priority = 30;
    proc_table[1].ticks = proc_table[1].priority = 80;
    proc_table[2].ticks = proc_table[2].priority = 20;
    // 方便循环赋值
    TASK task[MAX_PROCESS_NUM] = {
        {procA, "procA"}, {procB, "procB"}, {procC, "procC"}};

    for(int i=0; i < MAX_PROCESS_NUM; ++i){
        initPCB(&proc_table[i], task[i].start_addr, 1024 + i,
                task[i].name, proc_stack[i+1]/*栈底位置，先一个栈的栈顶*/);

        // 指向LDT的描述符
        // 注意，因为此时使用的内核的数据段基地址是０，才能使用p_proc->ldts作为ldt的基地址，
        // 如果不是，则只是个偏移，需要将偏移与LDT中的基地址相加，才能得到线性地址。
        setDescraptor(&(descriptor[DESC_FIRST_PROC_INDEX + i]), 
                base2virtual(sele2base(SELECTOR_KERNEL_DS), proc_table[i].ldts),
                LDT_SIZE * sizeof(DESCRIPTOR) -1, DESC_LDT);//S为0:指向的内容为描述符或门描述符
    }
    ticks = 0; // 任务调度的计数
    schedule_reenter = 0; // 是否任务调度重入标志
    pcb_proc_ready = proc_table;
    wakeupProc();
}





void initPCB(PCB* p_proc, proc_func proc, int id, char* p_name, char p_stack[]){
    p_proc->ldtSelect = SELE_FIRST_PROC; // 保存进程的描述符表选择子
    // 设置进程的代码段描述符，由于现在还不知道怎么计算函数的长度，所以先给一个较大的值，虽然这是有风险的。
    setDescraptor(&(p_proc->ldts[0]), /*(u32)procA*/0, (u32)0xFFFFF,
            DESC_32BIT_BASE | DESC_PRISENT | DESC_PRIVILAGE1 |
            DESC_TYPE_R | DESC_DATA_CODE); //代码段：粒度４Ｋ、32位段、在内存、权限1、可读可执行 

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
    p_proc->regs.eip = (u32)proc;
    p_proc->regs.esp = (u32)p_stack; //proc_stack + PROC_STACK_BYTE;// 栈底
    p_proc->regs.eflags = 0x1202;  // IF=1：retd后开中断，IOPL=1：可以使用I/O指令，bit2 is always 1
    // 一下两项现在初始化有点多余，根本没有用到
    p_proc->pid = id; // 前1024个进程号留给内核
    memCpy(&p_proc->p_name, p_name, PROC_NAME_LEN);
}

// 一个最简单的进程
void procA() {
    while( TRUE ){
        //dispInt(getTicks());
        dispStr("A ");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}

// 一个最简单的进程
void procB(){
    while( TRUE ){
        dispStr("B ");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}

// 一个最简单的进程
void procC(){
    while( TRUE ){
        dispStr("C ");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}
// 一个粗略的延迟函数，调节内部的循环条件，以使打印速度在合理的范围
PUBLIC void delay(int time){
    for(int i = 0; i < time; ++i){
        for(int j = 0; j < 1000; ++j){
            for(int k = 0; k < 100; ++k);
        }
    }
}


void taskSchedule(){
    ticks++;
    //dispStr("*");
    // 时间片轮转的调度算法
    // pcb_proc_ready++;
    // if(pcb_proc_ready >= proc_table + MAX_PROCESS_NUM){
    //     pcb_proc_ready = proc_table;
    // }
    prioritySchedule();
}

void prioritySchedule(){
    pcb_proc_ready->ticks--;
    if(pcb_proc_ready->ticks == 0){
        PCB * proc;
        int maxPriority = 0;
        for(proc = proc_table; proc < (proc_table + MAX_PROCESS_NUM); proc++){
            if(maxPriority < proc->ticks){
                maxPriority = proc->ticks;
                pcb_proc_ready = proc;
            }
        }
        if(maxPriority == 0){ // 所有的ticks都是0时，重置ticks
            for(proc = proc_table; proc < (proc_table + MAX_PROCESS_NUM); proc++){
                proc->ticks = proc->priority;
                if(maxPriority < proc->ticks){
                    maxPriority = proc->ticks;
                    pcb_proc_ready = proc;
                }
            }
        }
    }
}

PUBLIC int sysGetTicks(){
    return ticks;
}