; File name: kernel.asm
; Create date: 2017/3/2
; Author: guobool
; 
; Complate:
; 32 bits platforms
; 	nasm -f elf kernel.asm -o kernel.o
; 	ld -s kernel.o -o kernel.bin
; 64 bits platforms
; 	nasm -f elf kernel.asm -o kernel.o
; 	ld -m elf_i386 kernel.o -o kernel.bin

[section .data]
SELECTOR_KERNEL_C 	EQU 8  	; 代码段的选择子：偏移和权限
extern replaceGdt
extern test
extern gdt_ptr


[section .bss]
stack_space: resb 2 * 1024
stack_bottom:


[section .text] 			; code segment

global _start 				; export _start

_start:   ; When ececute this, we asume gs had point to video memory
	; 将堆栈切换到内核空间
	mov 	esp, stack_bottom

	; 将描述符复制到内核空间，并使用内核空间的描述符
	sgdt 	[gdt_ptr] 			; 复制时需要知道原描述符的地址，和长度
	call 	replaceGdt 			; 将gdt_ptr指向的描述符复制到内核空间，并将新地址保存到gdt_ptr
	lgdt 	[gdt_ptr] 			; 加载新的gdt地址和长度

	;jmp 	SELECTOR_KERNEL_C:initStack ; 资料上说，这个跳转将强制使用刚刚初始化的描述符，我感觉根本
										; 不用使用该指令，因为原本的描述符就是一个偏移和权限（也是8）
										; 即指向描述符1，而initStack标号就是下一条指令的地址，该指令
										; 执行时，eip自动增加，就是下一条指令的地址
initStack:
	push 	0
	popfd 						; 赋值EFLAGS，但不影响VM，RF，IOPL，VIF和VIP的值
	call 	test
	hlt

	