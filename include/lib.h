#include "const.h"
#ifndef _LIB_H_
#define _LIB_H_
// 将数字转化为十进制字符串，前面多余的0不显示。
PUBLIC int itoa(int num, char * str);

/**
* 十进制显示一个int型正数，并不显示前面的0
* 这里需要重写打印数字的方法，因为之前的函数不是通过入栈的方式传递参数的
*/
PUBLIC void dispInt(int num);

/*
 * 拷贝以字符串结尾符为结尾的字符串
 * 返回所拷贝字符的个数
 */
PUBLIC int strcpy(char* source, char* target);

#endif