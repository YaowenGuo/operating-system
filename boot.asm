; Exetutable name           : boot.bin
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
; yasm boot.asm -o boot.bin ;不要加-f elf之类的格式参数，否则会将org指令当作标签来处理
; 
;


section .text               ; unix like platforms user like use lowercase, and 
                            ; me too.
    org     7c00h           ; 告诉编译器程序将被加载到0x7c00处，编译器据此计算地址
    mov     ax, 0           ; | <---千万不要用反斜线，这会对回车进行转义，导致编译器把下一行认为改行的继续
    mov     ss, ax          ; |堆栈地址
    mov     sp, 7c00h       ; /
    
    mov     ax, 800h        ; |
    mov     es, ax          ; |内存地址
    xor     bx, bx          ; /
    mov     dl, 0           ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    mov     si, 1           ; 开始磁盘序号
    mov     di, 20          ; 磁盘数量
    call    readSector      ; 调用读取函数
    jc      ReadSectorError ; 出错，显示错误，调用BIOS回到BIOS

    jmp     8000h

ReadSectorError:
    mov     ax, 0
    mov     es, ax
    mov     bp, READ_SECTOR_ERROR
    mov     cx, SECTOR_ERROR_STRLEN
    call    printStr
    hlt                     ; 暂停一下，收到信号再回到BIOS
    mov ax, 4c00h           ; ┓读取扇区出错，回到BIOS
    int 21h                 ; ┛

    READ_SECTOR_ERROR db "Load Disk Error!\n"
    SECTOR_ERROR_STRLEN equ $ - READ_SECTOR_ERROR
    READ_SECTOR_GOOD db  "Load Disk Access!\n"
    READ_GOOD_STRLEN equ $ - READ_SECTOR_GOOD                          





;-----------------------------------------------------------
; 读取指定序号扇区开始的ｎ个扇区到内存
; es:bx :内存地址
; si    :起始扇区序号
; di    :要读取的扇区个数
; dl    :驱动器号
;
;return:
; cf    :0-没有错误，1-有错误
; ah    :0-成功，非0-错误码
; al    :ah==0,al为读取的扇区数
readSector:
    push    bp
    mov     bp, sp
    push    ax              ; 用于传递扇区序号和返回值，所以要保存
    push    cx              ; 被numToLocation用户返回磁道号和扇区号
    push    dx              ; dh被numToLocation返回磁头号，和驱动器号
NextSector:
    mov     ax, si          ; 将扇区序号放到ａｘ中用于计算
    call    numToLocation   ; 将扇区序号转化为物理位置（磁道，磁头，扇区）
    call    readOneSector   ; 读取一个扇区
    jc      .fin            ; 出错就返回，readOneSecotr的返回值作为本函数的返回值
    dec     di              ; |
    cmp     di, 0           ; |判断扇区个数是否满足结束条件
    jz      .fin            ; /
    inc     si              ; 扇区序号加１
    mov     ax, es          ; |
    add     ax, 20h         ; |es:bx的地址加５１２字节
    mov     es, ax          ; /
    jmp     NextSector      ; 读取下一个扇区
.fin:
    pop     dx
    pop     cx
    pop     ax
    mov     sp, bp
    pop     bp
    ret

;-----------------------------------------------------------
; 由扇区序号（从０开始的所有扇区排列）计算磁道号，磁头号，扇区号
; ax    :要读取的扇区号
;
; return:
; ch    :磁道号
; cl    :扇区号
; dh    :磁头号
; 设扇区号为 x
;                          ┌ 柱面号 = y / 磁头数
;       x           ┌ 商 y ┤
; -------------- => ┤      └ 磁头号 = y ％ 磁头数
; 每磁道扇区数        │
;                   └ 余 z => 起始扇区号 = z + 1  
numToLocation:
    TRACK_SECTOR   equ 18   ; 软盘的每个磁道18个扇区
    MAGHEAD_NUM    equ 2    ; 软盘有两个磁头

    mov     cl, TRACK_SECTOR
    div     cl              ;　ah-余数z，al商y
    inc     ah              ; 扇区号从１开始，所以加一
    push    ax              ; 保存扇区号
    xor     ah, ah          ; 清空ah,　使用al的值／磁头数，来计算磁头号和磁道号
    mov     cl, MAGHEAD_NUM ; 获取磁头数，因为有些磁盘不止两个磁头
    div     cl              ; 除后，ah-磁头号，al-磁道号
    mov     dh, ah          ; 磁头号放到dh    
    mov     ch, al          ; 磁道号（柱面号）放到ch
    pop     ax              ; | 扇区号放到cl
    mov     cl, ah          ; /
    ret 


;------------------------------------------------------------------
; 读取一个扇区，因为软盘等介质并不稳定，一次可能读取失败，可以多读几次。最多读５次
; es:bx :内存地址
; dh/dl :磁头号／驱动器号
; ch    :磁道号
; cl    :扇区号
; return  
; cf    :0-没有错误，1-有错误
; ah    :0 成功，非0:错误码
; al    :ah==0,al为读取的扇区数
readOneSector:
    DISKERRORTIME  equ 5    ; 磁盘发生错误的最大读取次数
    push    bp              ; |
    mov     bp, sp          ; | 保存寄存器
    push    si              ; /
    mov     si, DISKERRORTIME ; 设置最大出错读取次数
.retry:
    mov     ah, 2           ; |
    mov     al, 1           ; | 读取一个扇区，因为出错是ax返回值，所以每次都要设置
    int     0x13            ; /
    jnc     .fin            ; 没出错直接结束
    dec     si              ; 出错剩余次数减１
    jz      .fin            ; 剩余０次后也跳转到结束
    mov     ah, 0           ; | 
    mov     dl, 0           ; | 磁盘复位后再读一次
    int     0x13            ; |
    jmp     .retry          ; /
.fin:
    pop     si              ; | 恢复寄存器
    mov     sp, bp          ; |
    pop     bp              ; /
    ret


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

times 510-( $-$$ ) db 0     ; 有org时，$$是程序开始的实际地址，$是本指令的实际地址。
    dw 0xaa55               ; DB      0x55, 0xaa      另一种写法，明显这是大字端机器