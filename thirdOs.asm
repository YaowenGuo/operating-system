; Exetutable name           : thirdOs.bin
; Version                   : 1.0
; Created date              : 11/10/2016
; Last update               : 11/10/2016
; Author                    : guobool
; Description               : 操作系统启动验证程序
;
; Buile using this command:
;
; yasm thirdOs.asm -o thirdOs.bin 
; 
;

    org     8000h
    jmp     Entery
    STR: db "Operating Systeam has been booted!"
    STR_LEN: equ $ - STR
Entery:
    mov     ax, 0
    mov     es, ax
    mov     bp, STR
    mov     cx, STR_LEN
    call    printStr
stop:
    hlt
    jmp     stop
;----------------------------------------------------------------
; 输出字符串
; ES:BP   :字符串首地址
; 
printStr:                   ; 这里有一个陷阱，不能再将sp赋值给bp了，因为bp存了字符串地址
    push    ax
    push    bx
    push    dx

    mov     ax, 1301h       ; AH = 13,显示字符串,  AL = 01h 写方式
    mov     bx, 0007h       ; 页号为0(BH = 0) 黑底白字(BL = 07h)
    mov     dx, 0           ; dh-0行,dl-0列
    int     10h
    pop     dx
    pop     bx
    pop     ax
    ret
