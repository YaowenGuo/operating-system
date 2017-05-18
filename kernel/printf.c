#include "type.h"
#include "lib.h"
#include "stdio.h"
#include "systemcall.h"
int printf(const char* format, ...){
    value_list args = (value_list)((char*)(&format) + 4); // 获得第一个参数后的参数列表。地址相当于指针，加1增加4个字节
    char buf[256];
    int len = value2steam(buf, format, args);
    write(buf, len);
    return len;
}

int value2steam(char* buf, const char* fmt, value_list args){
    char tmp[256];
    char* p_buf;
    value_list p_next_args = args;
    int tmp_len;
    for(p_buf = buf; *fmt; fmt++){
        if(*fmt != '%'){
            *p_buf++ = *fmt;
            continue;
        }
        fmt++;
        switch(*fmt){
        case 'd':
            itoa(*(int*)p_next_args, tmp);
            tmp_len = strcpy(tmp, p_buf);
            p_next_args += 4;
            p_buf += tmp_len;
            break;
        case 's':
            tmp_len = strcpy((char*)p_next_args, p_buf);
            p_next_args += 4;
            p_buf += tmp_len;
            break;
        case 'c':
            *p_buf++ = *((char*)p_next_args);
            p_next_args++;
            break;
        default:
            break;
        }
    }
    *p_buf = '\0';
    return (p_buf - buf);
}

