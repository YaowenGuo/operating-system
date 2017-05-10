#include "port.h"
#include "global.h"
#include "keyboard.h"
#include "console.h"
#include "tty.h"

PUBLIC void taskTTY(){
    
    TTY*    p_tty;

    for (p_tty=tty_table; p_tty < tty_table + NUM_TTY; p_tty++) {
        initTTY(p_tty);
    }
    useTTY(0);

    while(TRUE){
        for (p_tty=tty_table; p_tty < tty_table + NUM_TTY; p_tty++) {
            if(p_tty == p_current_tty){
                keyboardRead(p_tty);
                //flush(&p_tty->console);
                //putc(&p_tty->console, 'c');
            }
        }
    }
}

/*
 * Pause,Print Screen和其他以0xE0开端的扫描码和普通字符的ASCII码，都交给该函数
 * 处理。Shift,Alt,Ctrl键的状态通过设置相应位来标志。
 */
PUBLIC void inProcess(TTY* p_tty, u32 key){
    //char output[2] = {'\0', '\0'};

    if (!(key & FLAG_EXT)) { // 是可打印字符，就是ASCII码
            //output[0] = key & 0xFF;
            //disp_str(output);
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

/*
 * 初始化终端
 */
PUBLIC void initTTY(TTY * p_tty){
    // p_tty->inbuf_count = 0;
    // p_tty->p_inbuf_head = p_tty->p_inbuf_tail = p_tty->p_inbuf;
    int index = p_tty - tty_table;
    initConsole(&(p_tty->console), index);
}

/*
 * 切换正在使用的终端
 */
PRIVATE void useTTY(u32 index){
    if(index >= NUM_TTY){ return; }
    p_current_tty = &tty_table[index];
    flush(&p_current_tty->console);
}

