#include "const.h"
#include "keyboard.h"
#include "keymap.h"
#include "i8259A.h"
#include "port.h"
#include "string.h"

PUBLIC KEYBOARD_BUFF   keyboard_buff;

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
PRIVATE u8 nextCodeInKbBuff(){
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

/*
 * keyboardRead
 * 每此调用处理一个按键的扫描码，组合按键需要多次调用
 * 只将扫描码转换为ASCII码，没有对应字符的扫描码不做处理。
 */
PUBLIC void keyboardRead(TTY* p_tty) {
    u8  scan_code;
    int make;   /* 1: make;  0: break. */

    u32 key = 0;/* 用一个整型来表示一个键。比如，如果 Home 被按下，
                * 则 key 值将为定义在 keyboard.h 中的 'HOME'。
                */
    if(keyboard_buff.count > 0){
        code_with_E0 = 0;
        scan_code = nextCodeInKbBuff();

        if (! isSpecialCode(scan_code, &key, & make)) {
            /* 首先判断Make Code 还是 Break Code */
            make = (scan_code & FLAG_BREAK ? FALSE : TRUE);

            column = 0;
            // 是否需要大写字母
            int caps = shift_l || shift_r;
            // 只有shift和字母组合才进行大小写转换，否则将shift当做功能键上传
            if (caps_lock && (keymap[scan_code & 0x7F][0] >= 'a') 
                    && (keymap[scan_code & 0x7F][0] <= 'z')) {
                caps = !caps;
            }
            if (caps) {// CapsLock被设置
                column = 1;
            }

            if (code_with_E0) {
                column = 2; 
                code_with_E0 = 0;
            }
            /* 先定位到 keymap 中的行 */
            // 只定义了Make Code，所以如果是Break Code要先转化为Make Code
            key = keymap[scan_code & 0x7F][column];
            
            switch(key) {
            // 当某一个按键被按下，相应的标志变量变为True，松开变成False
            case SHIFT_L:
                shift_l = make;
                break;
            case SHIFT_R:
                shift_r = make;
                break;
            case CTRL_L:
                ctrl_l = make;
                break;
            case CTRL_R:
                ctrl_r = make;
                break;
            case ALT_L:
                alt_l = make;
                break;
            case ALT_R:
                alt_l = make;
                break;
            case CAPS_LOCK:
                if (make) {
                    caps_lock   = !caps_lock;
                    setLeds();
                }
                break;
            case NUM_LOCK:
                if (make) {
                    num_lock    = !num_lock;
                    setLeds();
                }
                break;
            case SCROLL_LOCK:
                if (make) {
                    scroll_lock = !scroll_lock;
                    setLeds();
                }
                break;
            default:
                break;
            }

            if (make) { /* 忽略 Break Code */
                int pad = 0;

                /* 首先处理小键盘 */
                if ((key >= PAD_SLASH) && (key <= PAD_9)) {
                    pad = 1;
                    switch(key) {
                    case PAD_SLASH:
                        key = '/';
                        break;
                    case PAD_STAR:
                        key = '*';
                        break;
                    case PAD_MINUS:
                        key = '-';
                        break;
                    case PAD_PLUS:
                        key = '+';
                        break;
                    case PAD_ENTER:
                        key = ENTER;
                        break;
                    default:
                        if (num_lock &&
                            (key >= PAD_0) &&
                            (key <= PAD_9)) {
                            key = key - PAD_0 + '0';
                        }
                        else if (num_lock &&
                             (key == PAD_DOT)) {
                            key = '.';
                        }
                        else{
                            switch(key) {
                            case PAD_HOME:
                                key = HOME;
                                break;
                            case PAD_END:
                                key = END;
                                break;
                            case PAD_PAGEUP:
                                key = PAGEUP;
                                break;
                            case PAD_PAGEDOWN:
                                key = PAGEDOWN;
                                break;
                            case PAD_INS:
                                key = INSERT;
                                break;
                            case PAD_UP:
                                key = UP;
                                break;
                            case PAD_DOWN:
                                key = DOWN;
                                break;
                            case PAD_LEFT:
                                key = LEFT;
                                break;
                            case PAD_RIGHT:
                                key = RIGHT;
                                break;
                            case PAD_DOT:
                                key = DELETE;
                                break;
                            default:
                                break;
                            }
                        }
                        break;
                    }
                }
                key |= shift_l  ? FLAG_SHIFT_L  : 0;
                key |= shift_r  ? FLAG_SHIFT_R  : 0;
                key |= ctrl_l   ? FLAG_CTRL_L   : 0;
                key |= ctrl_r   ? FLAG_CTRL_R   : 0;
                key |= alt_l    ? FLAG_ALT_L    : 0;
                key |= alt_r    ? FLAG_ALT_R    : 0;
                key |= pad      ? FLAG_PAD      : 0;

                inProcess(p_tty, key);
            }
        }
    }
}

PRIVATE int isSpecialCode(u8 scan_code, u32* p_key, int* p_make){
    /* 下面开始解析扫描码 */
    if (scan_code == 0xE1) {
        u8 pausebrk_scode[] = {0xE1, 0x1D, 0x45, 0xE1, 0x9D, 0xC5};
        int i;
        for(i=1; i<6 && (nextCodeInKbBuff() == pausebrk_scode[i]); i++); 
        // 六个编码都相同才是
        if (6 == i) {
            *p_key = PAUSEBREAK;
        }
    }
    else if (scan_code == 0xE0) {
        scan_code = nextCodeInKbBuff();

        /* PrintScreen 被按下 */
        if ((scan_code == 0x2A) && (nextCodeInKbBuff() == 0xE0) 
                && (nextCodeInKbBuff() == 0x37)) {
            *p_key = PRINTSCREEN;
            *p_make = 1;
        }
        /* PrintScreen 被释放 */
        if ((scan_code == 0xB7) && (nextCodeInKbBuff() == 0xE0) 
                && (nextCodeInKbBuff() == 0xAA) ) {
             *p_key = PRINTSCREEN;
             *p_make = 0;
        }
        /* 不是PrintScreen, 此时scan_code为0xE0紧跟的那个值. */
        if (*p_key == 0) {
            code_with_E0 = 1;
        }
    }
    return (*p_key == PAUSEBREAK) || (*p_key == PRINTSCREEN);
}