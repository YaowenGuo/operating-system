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

section .text                           ; unix like platforms user like use lowercase, and 
                                        ; me too.
    org     7c00h                       ; 告诉编译器程序将被加载到0x7c00处，编译器据此计算地址
    JMP     entry                       ; 跳转到程序区去执行程序
    DB  0                               ; 占位，因为FAT12格式要从字节３开始
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

    ROOTDIR_START_SECTOR    equ 19
    ROOTDIR_SECTOR_NUM      equ  14     ; 根目录扇区数
    NOT_FIND_FILE           DB  "NOT FIND FILE\n"
    NOT_FIND_STRLEN         equ $-NOT_FIND_FILE
    DATA_START_SECOTRS      equ 33
    FAT_START_SECTORS       equ 1  
    FAT_SECTOR_NUM          equ 9
    FAT_ITEM_NUM            dw  0
    SECTORS_OF_CLUSTER      equ 1
    LOAD_ADDRESS            dw  800h    ; 段地址。
    READ_SECTOR_ERROR       db  "Load Disk Error!\n"
    SECTOR_ERROR_STRLEN     equ $ - READ_SECTOR_ERROR
    READ_SECTOR_GOOD        db  "Load Disk Access!\n"
    READ_GOOD_STRLEN        equ $ - READ_SECTOR_GOOD 
entry:
    mov     ax, 0                       ; | <---千万不要用反斜线，这会对回车进行转义，导致编译器把下一行认为改行的继续
    mov     ss, ax                      ; |堆栈地址
    mov     sp, 7c00h                   ; /

    ; 加载根目录到内存0x100的缓冲区，这里的分配给操作系统的中断向量表，但由于系统还未加载，可以使用
    mov     ax, 10h                     ; |内存地址
    mov     es, ax                      ; /
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    mov     si, ROOTDIR_START_SECTOR    ; 开始磁盘序号
    mov     di, ROOTDIR_SECTOR_NUM      ; 加载的扇区数  
    call    readSector                  ; 调用读取函数
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS

    ; 找到引导器loader的目录项，读取第一个簇的FAT项位置
    mov     ax, 10h
    mov     es, ax
    mov     ax, ROOTDIR_SECTOR_NUM
    call    findStartFatItem
    cmp     ax, 0                       ; |如果是小于０，说明没找到,就跳到结束执行
    jl      .notFindFile                ; /
    mov     [FAT_ITEM_NUM], ax          ; 找到了保存FAT项，用于计算簇

    ; 将FAT项加载进内存0x100的缓冲区，用于寻找剩下的簇
    mov     ax, 10h                     ; 将FAT区加载进内存0x100的缓冲区
    mov     es, ax
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    mov     si, FAT_START_SECTORS       ; 开始磁盘序号
    mov     di, FAT_SECTOR_NUM   
    call    readSector                  ; 读取FAT表进内存缓冲区 
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS

    ; 将FAT号转换为扇区号，然后读取数据进内存，寻找时候存在下一簇数据，存在的话就继续循环
.nextCluster:
    mov     ax, [FAT_ITEM_NUM]
    sub     ax, 2                       ; 有FAT项计算簇号，由于FAT项0,1并不使用，FAT2对应的簇号比FAT项号小２ 
    add     ax, DATA_START_SECOTRS      ; 计算簇的起始扇区，由于每个簇占一个扇区，这里没有乘每簇扇区数（扇区号＝(FAT项号－2)×每簇扇区号＋数据区起始扇区号)
    mov     si, ax                      ; 开始磁盘序号
    mov     di, SECTORS_OF_CLUSTER      ; 每簇有多少个扇区，一次加载进内存
    mov     ax, [LOAD_ADDRESS]          ; 将加载器放到0x8000之后的内存
    mov     es, ax                      ; 
    add     ax, 0x20                    ; 计算下一簇数据的加载地址
    mov     [LOAD_ADDRESS], ax          ; 保存下一个簇的加载地址
    mov     dl, 0                       ; 驱动器号，A驱动器，有多个软件驱动器的时候，用于指定哪个驱动器
    call    readSector
    jc      .readSectorError            ; 出错，显示错误，调用BIOS回到BIOS
    mov     ax, [FAT_ITEM_NUM]          ; 此次使用的FAT号
    mov     bx, 100h                    ; FAT表起始地址
    call    nextFatItem                 ; 查找下一个FAT项
    mov     [FAT_ITEM_NUM], ax          ; 保存FAT号
    cmp     ax, 0xFF7                   ; |小于0xff7就寻找下一簇，否则结束
    jb      .nextCluster                ; /

    jmp     0x8000

.readSectorError:                       ; 出错时的输出提示
    mov     ax, 0
    mov     es, ax
    mov     bp, READ_SECTOR_ERROR
    mov     cx, SECTOR_ERROR_STRLEN
    jmp     .print
.notFindFile:
    mov     ax, 0
    mov     es, ax
    mov     bp, NOT_FIND_FILE
    mov     cx, NOT_FIND_STRLEN
.print:
    call    printStr
    hlt                                 ; 暂停一下，收到信号再回到BIOS
    mov ax, 4c00h                       ; ┓读取扇区出错，回到BIOS
    int 21h                             ; ┛                      

;-----------------------------------------------------------
; 找到文件的入口
; 传递目录的开始扇区和扇区总数，以及文件名，查看此连续扇区上是否有该文件，
; 返回文件的起始簇号,不存在返回０
; es : 缓冲区地址
; ax : 扇区数

    FILE_NAME       DB  "LOADER     "   ; 但对照linux的输出发现存的是大写，所以这里使用大写的字符串，后补空格
    ITEN_ONE_SECTOR equ 16              ; 每个扇区512字节，每个目录项32字节，512/32
    FILE_NEME_LEN   equ 11              ; 根目录的扇区数
findStartFatItem:
    mov     cl, ITEN_ONE_SECTOR         ; |计算出11个扇区的根目录总共有多少条目录项
    mul     cl                          ; /
.nextItem:
    cmp     ax, 0                       ; |目录项小于等于０，没有找到，就结束
    jz      .notFind                    ; /
    xor     di, di                      ; |es:di指向目标，
    mov     si, FILE_NAME               ; |ds:si指向文件名LOADER
    mov     cx, FILE_NEME_LEN           ; |cx是字符串的长度
    repe    cmpsb                       ; /cx==0或者两字符不等时结束，
    jz      .find                       ; 如果结束时0标志位为０则说明找到

    dec     ax                          ; 条目数减一
    mov     bx, es                      ; |es:di增加32，然后调到下一次比较
    add     bx, 2                       ; |
    mov     es, bx                      ; |
    jmp     .nextItem                   ; /

.find:
    mov     di, 26                      ; |找到之后将目录项的FAT项号取出
    mov     ax, [es:di]                 ; |
    jmp     .end                        ; /
.notFind:
    mov     ax, -1                      ; 没找到返回－１
.end:
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
%macro numToLocation 0
    TRACK_SECTOR   equ 18               ; 软盘的每个磁道18个扇区
    MAGHEAD_NUM    equ 2                ; 软盘有两个磁头

    mov     cl, TRACK_SECTOR
    div     cl                          ;　ah-余数z，al商y
    inc     ah                          ; 扇区号从１开始，所以加一
    push    ax                          ; 保存扇区号
    xor     ah, ah                      ; 清空ah,　使用al的值／磁头数，来计算磁头号和磁道号
    mov     cl, MAGHEAD_NUM             ; 获取磁头数，因为有些磁盘不止两个磁头
    div     cl                          ; 除后，ah-磁头号，al-磁道号
    mov     dh, ah                      ; 磁头号放到dh    
    mov     ch, al                      ; 磁道号（柱面号）放到ch
    pop     ax                          ; | 扇区号放到cl
    mov     cl, ah                      ; /
%endmacro

;-----------------------------------------------------------
; 读取指定序号扇区开始的ｎ个扇区到内存
; es*16 :内存地址
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
    push    ax                          ; 用于传递扇区序号和返回值，所以要保存
    push    bx
    mov     bx, 0 
    push    cx                          ; 被numToLocation用户返回磁道号和扇区号
    push    dx                          ; dh被numToLocation返回磁头号，和驱动器号
NextSector:
    mov     ax, si                      ; 将扇区序号放到ａｘ中用于计算
    numToLocation                       ; 将扇区序号转化为物理位置（磁道，磁头，扇区）
    call    readOneSector               ; 读取一个扇区
    jc      .fin                        ; 出错就返回，readOneSecotr的返回值作为本函数的返回值
    dec     di                          ; |
    cmp     di, 0                       ; |判断扇区个数是否满足结束条件
    jz      .fin                        ; /
    inc     si                          ; 扇区序号加１
    mov     ax, es                      ; |
    add     ax, 20h                     ; |es:bx的地址加５１２字节
    mov     es, ax                      ; /
    jmp     NextSector                  ; 读取下一个扇区
.fin:
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    mov     sp, bp
    pop     bp
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
    DISKERRORTIME  equ 5                ; 磁盘发生错误的最大读取次数
    push    bp                          ; |
    mov     bp, sp                      ; | 保存寄存器
    push    si                          ; /
    mov     si, DISKERRORTIME           ; 设置最大出错读取次数
.retry:
    mov     ah, 2                       ; |
    mov     al, 1                       ; | 读取一个扇区，因为出错是ax返回值，所以每次都要设置
    int     0x13                        ; /
    jnc     .fin                        ; 没出错直接结束
    dec     si                          ; 出错剩余次数减１
    jz      .fin                        ; 剩余０次后也跳转到结束
    mov     ah, 0                       ; | 
    mov     dl, 0                       ; | 磁盘复位后再读一次
    int     0x13                        ; |
    jmp     .retry                      ; /
.fin:
    pop     si                          ; | 恢复寄存器
    mov     sp, bp                      ; |
    pop     bp                          ; /
    ret

;----------------------------------------------------------------
; 输出字符串
; ES:BP   :字符串首地址
; 
printStr:                               ; 这里有一个陷阱，不能再将sp赋值给bp了，因为bp存了字符串地址
    push    ax
    push    bx
    push    dx

    mov     ax, 1301h                   ; AH = 13,显示字符串,  AL = 01h 写方式
    mov     bx, 0007h                   ; 页号为0(BH = 0) 黑底白字(BL = 07h)
    mov     dx, 0                       ; dh-0行,dl-0列
    int     10h
    pop     dx
    pop     bx
    pop     ax
    ret

;--------------------------------------------------------------------------------
; 计算下一个簇在FAT表中的项数，如果值大于或等于0xFF8,则表示当前FAT项对应的簇是最后一个簇。如果
; 值为0xFF7表示这是一个坏簇，读取时应该不会遇到这种情况，只对写入数据时有用，除非磁盘发生的错误。
; 所以将0xFF7及其以上的都认为是最后一簇。
; ax : 上一个FAT号
; bx : FAT表的内存地址
nextFatItem:
    shr     bx, 4                       ; |使用es作为FAT表起始地址。
    mov     es, bx                      ; /
    mov     bx, 3                       ; |计算FAT的起始字节地址，由于一个FAT项占12位,导致
    mul     bx                          ; |奇数FAT的在两字节的左侧和偶数FAT在两字节的右侧
    mov     bx, 2                       ; |
    div     bx                          ; /
    mov     si, ax                      ; |取FAT值
    mov     ax, [es:si]                 ; / 
    cmp     dx, 0                       ; |如果是偶数的话就不用右移
    jz      .logicOperation             ; /
    shr     ax, 4                       ; 
.logicOperation:                        ;
    and     ax, 0x0FFF                  ; 清零高四位无用的数值
    ret 
    
times 510-( $-$$ ) db 0                 ; 有org时，$$是程序开始的实际地址，$是本指令的实际地址。
    dw      0xaa55                      ; DB      0x55, 0xaa      另一种写法，明显这是大字端机器