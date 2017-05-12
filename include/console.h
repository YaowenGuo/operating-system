#ifndef _CONSOLE_H_
#define _CONSOLE_H_

#define SCR_UP  1   /* scroll forward */
#define SCR_DN  -1  /* scroll backward */

#define SCREEN_SIZE     (80 * 25)
#define SCREEN_WIDTH        80

#define DEFAULT_CHAR_COLOR  0x07    /* 0000 0111 黑底白字 */

/* CONSOLE
 * 成员都表示字符的位置，即以双字节(word)为单位的
 */
typedef struct s_console{
    unsigned int    original_addr;      /* 当前控制台对应显存位置 */
    unsigned int    v_mem_limit;        /* 当前控制台占的显存大小 */
    unsigned int    current_start_addr; /* 当前显示到了什么位置   */
    unsigned int    cursor;             /* 当前光标位置 */
}CONSOLE;

/*
 * 初始化保存控制台信息的结构体
 */
PUBLIC void initConsole(CONSOLE* p_con, int index);

PUBLIC void putc(CONSOLE* p_con, char ch);

PUBLIC void flush(CONSOLE* p_con);

/*
 * 设置光标位置
 */
PRIVATE void setCursor(u32 addr);

/*
 * 设置屏幕显示区的其实地址
 */
PRIVATE void setVideoStartAddr(u32 addr);

/*
 * 滚屏.
 * direction:
 *  SCR_UP  : 向上滚屏
 *  SCR_DN  : 向下滚屏
 *  其它  : 不做处理
 */
PUBLIC void scrollScreen(CONSOLE* p_con, int direction);

#endif