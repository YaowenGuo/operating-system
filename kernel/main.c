#include "const.h"
#include "global.h"
#include "string.h"
#include "tty.h"
#include "i8259A.h"
#include "port.h"
#include "process.h"
#include "clock.h"
#include "keyboard.h"

/* 8253/8254 PIT (Programmable Interval Timer) */
// #define TIMER0         0x40 /* I/O port for timer channel 0 */
// #define TIMER_MODE     0x43 /* I/O port for timer mode control */
// #define RATE_GENERATOR 0x34  00-11-010-0 :
//                  * Counter0 - LSB then MSB - rate generator - binary
                 
// #define TIMER_FREQ     1193182L/* clock frequency for timer in PC and AT */
// #define HZ             100  /* clock freq (software settable on IBM-PC) */


PUBLIC void wakeupProc();

PUBLIC int sysGetTicks();


PUBLIC void test()
{
    dispStr("\n\n\n\n\n\n\n\n\n"
        "----------In kernel space----------\n"); 
}

// 一个最简单的进程
void procA() {
    while( TRUE ){
        //dispInt(getTicks());
        //dispStr("A ");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}

// 一个最简单的进程
void procB(){
    while( TRUE ){
        //dispStr("B ");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}

// 一个最简单的进程
void procC(){
    while( TRUE ){
        //dispStr("C ");
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


PUBLIC void kernelMain(){
    // 给不同进程不同优先级分配不同的运行时间
    proc_table[0].ticks = proc_table[0].priority = 1;
    proc_table[1].ticks = proc_table[1].priority = 1;
    proc_table[2].ticks = proc_table[2].priority = 1;
    proc_table[3].ticks = proc_table[3].priority = 1;
    // 方便循环赋值
    TASK task[MAX_PROCESS_NUM] = {
        {procA, "procA"},
        {procB, "procB"},
        {procC, "procC"},
        {taskTTY, "task TTY"}
    };

    creatProcess(task);

    initClock();
    initKeyboard();

    wakeupProc();
}

