#include "const.h"
#include "global.h"
#include "i8259A.h"
#include "port.h"
#include "process.h"
#include "clock.h"

PUBLIC void initClock(){
    setIRQHandler(CLOCK_IRQ, taskSchedule);    /* 设定时钟中断处理程序 */
    enableIRQ(CLOCK_IRQ);                        /* 让8259A可以接收时钟中断 */
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

PUBLIC int sysGetTicks(){
    return ticks;
}

