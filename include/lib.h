#ifndef _LIB_H_
#define _LIB_H_
// 将数字转化为十进制字符串，前面多余的0不显示。
PUBLIC void itoa(int num, char * str);

/**
* 十进制显示一个int型正数，并不显示前面的0
* 这里需要重写打印数字的方法，因为之前的函数不是通过入栈的方式传递参数的
*/
PUBLIC void dispInt(int num);
#endif