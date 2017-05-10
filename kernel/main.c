#include "global.h"
#include "string.h"
#include "lib.h"
#include "systemcall.h"
#include "process.h"
#include "clock.h"
#include "keyboard.h"
#include "tty.h"
void wakeupProc();

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
        //delay(1); // 延迟一会，不然打印的A太快了。
    }
}

// 一个最简单的进程
void procB(){
    while( TRUE ){
        //dispStr("B ");
        //delay(1); // 延迟一会，不然打印的A太快了。
    }
}

// 一个最简单的进程
void procC(){
    while( TRUE ){
        //dispStr("C ");
        //delay(1); // 延迟一会，不然打印的A太快了。
    }
}

PUBLIC void kernelMain(){
    initClock(); // 初始化时钟
    initKeyboard(); // 初始化键盘

    // 给不同进程不同优先级分配不同的运行时间
    proc_table[0].ticks = proc_table[0].priority = 1;
    proc_table[1].ticks = proc_table[1].priority = 1;
    proc_table[2].ticks = proc_table[2].priority = 1;
    proc_table[3].ticks = proc_table[2].priority = 1;
    // 方便循环赋值
    TASK task[MAX_PROCESS_NUM] = {
        {procA, "procA"}, {procB, "procB"}, {procC, "procC"},
        {taskTTY, "TTY task"}};
    creatProcess(task);
    wakeupProc();
}


