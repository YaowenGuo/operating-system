;hello-os

    ORG		0x7c00          ; （origin）汇编器。如果没有它，有几个指令就不能
    ;被正确的翻译和执行。有了这条指令,$符的含义发生变化，它不再是指输出我耳机那的地几个字节，
    ;而是代表要读入的内存地址
;以下这段是标准FAT12格式软盘专用的代码
    JMP		entry           ; 跳转到程序区去执行程序
	DB		0x90            ; ?
	DB		"HELLOIPL"		; 启动区的名称可以是任意8字节的字符串，不够填‘\0’
	DW		512				; 每个扇区（sector）的大小（软盘必须为512字节）
	DB		1				; 簇（cluster）的大小（必须为一个扇区）
	DW		1				; FAT的起始位置（一般从第一个扇区开始）
	DB		2				; FAT的个数（必须为2）
	DW		224				; 根目录的大小（一般设为224项）
	DW		2880			; 该磁盘的扇区数（软盘大小（bit）/扇区大小）其实扇区数是生产是固定的，不是计算的。真正计算的是扇区数*扇区大小-》磁盘容量
	DB		0xf0			; 磁盘的种类（软盘为0Xf0）
	DW		9				; FAT的长度（必须是9扇区）
	DW		18				; 1个磁道（track）有几个扇区（必须是18）
	DW		2				; 磁头数（必须是2）
	DD		0				; 不使用分区，必须是0
	DD		2880			; 重写一次磁盘大小
	DB		0,0,0x29		; 意义不明确，固定
	DD		0xffffffff		; （可能是）卷标号码
	DB		"HELLO-OS   "	; 磁盘的名称（11字节）
	DB		"FAT12   "		; 磁盘格式名称（8字节）
	times 	18	db    0        ; 先空出18字节


entry:
	MOV		AX,0			; 初始化寄存器
	MOV		SS,AX
	MOV		SP,0x7c00
	MOV		DS,AX
	MOV		ES,AX
	MOV		SI,msg
putloop:
	MOV		AL,[SI]
	ADD		SI,1			; 给SI加1
	CMP		AL,0
	JE		fin
	MOV		AH,0x0e			; 显示一个文字
	MOV		BX,15			; 指定文字颜色
	INT		0x10			; 调用显卡BIOS
	JMP		putloop
fin:
	HLT						; （halt停止）让CPU进入等待状态。只要外部发生变化，如按下键盘或移动鼠标，cpu就会醒来
    ;加入SHL后CPU就不会毫无意义的空转，非常省电。作为一个初学者更应该样成良好的习惯。
	JMP		fin				; 无限循环

msg:
	DB		0x0a, 0x0a		; 换行两次
	DB		"hello, world"
	DB		0x0a			; 换行
	DB		0

	;RESB	0x7dfe - $		; 填写0，直到0x1fe
	times 512-( $-$$ ) db 0
	DB		0x55, 0xaa      ; 设置启动区标记

; 以下是启动区以外部分的输出

	DB		0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
	times 	4600  db 0
	DB		0xf0, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00
	times 	1469432  db  0
