%include "asmconst.inc"

; 偏移要跟global.c中sys_call_table的定义顺序一致
NUM_GET_TICKS   equ 0
NUM_WRITE   equ 1

INTE_VECTOR_SYS_CALL equ 0x80 ; 与protect.h中的保持一致

global getTicks
global write

bits 32
[section .text]
; 能够直接使用寄存器是因为C语言不使用寄存器保存值。
getTicks:
    mov     eax, NUM_GET_TICKS      ; 要完成工作的编号
    int     INTE_VECTOR_SYS_CALL    ; 完成该工作的中断向量号
    ret                             ; 中断处理返回后执行，eax中存放着返回值
    
write:
    mov     eax, NUM_WRITE          ; 输出
    mov     ebx, [esp + 4]
    mov     ecx, [esp + 8]
    int     INTE_VECTOR_SYS_CALL
    ret
