#include "global.h"
#include "process.h"
#include "tty.h"
#include "string.h"
#include "keyboard.h"
#include "console.h"
#include "lib.h"
#include "port.h"

PUBLIC void taskTTY(){
    TTY*    p_tty;

    for (p_tty=tty_table; p_tty < tty_table + NUM_TTY; p_tty++) {
        initTTY(p_tty);
    }
    useTTY(0);

    while(TRUE){
        for (p_tty=tty_table; p_tty < tty_table + NUM_TTY; p_tty++) {
            // if(p_tty == p_current_tty){
                keyboardRead(p_tty);
            // }
        }
    }
}

/*
 * 初始化终端
 */
PUBLIC void initTTY(TTY * p_tty){
    int index = p_tty - tty_table;
    initConsole(&(p_tty->console), index);
}


/*
 * 切换正在使用的终端
 */
PRIVATE void useTTY(u32 index){
    if(index >= NUM_TTY){ return; }
    p_using_console = &(tty_table[index].console);
    flush(p_using_console);
}

/*
 * Pause,Print Screen和其他以0xE0开端的扫描码和普通字符的ASCII码，都交给该函数
 * 处理。Shift,Alt,Ctrl键的状态通过设置相应位来标志。
 */
PUBLIC void inProcess(TTY* p_tty, u32 key){
    //char output[2] = {'\0', '\0'};

    if (!(key & FLAG_EXT)) { // 是可打印字符，就是ASCII码
            putc(&p_tty->console, key);
    }
    else{ // 就是不可打印字符的扫描码
        int raw_code = key & MASK_RAW;
        switch(raw_code){
        case ENTER:
            putc(&p_tty->console, '\n');
            break;
        case BACKSPACE:
            putc(&p_tty->console, '\b');
            break;
        case UP:
            if((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R)){
                scrollScreen(&p_tty->console, SCR_DN);
            }
            break;
        case DOWN:
            if((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R)){
                scrollScreen(&p_tty->console, SCR_UP);
            }
            break;
        case F1:
        case F2:
        case F3:
        case F4:
        case F5:
        case F6:
        case F7:
        case F8:
        case F9:
        case F10:
        case F11:
        case F12:
            /* Alt + F1 ~ F12 */
            if((key & FLAG_ALT_L) || (key & FLAG_ALT_R)){
                useTTY(raw_code - F1);
            }
        default:
            break;
        }
    }
}


PUBLIC void tty_write(TTY * p_tty, char* str, int len){
    char* p_char = str;
    while(len){
        putc(&(p_tty->console), *p_char++);
        len--;
    }
}
// 这里将系统输出和屏幕输处分开，便于将来扩展到不同的输出，如文件。
PUBLIC int sys_write(char* buf, int len, PCB* p_proc){
    tty_write(&tty_table[p_proc->index_tty], buf, len);
    return 0;
}