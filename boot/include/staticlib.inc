; 这里对标签命名进行规范
; 数据定义：
; 数据定义申请空间使用全小写，以下划线连接，如　save_number db 0
; 常数使用全大写，中间使用下划线连接。如：ROOTDIR_START_SECTOR    equ 19
; 字符串使用首字母大写，使用下划线连接。如：Not_Find_File      DB  "NOT FIND FILE\n"
; 标号：
; 过程和宏使用单词相连，第一个单词首字母小写，其他单词首字母大写。如　printStr
; 标签使用首字母大写的单词相连，如 .notAdd
;
; !这里需要注意，如果标记的词本身是几个单词缩写成的，即只使用了每个单词的首字母，则使用大写，如 GDT


    SECTORS_OF_CLUSTER      equ 1       ; 每个簇的扇区数，整个FAT格式区，只有这个用得到，多以定义成常量
    ; 代码的内存布局
    FAT_ADDRESS             equ 0x500   ; FAT表的加载地址
    DIRECTORY_ADDRESS       equ 0x1700  ; 根目录的加载地址
    LOADER_ADDRESS          equ 0x90000
    KERNEL_FILE_ADDRESS     equ 0x80000
    PAGE_DIR_ADDRESS        equ 0x100000
    PAGE_TABLE_ADDRESS      equ 0x101000
    KERNEL_ENTRY_PHYADDR    equ 0x30400

    ; 扇区信息，这些全是根据引导扇区中FAT文件的配置计算出来的，使用代码计算也可以，但很繁琐，况且
    ; 引导扇区没有这么大空间放这些代码，这里预先计算出结果直接使用

    FAT_SECTOR_NUM          equ 9       ; 单个FAT表大小           
    ROOTDIR_SECTOR_NUM      equ 14      ; 根目录扇区数 

    FAT_START_SECTORS       equ 1       ; FAT表的起扇区          
    ROOTDIR_START_SECTOR    equ 19      ; 根目录的起始扇区
    DATA_START_SECOTRS      equ 33      ; 数据区的起始扇区

    Not_Find_File           DB  "NOT FIND FILE\n"
    NOT_FIND_STRLEN         equ $-Not_Find_File

    Read_Sector_error       db  "Load Disk Error!\n"
    READ_SECTOR_STRLEN     equ $ - Read_Sector_error

;-----------------------------------------------------------
; 找到文件的入口
; 传递目录的开始扇区和扇区总数，以及文件名，查看此连续扇区上是否有该文件，
; 返回文件的起始簇号,不存在返回０
; es : 缓冲区地址
; ax : 扇区数
; si : 查找的文件名首地址，ds:si指向



fileFirstFat:
    mov     cl, ITEN_ONE_SECTOR     ; |计算出11个扇区的根目录总共有多少条目录项
    mul     cl                      ; /
    mov     [loder_name_offset], si ; 保护字符串的偏移
.nextItem:
    cmp     ax, 0                   ; |目录项小于等于０，没有找到，就结束
    jz      .notFind                ; /
    mov     si, [loder_name_offset] ; 取出保存的值
    xor     di, di                  ; es:di指向目标，
    mov     cx, FILE_NEME_LEN       ; |cx是字符串的长度
    cld
    repe    cmpsb                   ; /cx==0或者两字符不等时结束，注意，比较时si和di是跟着增长的
    jz      .find                   ; 如果结束时0标志位为０则说明找到

    dec     ax                      ; 条目数减一
    mov     bx, es                  ; |es:di增加32，然后调到下一次比较
    add     bx, 32>>4               ; |
    mov     es, bx                  ; |
    jmp     .nextItem               ; /

.find:
    mov     di, 26                  ; |找到之后将目录项的FAT项号取出
    mov     ax, [es:di]             ; |
    jmp     .end                    ; /
.notFind:
    mov     ax, -1                  ; 没找到返回－１
.end:
    ret
    loder_name_offset dw 0
    ITEN_ONE_SECTOR equ 16          ; 每个扇区512字节，每个目录项32字节，512/32
    FILE_NEME_LEN   equ 11          ; FAT12文件名固定为１１字节


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
    TRACK_SECTOR   equ 18           ; 软盘的每个磁道18个扇区
    MAGHEAD_NUM    equ 2            ; 软盘有两个磁头

    mov     cl, TRACK_SECTOR
    div     cl                      ;　ah-余数z，al商y
    inc     ah                      ; 扇区号从１开始，所以加一
    push    ax                      ; 保存扇区号
    xor     ah, ah                  ; 清空ah,　使用al的值／磁头数，来计算磁头号和磁道号
    mov     cl, MAGHEAD_NUM         ; 获取磁头数，因为有些磁盘不止两个磁头
    div     cl                      ; 除后，ah-磁头号，al-磁道号
    mov     dh, ah                  ; 磁头号放到dh    
    mov     ch, al                  ; 磁道号（柱面号）放到ch
    pop     ax                      ; | 扇区号放到cl
    mov     cl, ah                  ; /
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
    push    ax                      ; 用于传递扇区序号和返回值，所以要保存
    push    bx
    mov     bx, 0 
    push    cx                      ; 被numToLocation用户返回磁道号和扇区号
    push    dx                      ; dh被numToLocation返回磁头号，和驱动器号
NextSector:
    mov     ax, si                  ; 将扇区序号放到ａｘ中用于计算
    numToLocation                   ; 将扇区序号转化为物理位置（磁道，磁头，扇区）
    call    readOneSector           ; 读取一个扇区
    jc      .fin                    ; 出错就返回，readOneSecotr的返回值作为本函数的返回值
    dec     di                      ; |
    cmp     di, 0                   ; |判断扇区个数是否满足结束条件
    jz      .fin                    ; /
    inc     si                      ; 扇区序号加１
    mov     ax, es                  ; |
    add     ax, 20h                 ; |es:bx的地址加５１２字节
    mov     es, ax                  ; /
    jmp     NextSector              ; 读取下一个扇区
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
    DISKERRORTIME  equ 5            ; 磁盘发生错误的最大读取次数
    push    bp                      ; |
    mov     bp, sp                  ; | 保存寄存器
    push    si                      ; /
    mov     si, DISKERRORTIME       ; 设置最大出错读取次数
.retry:
    mov     ah, 2                   ; |
    mov     al, 1                   ; | 读取一个扇区，因为出错是ax返回值，所以每次都要设置
    int     0x13                    ; /
    jnc     .fin                    ; 没出错直接结束
    dec     si                      ; 出错剩余次数减１
    jz      .fin                    ; 剩余０次后也跳转到结束
    mov     ah, 0                   ; | 
    mov     dl, 0                   ; | 磁盘复位后再读一次
    int     0x13                    ; |
    jmp     .retry                  ; /
.fin:
    pop     si                      ; | 恢复寄存器
    mov     sp, bp                  ; |
    pop     bp                      ; /
    ret

;----------------------------------------------------------------
; 输出字符串
; ES:BP   :字符串首地址
; 
printStr:                           ; 这里有一个陷阱，不能再将sp赋值给bp了，因为bp存了字符串地址
    push    ax
    push    bx
    push    dx

    mov     ax, 1300h               ; AH = 13,显示字符串,  AL = 0h 写方式
    mov     bx, 0007h               ; 页号为0(BH = 0) 黑底白字(BL = 07h)
    mov     dx, 0                   ; dh-0行,dl-0列
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
    shr     bx, 4                   ; |使用es作为FAT表起始地址。
    mov     es, bx                  ; /
    mov     bx, 3                   ; |计算FAT的起始字节地址，由于一个FAT项占12位,导致
    mul     bx                      ; |奇数FAT的在两字节的左侧和偶数FAT在两字节的右侧
    mov     bx, 2                   ; |
    div     bx                      ; /
    mov     si, ax                  ; |取FAT值
    mov     ax, [es:si]             ; / 
    cmp     dx, 0                   ; |如果是偶数的话就不用右移
    jz      .logicOperation         ; /
    shr     ax, 4                   ; 
.logicOperation:                    ;
    and     ax, 0x0FFF              ; 清零高四位无用的数值
    ret 