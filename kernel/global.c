#define GLOBAL_VARIABLES_HERE  // 该文件导入的global.h将消除extern，成为定义


#include "global.h"
#include "clock.h"
#include "tty.h"

PUBLIC function sysCall[ NUM_SYS_CALL ] = { sysGetTicks, sys_write };
