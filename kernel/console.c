#include "port.h"
#include "const.h"
#include "global.h"
#include "console.h"
#include "type.h"
/*
 * 初始化保存控制台信息的结构体
 */
PUBLIC void initConsole(CONSOLE* p_con, int index){

    int v_mem_size = V_MEM_SIZE >> 1;   /* 显存总大小 (in WORD) */
    // 防止不足一行的情况出现。如果不在这里去除，没了不打印下一屏的内容，最后不满一行的
    // 内容也是不能显示的，反而使后面的计算变得麻烦。
    int con_v_mem_size        = v_mem_size / SCREEN_WIDTH / NUN_CONSOLE * SCREEN_WIDTH;
    // 注意 VGA端口的地址设置也是以偏移地址的
    p_con->original_addr      = index * con_v_mem_size; 
    p_con->v_mem_limit        = con_v_mem_size;
    p_con->current_start_addr = p_con->original_addr;

    /* 默认光标位置在最开始处 */
    p_con->cursor = p_con->original_addr;

    if (index == 0) {
        /* 第一个控制台沿用原来的光标位置 */
        p_con->cursor = disp_position_dw / 2; // 不覆盖原有的数据
        disp_position_dw = 0; //将原来的位置设0，如果使用了原先的打印函数，会打印到开始，便于知道。
    }
    else {
        putc(p_con, index + '0');
        putc(p_con, '#');
    }

    //setCursor(p_con->cursor);
}

PUBLIC void putc(CONSOLE* p_con, char ch){
    u8* p_vmem = (u8*)(V_MEM_BASE + p_con->cursor * 2);

    
    switch(ch) {
    case '\n':
        if (p_con->cursor < p_con->original_addr + p_con->v_mem_limit - SCREEN_WIDTH) {
            p_con->cursor = (p_con->cursor / SCREEN_WIDTH + 1) * SCREEN_WIDTH;
        }
        break;
    case '\b':
        if (p_con->cursor > p_con->original_addr) {
            p_con->cursor--;
            *(p_vmem-2) = ' ';
            *(p_vmem-1) = DEFAULT_CHAR_COLOR;
        }
        break;
    default:
        if (p_con->cursor < p_con->original_addr + p_con->v_mem_limit - 1) {
            *p_vmem++ = ch;
            *p_vmem++ = DEFAULT_CHAR_COLOR;
            p_con->cursor++;
        }
        break;
    }

    while (p_con->cursor >= p_con->current_start_addr + SCREEN_SIZE) {
        scrollScreen(p_con, SCR_DN);
    }

    flush(p_con);
}

PUBLIC void flush(CONSOLE* p_con){
    setCursor(p_con->cursor);
    setVideoStartAddr(p_con->current_start_addr);
}


/*
 * 设置光标位置
 */
PRIVATE void setCursor(u32 addr){
    disableInte();
    writePort(CRTC_ADDR_REG, CURSOR_H);
    writePort(CRTC_DATA_REG, (addr >> 8) & 0xFF);
    writePort(CRTC_ADDR_REG, CURSOR_L);
    writePort(CRTC_DATA_REG, addr & 0xFF);
    enableInte();
}



/*
 * 设置屏幕显示区的其实地址
 */
PRIVATE void setVideoStartAddr(u32 addr){
    disableInte();
    writePort(CRTC_ADDR_REG, START_ADDR_H);
    writePort(CRTC_DATA_REG, (addr >> 8) & 0xFF);
    writePort(CRTC_ADDR_REG, START_ADDR_L);
    writePort(CRTC_DATA_REG, addr & 0xFF);
    enableInte();
}



/*
 * 滚屏.
 * direction:
 *  SCR_UP  : 向上滚屏
 *  SCR_DN  : 向下滚屏
 *  其它  : 不做处理
 */
PUBLIC void scrollScreen(CONSOLE* p_con, int direction){
    if (direction == SCR_UP) {
        if (p_con->current_start_addr > p_con->original_addr) {
            p_con->current_start_addr -= SCREEN_WIDTH; // 上滚一行
        }
    }
    else if (direction == SCR_DN) {
        if (p_con->current_start_addr + SCREEN_SIZE <
            p_con->original_addr + p_con->v_mem_limit) {
            p_con->current_start_addr += SCREEN_WIDTH; // 下滚一行
        }
    }
    else{
    }

    setVideoStartAddr(p_con->current_start_addr);
    setCursor(p_con->cursor);
}