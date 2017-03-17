[section .text]
global  dispAChar
global  dispStr
global  memCpy

    disp_position_dw:  dd    0
;----------------------------------------------------------------
; 显示一个字符，特殊字符除换行特殊处理，其他字符都直接打印
; 入栈：一字节字符
; 入栈：一字节颜色值
; disp_position_dw: 显示的位置
; 无返回值
;
dispAChar:
    push    ebp
    mov     ebp, esp
    push    edi
    push    eax
    push    ebx
    mov     edi, [disp_position_dw]
    mov     ax, [ebp + 8]
    cmp     al, 0Ah                 ; 是回车吗？
    jne     .printChar              ; 不是，打印该字符
    ; 是回车，计算下一行的首字符的位置
    push    eax                     ; 保护字符信息
    ; 计算行数
    mov     eax, edi
    mov     bl,  160
    div     bl
    and     eax, 0FFh
    inc     eax                     ; 加一行
    mov     bl, 160
    mul     bl
    mov     edi, eax
    pop     eax                     ; 获取字符信息
    jmp     .savePosition           ; 跳过显示
.printChar:
    mov     [gs:edi], ax
    add     edi, 2
    ; 保存下一次显示的位置
.savePosition:
    mov     [disp_position_dw], edi
    pop     ebx
    pop     eax
    pop     edi
    pop     ebp
    ret

;----------------------------------------------------------------------
; 显示一个字符串，使用C语言中的规范，以0作为字符串的结束标志。为了能够在ｃ语言中调用
; 该函数，使用c语言参数的传递规范，使用堆栈传递参数
; 入栈：字符串首地址
; 

dispStr:
    push    ebp
    mov     ebp, esp
    push    esi
    push    eax
    mov     esi, [ebp + 8]      ; 获取字符串首地址
    mov     ah, 0fh             ; 白字
.nextChar:
    lodsb                       ; al <- [esi]
    test    al, al              ; 是０吗？
    jz      .end
    push    ax                  ; 低字节字符，高字节颜色
    call    dispAChar
    add     esp, 2              ; 恢复堆栈
    jmp     .nextChar
.end:
    pop     eax
    pop     esi
    pop     ebp
    ret

;-------------------------------------------------------------------------
; 内存拷贝
; void* memCpy( void * es:pDest, void* ds:pSrc, int iSize);
; pDest:    point destination
; pSrc:     point source
; iSize:    int size
; return:   destination

memCpy:
    push    ebp
    mov     ebp, esp
    push    esi
    push    edi
    push    ecx

    mov     edi, [ebp + 8]          ; Destination
    mov     esi, [ebp + 12]         ; Source
    mov     ecx, [ebp + 16]         ; Counter
    cld
    rep     movsb

    mov     eax, [ebp + 8]
    pop     ecx
    pop     edi
    pop     esi
    pop     ebp
    ret