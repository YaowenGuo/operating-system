#include "const.h"
#include "keyboard.h"
#include "i8259A.h"
#include "port.h"
#include "string.h"

PRIVATE KEYBOARD_BUFF   keyboard_buff;

PRIVATE int code_with_E0;
PRIVATE int shift_l;    /* l shift state */
PRIVATE int shift_r;    /* r shift state */
PRIVATE int alt_l;      /* l alt state   */
PRIVATE int alt_r;      /* r left state  */
PRIVATE int ctrl_l;     /* l ctrl state  */
PRIVATE int ctrl_r;     /* l ctrl state  */
PRIVATE int caps_lock;  /* Caps Lock     */
PRIVATE int num_lock;   /* Num Lock  */
PRIVATE int scroll_lock;    /* Scroll Lock   */
PRIVATE int column;

/*
 * 保存扫描码到缓冲区，缓冲区已满则丢弃
 * 注意：Alt + F4会结束虚拟机执行，我并没有找到修改这个快捷键的地方。
 * 其它一些快捷键也会被系统占用。这是虚拟环境和物理机不一样的地方。
 * 我的键盘Alt+Fn并不会得到正确的结果，必须按Fn键和F1-12才能得到Fn
 */
PUBLIC void saveCode2KbBuff(int irq){
    u8 scan_code = readPort(KB_DATA);
    // dispAChar(scan_code);
    // putc(&p_current_tty->console, scan_code);
    if(keyboard_buff.count < SIZE_KB_BUFF){
        *(keyboard_buff.p_head) = scan_code;
        keyboard_buff.p_head++;
        if(keyboard_buff.p_head == keyboard_buff.buff + SIZE_KB_BUFF){
            keyboard_buff.p_head = keyboard_buff.buff;
        }
        keyboard_buff.count++;
    }
}

/*
 * 从缓冲区取键盘扫描码，如果没有则等待，知道获取一个扫描码才返回
 */
PUBLIC u8 nextCodeInKbBuff(){
    u8 scan_code;
    while(keyboard_buff.count <= 0); // 等待下一个字节到来
    disableInte(); // 防止读同时写入造成的混乱。
    scan_code = *(keyboard_buff.p_tail);
    keyboard_buff.p_tail++;
    if(keyboard_buff.p_tail == keyboard_buff.buff + SIZE_KB_BUFF){
        keyboard_buff.p_tail = keyboard_buff.buff;
    }
    keyboard_buff.count--;
    enableInte();
    return scan_code;
}


/*
 *initKeyboard
 */
PUBLIC void initKeyboard(){
    keyboard_buff.count = 0;
    keyboard_buff.p_head = keyboard_buff.p_tail = keyboard_buff.buff;

    shift_l = shift_r = 0;
    alt_l   = alt_r   = 0;
    ctrl_l  = ctrl_r  = 0;

    caps_lock   = 0;
    num_lock    = 1; // 默认使用数字功能而非箭头功能
    scroll_lock = 0;
    setLeds();

    setIRQHandler(KEYBOARD_IRQ, saveCode2KbBuff);/*设定键盘中断处理程序*/
    enableIRQ(KEYBOARD_IRQ);                    /*开键盘中断*/
}

/*
 * 等待 8042 的输入缓冲区空
 */
PRIVATE void kbWait(){
    u8 kb_stat;
    do {
        kb_stat = readPort(KB_CMD);
    } while (kb_stat & 0x02);
}


/*
 * 等待键盘响应ACK
 */
PRIVATE void kbAck(){
    u8 kb_read;

    do {
        kb_read = readPort(KB_DATA);
    } while (kb_read =! KB_ACK);
}

/*
 * 设置LED灯
 */
PRIVATE void setLeds(){
    u8 leds = (caps_lock << 2) | (num_lock << 1) | scroll_lock;

    kbWait();
    writePort(KB_DATA, LED_CODE);
    kbAck();

    kbWait();
    writePort(KB_DATA, leds);
    kbAck();
}