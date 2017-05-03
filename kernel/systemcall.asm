%include "asmconst.inc"

NUM_GET_TICKS   equ 0 ; 要跟global.c中sys_call_table的定义一致
INTE_VECTOR_SYS_CALL equ 0x80 ; 与protect.h中的保持一致

global getTicks

bits 32
[section .text]

getTicks:
    mov     eax, NUM_GET_TICKS      ; 要完成工作的编号
    int     INTE_VECTOR_SYS_CALL    ; 完成该工作的中断向量号
    ret                             ; 中断处理返回后执行，eax中存放着返回值
    