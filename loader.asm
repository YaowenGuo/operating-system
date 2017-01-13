; Exetutable name           : thirdOs.bin
; Version                   : 1.0
; Created date              : 11/10/2016
; Last update               : 01/07/2017
; Author                    : guobool
; Description               : 操作系统启动验证程序
;
; Buile using this command:
;
; nasm loader.asm
; 
;


    org     0                                ;偏移地址为0时，不用写org，或者org 0。两者是一样的。
    jmp     Entery
%include    "staticlib.inc"
    kernel_seg_add  dw  KERNEL_ADDRESS >> 4 ; kernel.bin加载位置的段地址
    Kernel_Name     db  "KERNEL  BIN"
    Load_Access_Msg db  "Loader have been loaded!"
    LOAD_ACCESS_LEN equ $ - Load_Access_Msg

; --------------------------------------------------------------------------------
; 描述符定义，８字节。四字节段基址。两字节和４位的段界限。其它为属性位
; usage: Descriptor Base, Limit, Attr
;        Base:  dd
;        Limit: dd (low 20 bits available)
;        Attr:  dw (lower 4 bits of higher byte are always 0)
%macro descriptor 3
    dw  %2 & 0FFFFh                 ; 段界限低１６位             (2 字节)
    dw  %1 & 0FFFFh                 ; 段基址低１６位             (2 字节)
    db  (%1 >> 16) & 0FFh           ; 段基址中间８位             (1 字节)
    dw  ((%2 >> 8) & 0F00h) | (%3 & 0F0FFh) ; 段界限高４位 + 属性１２位  (2 字节)
    db  (%1 >> 24) & 0FFh           ; 段基址高８位　             (1 字节)
%endmacro

; GDT定义
; 这里代码段描述符直接使用规划好的地址，不用再在程序中定义。如果是在已有的系统上运行，因为程序被加载的位置不确定，
; 需要在程序中计算地址，然后填入相应的位置。
    GDT_Start:      descriptor  0,          0,          0      ; 空描述符
    Desc_Flat_C:    descriptor  0,          0xFFFFF,    0xc09A ; 0~4G代码段：粒度４Ｋ、３２位段、在内存、权限０、可读可执行
    DESC_FLAG_RW:   descriptor  0,          0xFFFFF,    0xc092 ; 0~4G数据段：粒度４Ｋ、３２位段、在内存、权限０、可读可写
    Desc_Video:    descriptor  0xB8000,    0xFFFF,     0xf2    ; 显存首地址 :粒度字节、在内存、权限３、可读可写

    GDT_LEN equ $ - GDT_Start            ; GDT的长度

    gdt_ptr dw  GDT_LEN - 1              ; 16位界限。界限不是长度，而是下标 |需要加载到gdtr？的
            dd  LOADER_ADDRESS + GDT_Start ; 32位地址                   /gdt描述信息。别忘了x86是大字端
; GDT选择子，是描述符的偏移首地址，和权限信息。
    SELECTER_FLATC  equ Desc_Flat_C - GDT_Start
    SELECTER_FLATRW equ DESC_FLAG_RW - GDT_Start
    SELECTER_VIDEO  equ Desc_Video - GDT_Start + 3 ; 请求特权级置３
    
Entery:
    mov     ax, cs
    mov     ds, ax                      ; 数据在代码中，所以使用同一地址
    mov     es, ax                      ; 其实将es转移过来没多大用处，es作为复制目标在改变
                                        ; 堆栈段仍旧使用原来的。

    mov     ax, LOADER_ADDRESS >> 4
    mov     es, ax
    mov     bp, Load_Access_Msg
    mov     cx, LOAD_ACCESS_LEN
    call    printStr

    ; 找到引导器kernel.bin的目录项，读取第一个簇的FAT项位置
    mov     ax, DIRECTORY_ADDRESS >> 4
    mov     es, ax
    mov     si, Kernel_Name             ; ds:si指向源字符串
    mov     ax, ROOTDIR_SECTOR_NUM
    call    fileFirstFat
    cmp     ax, 0                       ; |如果是小于０，说明没找到,就跳到结束执行
    jl      .notFindFile                ; /

    ; 将FAT号转换为扇区号，然后读取数据进内存，寻找时候存在下一簇数据，存在的话就继续循环
.nextCluster:
    push    ax                          ; 保存FAT项，用于计算簇
    sub     ax, 2                       ; 有FAT项计算簇号，由于FAT项0,1并不使用，FAT2对应的簇号比FAT项号小２ 
    add     ax, DATA_START_SECOTRS      ; 计算簇的起始扇区，由于每个簇占一个扇区，这里没有乘每簇扇区数（扇区号＝(FAT项号－2)×每簇扇区号＋数据区起始扇区号)
    mov     si, ax                      ; 开始磁盘序号
    mov     di, SECTORS_OF_CLUSTER      ; 每簇有多少个扇区，一次加载进内存
    mov     ax, [kernel_seg_add]        ; 将加载器放到0x80000之后的内存
    mov     es, ax                      ; 
    add     ax, 512 >> 4                ; 每簇只有一个扇区，计算下一簇数据的加载地址,512字节加在段寄存器上
    mov     [kernel_seg_add], ax        ; 保存下一个簇的加载地址
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    call    readSector
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS
    pop     ax                          ; 此次使用的FAT号
    mov     bx, FAT_ADDRESS             ; FAT表起始地址
    call    nextFatItem                 ; 查找下一个FAT项
    cmp     ax, 0xFF7                   ; |小于0xff7就寻找下一簇，否则结束
    jb      .nextCluster                ; /

    call    closeFloppyDrive            ; 关闭软驱

; 准备跳入３２位代码段
    ; 加载GDT
    lgdt    [gdt_ptr]

    ; 关中断
    cli

    ; 打开地址线A20
    in      al, 92h
    or      al, 00000010b
    out     92h, al

    ; 设置模式标识位为保护模式，只将cr0的０位置１，其它位不要动
    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax                    ; 在此之后执行的代码都是按照３２位指令执行

    ; 真正进入保护模式，这里需要将代码段的选择子装入cs,由于是３２位指令，却在１６位程序中，
    ; 它属于混合编程的一部分，直接这样写“jmp     SELECTER_FLATC:0“是不严谨的，这样编译
    ; 出来的是16位代码，如果目标地址不是０，而是一个很大的值，编译后会被阶段，如jmp SELECTER_FLATC
    ; :0x12345678,只剩下0x5678
    jmp     dword SELECTER_FLATC:(LOADER_ADDRESS + ProterModeStart)         

.readSectorError:                       ; 出错时的输出提示
    mov     ax, ds
    mov     es, ax
    mov     bp, Read_Sector_error
    mov     cx, READ_SECTOR_STRLEN
    jmp     .print
.notFindFile:
    mov     ax, ds
    mov     es, ax
    mov     bp, Not_Find_File
    mov     cx, NOT_FIND_STRLEN
.print:
    call    printStr
    hlt                                 ; 暂停一下，收到信号再回到BIOS
    mov ax, 4c00h                       ; ┓读取扇区出错，回到BIOS
    int 21h                             ; ┛  


[section .s32] ;32位代码段，由实模式跳入。也是该段中$$的地址
align 32  ; ?
[bits 32] ; 告诉编译器，此段使用３２位指令

ProterModeStart:
    mov     ax, SELECTER_VIDEO
    mov     gs, ax

    mov     edi, (80 * 11 + 39) * 2     ; 屏幕第１１行，第９列
    mov     ah, 0ch                     ; 0000:黑底  1100:红字
    mov     al, 'p'
    mov     [gs:edi], ax

.stop:
   
   hlt
   jmp     .stop
    

;---------------------------------------------------------------------------
; 关闭软盘驱动
; 

closeFloppyDrive:
    push    dx
    mov     dx, 3f2h
    mov     al, 0
    out     dx, al
    pop     dx
    ret 


