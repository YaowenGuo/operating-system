#include "const.h"
#include "global.h"
#include "i8259A.h"
#include "port.h"
#include "process.h"
#include "clock.h"

PUBLIC void initClock(){
    /* 初始化 8253 PIT */
    // 调快了中断的频率，原先的频率键盘处理程序调度的过慢
    writePort(TIMER_MODE, RATE_GENERATOR);
    writePort(TIMER0, (u8) (TIMER_FREQ/HZ) );
    writePort(TIMER0, (u8) ((TIMER_FREQ/HZ) >> 8));
    setIRQHandler(CLOCK_IRQ, taskSchedule);    /* 设定时钟中断处理程序 */
    enableIRQ(CLOCK_IRQ);                        /* 让8259A可以接收时钟中断 */
}

void taskSchedule(){
    ticks++;
    //当前中断已经设置设置了正在响应，不可能重入，这里是不让其他中断中发生的时钟中断重入
    if (inte_reenter != 0) {
        return;
    }

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
