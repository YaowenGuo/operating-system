#include "console.h"
#include "process.h"

#ifndef _TTY_H_
#define _TTY_H_

typedef struct s_tty{
    CONSOLE console;
}TTY;

PUBLIC void taskTTY();

/*
 * Pause,Print Screen和其他以0xE0开端的扫描码和普通字符的ASCII码，都交给该函数
 * 处理。Shift,Alt,Ctrl键的状态通过设置相应位来标志。
 */

PUBLIC void inProcess(TTY* p_tty, u32 key);


/*
 * 初始化终端
 */
PUBLIC void initTTY(TTY * p_tty);

PRIVATE void useTTY(u32 index);

/*
 * Pause,Print Screen和其他以0xE0开端的扫描码和普通字符的ASCII码，都交给该函数
 * 处理。Shift,Alt,Ctrl键的状态通过设置相应位来标志。
 */
PUBLIC void inProcess(TTY* p_tty, u32 key);

PUBLIC void tty_write(TTY * p_tty, char* str, int len);
// 这里将系统输出和屏幕输处分开，便于将来扩展到不同的输出，如文件。
PUBLIC int sys_write(char* buf, int len, PCB* p_proc);
#endif