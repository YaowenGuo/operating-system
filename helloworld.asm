; Exetutable name           : helloworle
; Version                   : 1.0
; Created date              : 10/31/2016
; Last update               : 10/31/2016
; Author                    : guobool
; Description               : A simple prgoram to be write boot section just 
;                           output a string "hello world!". The program used for
;                           execixe to hardware program
;
; Buile using this command:
;
;   yasm  helloworld.asm   ;不要加-f elf之类的格式参数，否则会将org指令当作标签来处理
; 
;

; section .text             ; unix like platforms user like use lowercase, and 
                            ; me too.
    org 0x7c00              ; 告诉编译器程序将被加载到0x7c00处，该伪指令并不会影像寄存器和立即数或
                            ; 一般指令的编译。只会影响到标签的地址计算，如标签和过程名在编译时会被编
                            ; 译为地址，没有org时，程序的开始地址是使用段地址从0开始计算的，而有了
                            ; org，标签的地址是以org指令的地址加上偏移地址。
                             
    mov ax, 0               ; call指令需要入栈操作，所以设置了ss和sp
    mov ss, ax              
    mov sp, 7c00H           
    call PrintStr
deadloop:
    hlt                     ; (halt停止）让CPU进入等待状态。只要外部发生变化，如按下键盘
                            ; 或移动鼠标，cpu就会醒来加入SHL后CPU就不会毫无意义的空转，
                            ; 非常省电, 作为一个初学者更应该样成良好的习惯。
    jmp deadloop



PrintStr:
    mov ax, cs              ; 设置es:bp指向字符串字符串，int 10h调用使用其作为输出起始
    mov es, ax
    mov ax, Msg
    mov bp, ax
    mov cx, MSGLEN          ; 设置字符串的长度
    mov ah, 13H             ; 调用字符串输出功能
    mov al, 1H              ; 光标跟随移动
    mov bl, 0cH             ; 黑底红字
    int 10H                 ; 调用BIOS功能
    ret
Msg:    db "Hello, Wordl!"
MSGLEN  equ $ - Msg

times 510-( $-$$ ) db 0     ; 引导扇区512字节的剩余空间添0。这里有个陷阱，在没有制定org时，$$是本段
                            ; 的首指令的偏移地址，$是本指令的的偏移地址，因为没有org时，程序将被看成
                            ; 从0地址开始。而有org时，$$是程序开始的实际地址，$是本指令的实际地址。
                            ; 因为程序看作是从org指定的地址开始，即程序的第一条指令的地址是org制定的
                            ; 地址。这时用510-$是错误的，要使用0x7dfe-$。随意最好使用本例给出的地址
                            ; 减地址，长度减长度的计算方法。
    dw 0xaa55

