;hello-os
    CYLS    EQU     10      ; 指定10个柱面
    ORG     0x7c00          ; （origin）汇编器。如果没有它，有几个指令就不能
                            ; 被正确的翻译和执行。有了这条指令,$符的含义发生变化，它不再是指输出我耳机那的地几个字节，
                            ; 而是代表要读入的内存地址
                            ; 以下这段是标准FAT12格式软盘专用的代码
    JMP     entry           ; 跳转到程序区去执行程序
    DB      0x90            ; ?
    DB      "HELLOIPL"      ; 启动区的名称可以是任意8字节的字符串，不够填‘\0’
    DW      512             ; 每个扇区（sector）的大小（软盘必须为512字节）
    DB      1               ; 簇（cluster）的大小（必须为一个扇区）
    DW      1               ; FAT的起始位置（一般从第一个扇区开始）
    DB      2               ; FAT的个数（必须为2）
    DW      224             ; 根目录的大小（一般设为224项）
    DW      2880            ; 该磁盘的扇区数（软盘大小（bit）/扇区大小）其实扇区数是生产是固定的，不是计算的。真正计算的是扇区数*扇区大小-》磁盘容量
    DB      0xf0            ; 磁盘的种类（软盘为0Xf0）
    DW      9               ; FAT的长度（必须是9扇区）
    DW      18              ; 1个磁道（track）有几个扇区（必须是18）
    DW      2               ; 磁头数（必须是2）
    DD      0               ; 不使用分区，必须是0
    DD      2880            ; 重写一次磁盘大小
    DB      0,0,0x29        ; 意义不明确，固定
    DD      0xffffffff      ; （可能是）卷标号码
    DB      "HELLO-OS   "   ; 磁盘的名称（11字节）
    DB      "FAT12   "      ; 磁盘格式名称（8字节）
    times   18  db    0     ; 先空出18字节


entry:
    MOV     AX,0            ; 初始化寄存器
    MOV     SS,AX
    MOV     SP,0x7c00       ; 使用了0c7c00之前的空闲区作堆栈
    MOV     DS,AX


; 读取下一个扇区数据进内存
; 0x7e00~0x9fbff内存空闲，可以随意使用。
    MOV     AX,0x7e0
    MOV     ES,AX


    MOV     DL,0x00         ; A驱动器，有多个软件驱动器的时候，用于制定哪个驱动器
    MOV     DH,0            ; 磁头0
    MOV     CX,2            ; 磁道0，扇区2
    
readloop:
    MOV     SI,0            ; 记录失败次数，软盘有时会发生不能读取数据的情况，此时并不是
                            ; 坏掉了，而是不稳定，应该多读几次，这设置最多读5次
retry:
    MOV     AH,0x02         ; AH=0x02 ： 读盘。如果读取失败会在AH：AL中设置返回，所以每次要重新设置
    MOV     AL,1            ; 1个扇区
    MOV     BX,0
    INT     0x13            ; 调用BIOS的磁盘功能
    JNC     next
    ADD     SI, 1
    CMP     SI, 5
    JAE     error
    MOV     AH, 0           ; 如果出错了，且小于5次，重置驱动器，再读一次
    INT     0X13
    JMP     retry
next:
    MOV     AX, ES
    ADD     AX, 0X20        ; 不能直接在BX上加，因为180K超出了BX的范围
    MOV     ES, AX          ; 讲ES:BX的指向后移512字节
    INC     CL
    CMP     CL, 18          ; 读完18扇区结束
    JBE     readloop        ; 
    MOV     CL, 1
    INC     DH
    CMP     DH, 2
    JB      readloop
    MOV     DH, 0
    INC     CH
    CMP     CH, CYLS
    JB      readloop

; 跳到操作系统处执行，将控制权交给操作系统
    mov     [0x0ff0],ch     ; 将磁盘装载内容的结束位置保存在内存0x0ff0的地方，即CYLS的值
    jmp     0xc200          ; 计算出的操作系统加载到内存的起始地址

error:
    mov     si,msg

putloop:
    MOV     AL,[SI]
    ADD     SI,1            ; 给SI加1
    CMP     AL,0
    JE      fin
    MOV     AH,0x0e         ; 显示一个文字
    MOV     BX,15           ; 指定文字颜色
    INT     0x10            ; 调用显卡BIOS
    JMP     putloop
fin:
    HLT                     ; 暂停执行
    JMP     fin             ; 循环

msg:
    DB      0x0a, 0x0a      ; 换行两次
    DB      "load error"
    DB      0x0a            ; 换行
    DB      0               ; 作为字符输出的结尾

    ;RESB   0x7dfe - $      ; 填写0，直到0x1fe
times 510-( $-$$ ) db 0
    DB      0x55, 0xaa      ; 设置启动区标记


; 10×2 × 18 × 512 = 184 320byte = 180 KB