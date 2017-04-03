#include "const.h"
#include "string.h"
/* PUBLIC void itoa(char * str, int num);
* 将数字转化为十进制字符串，前面多余的0不显示。
*/

PUBLIC void itoa(int num, char * str)
{
    char buff[11];
    int negative = FALSE;
    if(num < 0)
    {
        negative = TRUE;
        num -= num;
    }
    int i;
    for( i = 0; num > 0; ++i)
    {
        buff[i] = num % 10 + '0';
        num /= 10;
    }

    if(negative) buff[i] = '-';
    else --i;

    for(int j = 0; j <= i; ++j)
    {
        str[j] = buff[i - j];
    }
    str[i+1] = '\0';
    return;
}

// 十进制显示一个int型正数，并不显示前面的0
PUBLIC void dispInt(int num)
{
    char str[12] = "";
    itoa(num, str);
    dispStr(str);
}