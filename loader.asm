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


    ;偏移地址为0时，不用写org，或者org 0。两者是一样的。
    jmp     Entery
%include    "staticlib.inc"
    kernel_seg_add  dw  KERNEL_ADDRESS >> 4 ; kernel.bin加载位置的段地址
    Kernel_Name     db  "KERNEL  BIN"
    Load_Access_Msg db  "Loader have been loaded!"
    LOAD_ACCESS_LEN equ $ - Load_Access_Msg
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
    add     ax, 512 >> 4                ; 每簇只有一个扇区，计算下一簇数据的加载地址
    mov     [kernel_seg_add], ax        ; 保存下一个簇的加载地址
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    call    readSector
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS
    pop     ax                          ; 此次使用的FAT号
    mov     bx, FAT_ADDRESS             ; FAT表起始地址
    call    nextFatItem                 ; 查找下一个FAT项
    cmp     ax, 0xFF7                   ; |小于0xff7就寻找下一簇，否则结束
    jb      .nextCluster                ; /

.stop:
    call    closeFloppyDrive            ; 关闭软驱
    hlt
    jmp     .stop

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



;---------------------------------------------------------------------------
; 关闭软盘驱动
; 

closeFloppyDrive：
    push    dx
    mov     dx, 3f2h
    mov     al, 0
    out     dx, al
    pop     dx
    ret 
