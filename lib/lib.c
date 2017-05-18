#include "const.h"
#include "string.h"
/* PUBLIC void itoa(char * str, int num);
* 将数字转化为十进制字符串，前面多余的0不显示。
*/

PUBLIC int itoa(int num, char * str)
{
    char buff[12];
    int negative = FALSE;
    int i = 0;
    if(num < 0)
    {
        negative = TRUE;
        num -= num;
    }
    if (num == 0){
        buff[0] = '0';
        i = 1;
    }else{
        for( ; num > 0; ++i){
            buff[i] = num % 10 + '0';
            num /= 10;
        }
    }

    if(negative) buff[i] = '-';
    else --i;

    for(int j = 0; j <= i; ++j)
    {
        str[j] = buff[i - j];
    }
    str[i+1] = '\0';
    return i + 1;
}

// 十进制显示一个int型正数，并不显示前面的0
PUBLIC void dispInt(int num)
{
    char str[12] = "";
    itoa(num, str);
    dispStr(str);
}


/*
 * 拷贝以字符串结尾符为结尾的字符串
 * 返回所拷贝字符的个数
 */
PUBLIC int strcpy(char* source, char* target){
    int i;
    for(i = 0; source[i]; i++){
        target[i] = source[i];
    }
    target[i] = '\0';
    return i;
}