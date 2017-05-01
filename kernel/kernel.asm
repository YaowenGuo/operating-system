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
; 声明外部变量
extern gdt_ptr
extern idt_ptr
extern pcb_proc_ready
extern tss
extern kernel_stack_top
extern schedule_reenter

; 声明外部函数
extern test
extern repositionGdt
extern initIDT
extern exceptionHandler
extern divideZero
extern printIRQ
extern init8259A
extern creatProcess
extern initTSS
extern taskSchedule
extern irqHandler
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
global wakeupProc
global testVideo


PCB_STACKBASE       equ 0
PCB_GSREG           equ PCB_STACKBASE
PCB_FSREG           equ PCB_GSREG           + 4
PCB_ESREG           equ PCB_FSREG           + 4
PCB_DSREG           equ PCB_ESREG           + 4
PCB_EDIREG          equ PCB_DSREG           + 4
PCB_ESIREG          equ PCB_EDIREG          + 4
PCB_EBPREG          equ PCB_ESIREG          + 4
PCB_KERNELESPREG    equ PCB_EBPREG          + 4
PCB_EBXREG          equ PCB_KERNELESPREG    + 4
PCB_EDXREG          equ PCB_EBXREG          + 4
PCB_ECXREG          equ PCB_EDXREG          + 4
PCB_EAXREG          equ PCB_ECXREG          + 4
PCB_EIPREG          equ PCB_EAXREG          + 4
PCB_CSREG           equ PCB_EIPREG          + 4
PCB_EFLAGSREG       equ PCB_CSREG           + 4
PCB_ESPREG          equ PCB_EFLAGSREG       + 4
PCB_SSREG           equ PCB_ESPREG          + 4
PCB_STACK_BUTTOM    equ PCB_SSREG           + 4
PCB_LDT_SELE_OFFSET equ PCB_STACK_BUTTOM
PCB_LDT             equ PCB_LDT_SELE_OFFSET + 4

TSS_ESP0            equ 4
TSS_SS0             equ 8
; 必须与protect.h中的保持一致
SELECTOR_TSS        equ 0x20 ; TSS

INTE_MASTER_EVEN    equ 0x20 ; Master chip even control port
INTE_MASTER_ADD     equ 0x21
EOI                 equ 0x20

[section .bss]
stack_space: resb 2 * 1024
stack_bottom:


[section .text]                 ; code segment



_start:   ; When ececute this, we asume gs had point to video memory
    ; 将堆栈切换到内核空间
    mov     esp, stack_bottom

    ; 将描述符复制到内核空间，并使用内核空间的描述符
    sgdt    [gdt_ptr]           ; 复制时需要知道原描述符的地址，和长度
    call    repositionGdt       ; 将gdt_ptr指向的描述符复制到内核空间，并将新地址保存到gdt_ptr,
                                ; 将idt_ptr指向idt
    lgdt    [gdt_ptr]           ; 加载新的gdt地址和长度

    call    initIDT             ; 初始化idt,并将idt描述符放到idt_prt
    lidt    [idt_ptr]           ; 初始化指向中断向量表的寄存器

    call    init8259A           ; 初始化外部中断管理器8259A

    call    initTSS             ; 初始化TSS
    xor     eax, eax
    mov     ax, SELECTOR_TSS
    ltr     ax                  ; 设置指向TSS的指针

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

    ;hlt
    call    creatProcess

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

;--------------------------------------
; 用于保存计算器
;
%macro saveRegsters 0
    pushad
    push    ds
    push    es
    push    fs
    push    gs
    ; 内核的堆栈段、数据段、附加段原先都是使用的同一个描述符
    mov     ax, ss
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
%endmacro

; 硬件中断
; ---------------------------------
%macro  hwInte  1
    saveRegsters        ; 首先要做的就是保存进程运行的状态，即寄存器信息

    ; 如果是上一次调度没有处理完，就进入进入了调度，则直接返回，不用再进行调度。
    ; ?为什么不能放到最前面，入栈之前？
    inc     dword [schedule_reenter]
    jnz     .end        ; 不是0，则上次的调度任务没有完成就再次发生了时钟中断，直接结束

    ; 此时esp指向的是PCB中保存寄存器的数据结构的顶部，如果进行任何的进栈出栈就很核能会坏PCB
    ; 中保存的进程运行状态数据，所以接下来应该将esp指向内核自己的栈顶。
    ; 如果是重入，已经在内核栈中，不用再切换，所以放在判断重入之后。同时，希望重入时的跳转
    ; 入栈是在内核栈上的，所以要在开中断之前切换。
    mov     esp, [kernel_stack_top]

    in      al, INTE_MASTER_ADD ;'.
    or      al, 1               ; | 屏蔽时钟中断
    out     INTE_MASTER_ADD, al ; /
    ; 让中断可以继续发生。要放在任务处理之前，以便在任务处理过程中也能接受键盘等需要立刻响应的中断
    mov     al, EOI
    out     INTE_MASTER_EVEN, al

    ; 在CPU响应中断时会自动关闭中断。在进程调度中，希望响应键盘等立即需要响应的中断，这里打中断
    sti ;为什么不开中断时，一直在打印*,而无法打印A?
    push    %1
    call    [irqHandler + 4 * %1]
    pop     ecx
    ; 切换到进程是一个整体操作，如果被打断会引起数据错乱。所以把中断关掉。
    cli 

    in      al, INTE_MASTER_ADD ;'.
    and     al, 0xFE            ; | 打开时钟中断
    out     INTE_MASTER_ADD, al ; /

    push    wakeupProc          ;'.
    jmp     .end                ; | 之所以这样写是为了和C语言中使用统一的返回函数wakeupProc
    push    endReenter          ; | 的结果，C语言只能调用汇编的函数而无法调用宏。然而在这里调用
.end:                           ; | 函数时，由于wakeupProc不会将调用时的压栈弹出，而造成堆栈不
    ret                         ; / 平衡，所以使用了push和ret的技巧，返回到wakeupProc执行。
%endmacro

inteClick:                      ; 任务调度程序
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

wakeupProc:
    mov     [kernel_stack_top], esp
    mov     esp, [pcb_proc_ready]           ; 获得要启动的进程的pcb首地址
    lea     eax, [esp + PCB_STACK_BUTTOM]   ; 获得PCB中进程切换时用于保存寄存器入栈的地址
    mov     [tss + TSS_ESP0], eax
    lldt    [esp + PCB_LDT_SELE_OFFSET]     ; 加载pcb中保存的ldt描述符的选择子
endReenter: ; 结束重入，由于需要在外部访问，不能再使用内部标号
    dec     dword [schedule_reenter]
    pop     gs
    pop     fs
    pop     es
    pop     ds
    popad
    iretd
