; Exetutable name           : ipl.bin
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
    org 0x7c00              ; 告诉编译器程序将被加载到0x7c00处，编译器据此计算地址

    JMP     entry           ; 跳转到程序区去执行程序
    DB      0               ; 占位，也可以使用nop指令，只要保证下一项从3字节开始即可。
    DB      "Producer"      ; 生产厂商可以是任意8字节的字符串，不够填‘\0’
    DW      512             ; 每个扇区（sector）的字节数
    DB      1               ; 簇（cluster）的大小（FAT12必须为一个扇区）
    DW      1               ; FAT的起始位置（一般从第一个扇区开始）
    DB      2               ; FAT的个数（FAT12为2）
    DW      224             ; 根目录的大小（一般设为224项）
    DW      2880            ; 该磁盘的总扇区数
    DB      0xf0            ; 磁盘的种类（软盘为0Xf0）
    DW      9               ; FAT的长度（FAT12是9扇区）
    DW      18              ; 1个磁道（track）有几个扇区（软盘一般是18）
    DW      2               ; 磁头数（软盘是2）
    DD      0               ; 不使用分区，必须是0
    DD      2880            ; 重写一次扇区数
    DB      0,0,0x29        ; 意义不明确，固定
    DD      0               ; 卷序列号
    DB      "My own OS! "   ; 磁盘的名称（11字节）
    DB      "FAT12   "      ; 磁盘格式名称（8字节）

entry:                             
;这里编写代码


times 510-( $-$$ ) db 0     ; 有org时，$$是程序开始的实际地址，$是本指令的实际地址。
    dw 0xaa55               ; DB      0x55, 0xaa      另一种写法，明显这是大字端机器

