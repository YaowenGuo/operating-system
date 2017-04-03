; File name: kernel.asm
; Create date: 2017/3/2
; Author: guobool
; 
; Complate:
; 32 bits platforms
;   nasm -f elf kernel.asm -o kernel.o
;   ld -s kernel.o -o kernel.bin
; 64 bits platforms
;   nasm -f elf kernel.asm -o kernel.o
;   ld -m elf_i386 kernel.o -o kernel.bin

[section .data]
align 32  ; ?
[bits 32] 
; SELECTOR_KERNEL_CS  equ 8   ; 代码段的选择子：偏移和权限
extern test
extern gdt_ptr
extern idt_ptr
extern replaecGdt
extern initIDT
extern exceptionHandler
extern divideZero
extern printIRQ
extern init8259A


global _start                   ; export _start

; 中断程序跳转点
global divideError
global debugException
global nmi
global debugInterrupt
global overflow
global boundsCheck
global invalOpCode
global coprNotAvailable
global doubleFault
global coprSegOverrun
global invalTss
global segmentNotPresent
global stackException
global generalProtection
global pageFault
global floatError

; 外部中断
global inteClick
global inteKeyboard
global inteSlaveChip
global inteSerialPort2
global inteSerialPort1
global inteLPT2
global inteFloppyDisk
global inteLPT1
global inteRealtimeClick
global inteRedirect
global inteRetain1
global inteRetain2
global inteMouse
global inteFPUException
global inteATTemperaturePlate
global inteRetain3

[section .bss]
stack_space: resb 2 * 1024
stack_bottom:


[section .text]                 ; code segment



_start:   ; When ececute this, we asume gs had point to video memory
    ; 将堆栈切换到内核空间
    mov     esp, stack_bottom

    ; 将描述符复制到内核空间，并使用内核空间的描述符
    sgdt    [gdt_ptr]           ; 复制时需要知道原描述符的地址，和长度
    call    replaecGdt          ; 将gdt_ptr指向的描述符复制到内核空间，并将新地址保存到gdt_ptr,
                                ; 将idt_ptr指向idt
    lgdt    [gdt_ptr]           ; 加载新的gdt地址和长度

    call    initIDT             ; 初始化idt,并将idt描述符放到idt_prt
    lidt    [idt_ptr]           ; 初始化指向中断向量表的寄存器

    call    init8259A           ; 初始化外部中断管理器8259A
    sti                         ; 打开中断允许位

    ;jmp    SELECTOR_KERNEL_C:initStack ; 资料上说，这个跳转将强制使用刚刚初始化的描述符，我感觉根本
                                        ; 不用使用该指令，因为原本的描述符就是一个偏移和权限（也是8）
                                        ; 即指向描述符1，而initStack标号就是下一条指令的地址，该指令
                                        ; 执行时，eip自动增加，就是下一条指令的地址


initStack:
    ; push  0
    ; popfd                     ; 赋值EFLAGS，但不影响VM，RF，IOPL，VIF和VIP的值
    call    test                ; 调用测试函数，打印字符串。证明程序执行到此。

    ; ud2　                       ; 引发中断的操作码,我在编译时根本不识别该指令，只有使用下一条来产生错误了
    ; jmp 0x40:0                  ; 调试外部中断时，需要将此注释，不然运行到此已经发生了异常。跳入了异常处理函数内

    hlt

; 为什么这里使用如此多的标号，而不是直接使用Ｃ语言的调用？难道仅仅给出一个一个
; 指针地址的Ｃ函数不会被编译进结果？还有一点不明白的就是：通过int指令可以调用中断
; 软件中断的需要通过iret返回源中断触发点，而外部中断和错误回到原处根本没有意义。
; 如果这int触发的正是外部中断和错误中断，中断如何区分两者？并按照正确的方式处理？
; 如int中断需要iret返回远原点，而错误需要处理后返回到特定的位置。
; 异常
divideError:
    push    0xFFFFFFFF          ; no err code
    push    0                   ; vector_no = 0
    jmp exception
debugException:
    push    0xFFFFFFFF          ; no err code
    push    1                   ; vector_no = 1
    jmp exception
nmi:
    push    0xFFFFFFFF          ; no err code
    push    2                   ; vector_no = 2
    jmp exception
debugInterrupt:
    push    0xFFFFFFFF          ; no err code
    push    3                   ; vector_no = 3
    jmp exception
overflow:
    push    0xFFFFFFFF          ; no err code
    push    4                   ; vector_no = 4
    jmp exception
boundsCheck:
    push    0xFFFFFFFF          ; no err code
    push    5                   ; vector_no = 5
    jmp exception
invalOpCode:
    push    0xFFFFFFFF          ; no err code
    push    6                   ; vector_no = 6
    jmp exception
coprNotAvailable:
    push    0xFFFFFFFF          ; no err code
    push    7                   ; vector_no = 7
    jmp exception
doubleFault:
    push    8                   ; vector_no = 8
    jmp exception
coprSegOverrun:
    push    0xFFFFFFFF          ; no err code
    push    9                   ; vector_no = 9
    jmp exception
invalTss:
    push    10                  ; vector_no = A
    jmp exception
segmentNotPresent:
    push    11                  ; vector_no = B
    jmp exception
stackException:
    push    12                  ; vector_no = C
    jmp exception
generalProtection:
    push    13                  ; vector_no = D
    jmp exception
pageFault:
    push    14                  ; vector_no = E
    jmp exception
floatError:
    push    0xFFFFFFFF          ; no err code
    push    16                  ; vector_no = 10h
    jmp exception

exception:
    call    exceptionHandler
    add esp, 4 * 2              ; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
    hlt

; 硬件中断
; ---------------------------------
%macro  hwInte  1
        push    %1
        call    printIRQ
        add     esp, 4
        hlt
%endmacro

inteClick:                      ; 
    hwInte  0
inteKeyboard:
    hwInte  1
inteSlaveChip:
    hwInte  2
inteSerialPort2:
    hwInte  3
inteSerialPort1:
    hwInte  4
inteLPT2:
    hwInte  5
inteFloppyDisk:
    hwInte  6
inteLPT1:
    hwInte  7
inteRealtimeClick:
    hwInte  8
inteRedirect:
    hwInte  9
inteRetain1:
    hwInte  10
inteRetain2:
    hwInte  11
inteMouse:
    hwInte  12
inteFPUException:
    hwInte  13
inteATTemperaturePlate:
    hwInte  14
inteRetain3:
    hwInte  15

