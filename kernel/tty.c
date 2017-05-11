#include "process.h"
#include "tty.h"
#include "string.h"
#include "keyboard.h"

PUBLIC void taskTTY(){
    while( TRUE ){
        char ch = nextCodeInKbBuff();;
        dispAChar(ch);
        //dispStr("task TTY");
        delay(1); // 延迟一会，不然打印的A太快了。
    }
}