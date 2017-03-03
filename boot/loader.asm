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

;---------------------------------------------------------------------------
; 获取内存占用信息
; 
%macro getMemoryInfo 0
    mov     ax, cs
    mov     es, ax
    mov     di, _mem_check_buf
    mov     ecx, 20
    mov     ebx, 0
.loop:
    mov     edx, 'PAMS'         ; SMAP会以相反的顺序转换数字，还是直接写数字靠谱
    mov     eax, 0E820h
    int     15h
    jc      .memCheckError
    add     di, 20
    inc     byte [_ARDS_num_dw]
    cmp     ebx, 0
    jne     .loop
    jmp     .memCheckOk
.memCheckError:
    mov     dword [_ARDS_num_dw], 0
.memCheckOk:

%endmacro



; GDT定义
; 这里代码段描述符直接使用规划好的地址，不用再在程序中定义。如果是在已有的系统上运行，因为程序被加载的位置不确定，
; 需要在程序中计算地址，然后填入相应的位置。
    GDT_Start:      descriptor  0,          0,          0      ; 空描述符
    Desc_Flat_C:    descriptor  0,          0xFFFFF,    0xc09A ; 0~4G代码段：粒度４Ｋ、３２位段、在内存、权限０、可读可执行
    Desc_Flat_RW:   descriptor  0,          0xFFFFF,    0xc092 ; 0~4G数据段：粒度４Ｋ、３２位段、在内存、权限０、可读可写
    Desc_Video:     descriptor  0xB8000,    0xFFFF,     0xf2   ; 显存首地址 :粒度字节、在内存、权限３、可读可写

    GDT_Len equ $ - GDT_Start            ; GDT的长度

    GDT_pointer dw  GDT_Len - 1              ; 16位界限。界限不是长度，而是下标 |需要加载到gdtr？的
                dd  LOADER_ADDRESS + GDT_Start ; 32位地址                   /gdt描述信息。别忘了x86是大字端
; GDT选择子，是描述符的偏移首地址，和权限信息。C:Code, R:Read, W:Write
    SELECTER_FLATC  equ Desc_Flat_C - GDT_Start
    SELECTER_FLATRW equ Desc_Flat_RW - GDT_Start
    SELECTER_VIDEO  equ Desc_Video - GDT_Start + 3 ; 请求特权级置３


; 定义一定大小的缓冲区，用于存储内存信息
    ; 注意，以下划线开始的标号在实模式下使用，标识同一个内存，不以下划线开始的标号，在保护模式下使用。
    ; 另一点需要注意的是，汇编语言与高级语言不同，标号本身不带有数据长度信息，但实际对应的空间却是有长度的
    ; 为了在程序中就能体现处数据的长度，这里以后缀的形式给出，如"_dw"

    ; 一下标号是偏移地址，用于实模式
    _Mem_Disp_Title_Str  db  "StartAddress      Length            Type", 0Ah, 0  ;添加换行和结束标志，使用C语言中的字符串结束标志 
    _mem_check_buf: times 256   db  0
    _ARDS_num_dw:   dd  0   ; ARDS:Address Range Descriptor Structor. 256 / 20 只用一字节就够了
    _Mem_Size_Hint:  db  "Memory size is: ",0
    _mem_size_dq:    dq  0

    ; 以下标号是线性地址，用于保护模式
    Mem_Disp_Title_Str: equ LOADER_ADDRESS + _Mem_Disp_Title_Str
    mem_check_buf:  equ LOADER_ADDRESS + _mem_check_buf
    ARDS_num_dw:    equ LOADER_ADDRESS + _ARDS_num_dw
    Mem_Size_Hint:  equ LOADER_ADDRESS + _Mem_Size_Hint
    mem_size_dq:    equ LOADER_ADDRESS + _mem_size_dq
    
; 定义一个内存空间，用于存放内存显存中光标的位置
    disp_position_dw:  dd    0

; 定义页目录，页权限描述符
    PG_P:   equ 1
    PG_USU: equ 2
    PG_RWW: equ 3
    PG_RWR: equ 4




    
Entery:
    mov     ax, cs
    mov     ds, ax                      ; 数据在代码中，所以使用同一地址
    mov     es, ax                      ; 其实将es转移过来没多大用处，es作为复制目标在改变
                                        ; 堆栈段仍旧使用原来的。
    ; 清屏
    mov ax, 0600h                       ; AH = 6,  AL = 0h
    mov bx, 0700h                       ; 黑底白字(BL = 07h)
    mov cx, 0                           ; 左上角: (0, 0)
    mov dx, 0184fh                      ; 右下角: (80, 50)
    int 10h                             ; int 10h

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

    getMemoryInfo

; 准备跳入３２位代码段
    ; 加载GDT
    lgdt    [GDT_pointer]

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
[bits 32] ; 告诉编译器，此段使用３２位指令。缺少该伪指令会导致编译出的代码错误

; 如下的两个宏要在３２位代码段中使用，所以要放在[bits 32]之后，否则会出现编译后的指令错误
%macro dispMemInfo 0
    ; 显示提示表头
    push    Mem_Disp_Title_Str
    call    dispStr
    add     esp, 4 

    mov     ebx, mem_check_buf
    mov     ecx, [ARDS_num_dw]
.loop:
    mov     esi, ebx
    ; 显示地址
    call    dispLongInHex

    mov     al, ' '
    push    ax                  ; 低字节字符，高字节颜色
    call    dispAChar           ; 输出字符
    add     esp, 2              ; 恢复栈指针
    ; 显示长度
    add     esi, 8
    call    dispLongInHex

    mov     al, ' '
    push    ax
    call    dispAChar
    add     esp, 2
    ; 显示类型
    add     esi, 8
    call    dispIntInHex

    mov     al, 0Ah             ; 换行符
    push    ax
    call    dispAChar
    add     esp, 2
;    mov     eax, [esi]
    ; 计算内存总量，虽然这里对内存的可用与否进行了判断，但在计算时，除了最后一个
    ; 不可用块没有计入总量，其他都算入了结果。这是因为使用了”结果＝首地址＋长度“，
    ; 而不是”结果＝上次的结果＋长度的“的计算方法。
    cmp     dword[esi], 1           ; 类型１，表示可用内存
    jne     .next                   ; 否则，不用计算，直接显示下一组
    ; ６４位数加法
    ; 低３２位相加，并保存
    mov     eax, [ebx]
    add     eax, [ebx + 8]
    mov     [mem_size_dq], eax
    ; 高３２位带进位相加，并保存
    mov     eax, [ebx + 4]
    adc     eax, [ebx + 12]
    mov     [mem_size_dq+4], eax

.next:
    add     ebx, 20
    loop    .loop
    ; 显示内存总量
    push    Mem_Size_Hint
    call    dispStr
    add     esp, 4                  ; 恢复堆栈
    mov     esi, mem_size_dq
    call    dispLongInHex

%endmacro

%macro setupPaging 0
    ; 根据内存大小计算应初始化多少页目录项，以及多少页表
    xor     edx, edx
    mov     eax, [mem_size_dq]
    mov     ebx, 1024 * 4094        ; 每个页表有1024个页表项，每个表项指向的也为４０９６字节
    div     ebx
    test    edx, edx
    jz      .no_remainder
    inc     eax
    ; 初始化目录表
.no_remainder:
    push    eax
    mov     ecx, eax
    mov     ax, SELECTER_FLATRW
    mov     es, ax
    mov     edi, PAGE_DIR_ADDRESS
    mov     eax, PAGE_TABLE_ADDRESS | PG_P | PG_USU | PG_RWW
.nextDirEntry:
    stosd
    add     eax, 4096
    loop    .nextDirEntry
    ; 初始化页表
    pop     eax
    mov     ebx, 1024
    mul     ebx
    mov     ecx, eax
    mov     edi, PAGE_TABLE_ADDRESS
    mov     eax, PG_P | PG_USU | PG_RWR
    cld
.nextPageEntry:
    stosd
    add     eax, 4096
    loop    .nextPageEntry
    ; 将cr3指向页目录表
    mov     eax, PAGE_DIR_ADDRESS
    mov     cr3, eax
    ; 打开分页机制
    mov     eax, cr0
    or      eax, 80000000h
    mov     cr0, eax
%endmacro


ProterModeStart:
    mov     ax, SELECTER_VIDEO
    mov     gs, ax
; 设置好段选择子，否则会在访问非法时，出现跳转
    mov     ax, SELECTER_FLATRW
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     ss, ax

    mov     edi, (80 * 0 + 39) * 2     ; 屏幕第0行，第９列
    mov     ah, 0ch                     ; 0000:黑底  1100:红字
    mov     al, 'p'
    mov     [gs:edi], ax

    dispMemInfo
    setupPaging

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



;----------------------------------------------------------------------
; 以１６进制显示一个８字节整数
; esi: 内存地址
; 
dispLongInHex:
    push    ebx
    push    ecx
    push    edx
    mov     edx, 4                  ; ４字节为单位处理
.next32bit:
    mov     ebx, [esi+edx]          ; 获取高４字节的数据
    mov     ecx, 8                  ; ４字节３２位转换为８个１６进制
.loop:
    push    ecx
    mov     ecx, 4                  ; 每次循环移位４位
    rol     ebx, cl
    mov     al, bl
    call    num2ASCII
    mov     ah, 0Fh
    push    ax 
    call    dispAChar
    add     esp, 2
    pop     ecx
    loop    .loop
    sub     edx, 4
    jz      .next32bit
    ; 显示一个h
    mov     ah, 07h
    mov     al, 'h'
    push    ax
    call    dispAChar
    add     esp, 2
    pop     edx
    pop     ecx
    pop     ebx
    ret
;---------------------------------------------------------------------
; 将数字转化为该数字的ASCII码
; al:低四位，数字
; 返回　al:数字的ASCII码
; 
num2ASCII:
    and     al, 0Fh
    add     al, '0'
    cmp     al, '9'
    jbe     .end
    add     al, 'A'-':'
.end:
    ret
;----------------------------------------------------------------------
; 以１６进制显示一个32位整数
; esi: 内存地址
; 
dispIntInHex:
    push    ebx
    push    ecx

    mov     ebx, [esi]              ; 获取４字节的数据
    mov     ecx, 8                  ; ４字节３２位转换为８个１６进制
.loop:
    push    ecx
    mov     ecx, 4                  ; 每次循环移位４位
    rol     ebx, cl
    mov     al, bl
    call    num2ASCII
    mov     ah, 0Fh 
    push    ax
    call    dispAChar
    add     esp, 2
    pop     ecx
    loop    .loop
    ; 显示一个h
    mov     ah, 07h
    mov     al, 'h'
    push    ax
    call    dispAChar
    add     esp, 2

    pop     ecx
    pop     ebx
    ret