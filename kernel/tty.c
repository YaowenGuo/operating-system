#include "global.h"
#include "process.h"
#include "tty.h"
#include "string.h"
#include "keyboard.h"
#include "console.h"
#include "lib.h"
PUBLIC void taskTTY(){
    TTY*    p_tty;

    for (p_tty=tty_table; p_tty < tty_table + NUM_TTY; p_tty++) {
        initTTY(p_tty);
        // dispStr("addr:");
        // dispInt(p_tty->console.original_addr);
        // dispStr(" \n");
        // dispInt(p_tty->console.v_mem_limit);
        // dispStr(" \n");
        // dispInt(p_tty->console.cursor);
        // dispStr(" \n");
    }
    useTTY(0);
    while( TRUE ){
        //char ch = nextCodeInKbBuff();;
        //dispAChar(ch);
        //putc(&p_current_tty->console,'t');
        //dispStr("task TTY");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}


/*
 * 初始化终端
 */
PUBLIC void initTTY(TTY * p_tty){
    // p_tty->inbuf_count = 0;
    // p_tty->p_inbuf_head = p_tty->p_inbuf_tail = p_tty->p_inbuf;
    int index = p_tty - tty_table;
    //dispInt(index);
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
