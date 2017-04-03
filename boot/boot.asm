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
; nasm boot.asm  ;不要加-f elf之类的格式参数，否则会将org指令当作标签来处理
; 
;

section .text                           ; unix like platforms user like use lowercase, and 
                                        ; me too.
    org 7c00h                           ; 告诉编译器程序将被加载到0x7c00处，编译器据此计算地址
    JMP entry                           ; 跳转到程序区去执行程序，超过了short跳转的距离，默认使用near跳转，
;    DB  0                               ; 因为FAT12格式要从字节３开始，near跳转正好占３字节。
    DB  "HELLOIPL"                      ; 启动区的名称可以是任意8字节的字符串，不够填‘\0’
    DW  512                             ; 每个扇区（sector）的大小（软盘必须为512字节）
    DB  1                               ; 簇（cluster）的大小（必须为一个扇区）
    DW  1                               ; FAT的起始位置（一般从第一个扇区开始）
    DB  2                               ; FAT的个数（必须为2）
    DW  224                             ; 根目录的大小（一般设为224项）
    DW  2880                            ; 该磁盘的扇区数（软盘大小（bit）/扇区大小）其实扇区数是生产是固定的，不是计算的。真正计算的是扇区数*扇区大小-》磁盘容量
    DB  0xf0                            ; 磁盘的种类（软盘为0Xf0）
    DW  9                               ; FAT的长度（必须是9扇区）
    DW  18                              ; 1个磁道（track）有几个扇区（必须是18）
    DW  2                               ; 磁头数（必须是2）
    DD  0                               ; 不使用分区，必须是0
    DD  2880                            ; 重写一次磁盘大小
    DB  0,0,0x29                        ; 意义不明确，固定
    DD  0xffffffff                      ; （可能是）卷标号码
    DB  "HELLO-OS   "                   ; 磁盘的名称（11字节）
    DB  "FAT12   "                      ; 磁盘格式名称（8字节）

%include    "staticlib.inc"

    

    LOADER_BASE             equ LOADER_ADDRESS >> 4
    LOADER_OFFSET           equ LOADER_ADDRESS & 0x0F

    Loder_Name              DB  "LOADER  BIN" ; 查看linux的输出发现存的是大写。后补空格填够１１字节

    fat_item_num            dw  -1
    load_seg_add            dw  LOADER_ADDRESS >> 4  ; 段地址。

entry:
    mov     ax, cs                      ; | <---千万不要用反斜线，这会对回车进行转义，导致编译器把下一行认为改行的继续
    mov     ds, ax                      ; | 数据段
    mov     ss, ax                      ; | 堆栈地址
    mov     sp, 7c00h                   ; /

    ; 加载根目录到内存0x1700的缓冲区，这里避开终端向量表和ROM BIOS Parameter Ares
    mov     ax, DIRECTORY_ADDRESS >> 4  ; |内存地址
    mov     es, ax                      ; /
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    mov     si, ROOTDIR_START_SECTOR    ; 开始磁盘序号
    mov     di, ROOTDIR_SECTOR_NUM      ; 加载的扇区数  
    call    readSector                  ; 调用读取函数
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS

    ; 找到引导器loader的目录项，读取第一个簇的FAT项位置
    mov     ax, DIRECTORY_ADDRESS >> 4
    mov     es, ax
    mov     si, Loder_Name              ; ds:si指向源字符串
    mov     ax, ROOTDIR_SECTOR_NUM
    call    fileFirstFat
    cmp     ax, 0                       ; |如果是小于０，说明没找到,就跳到结束执行
    jl      .notFindFile                ; /
    mov     [fat_item_num], ax          ; 找到了保存FAT项，用于计算簇

    ; 将FAT项加载进内存0x500的缓冲区，用于寻找剩下的簇
    mov     ax, FAT_ADDRESS >> 4        ; 将FAT区加载进内存0x100的缓冲区
    mov     es, ax
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    mov     si, FAT_START_SECTORS       ; 开始磁盘序号
    mov     di, FAT_SECTOR_NUM   
    call    readSector                  ; 读取FAT表进内存缓冲区 
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS

    ; 将FAT号转换为扇区号，然后读取数据进内存，寻找时候存在下一簇数据，存在的话就继续循环
.nextCluster:
    mov     ax, [fat_item_num]
    sub     ax, 2                       ; 有FAT项计算簇号，由于FAT项0,1并不使用，FAT2对应的簇号比FAT项号小２ 
    add     ax, DATA_START_SECOTRS      ; 计算簇的起始扇区，由于每个簇占一个扇区，这里没有乘每簇扇区数（扇区号＝(FAT项号－2)×每簇扇区号＋数据区起始扇区号)
    mov     si, ax                      ; 开始磁盘序号
    mov     di, SECTORS_OF_CLUSTER      ; 每簇有多少个扇区，一次加载进内存
    mov     ax, [load_seg_add]          ; 将加载器放到0x9000之后的内存
    mov     es, ax                      ; 
    add     ax, 0x20                    ; 计算下一簇数据的加载地址，512字节加在段寄存器上
    mov     [load_seg_add], ax          ; 保存下一个簇的加载地址
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    call    readSector
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS
    mov     ax, [fat_item_num]          ; 此次使用的FAT号
    mov     bx, FAT_ADDRESS             ; FAT表起始地址
    call    nextFatItem                 ; 查找下一个FAT项
    mov     [fat_item_num], ax          ; 保存FAT号
    cmp     ax, 0xFF7                   ; |小于0xff7就寻找下一簇，否则结束
    jb      .nextCluster                ; /

    jmp     LOADER_BASE:LOADER_OFFSET   ; 900h:0000h 

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


times 510-( $-$$ ) db 0                 ; 有org时，$$是程序开始的实际地址，$是本指令的实际地址。
    dw      0xaa55                      ; DB      0x55, 0xaa      另一种写法，明显这是大字端机器