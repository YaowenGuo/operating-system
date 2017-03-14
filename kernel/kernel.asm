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

[section .text] 			; code segment

global _start 				; export _start

_start:   ; When ececute this, we asume gs had point to video memory
	mov 	ah, 0xF
	mov 	al, 'K'
	mov 	[gs:(( 80*9 + 0 ) * 2)], ax
	jmp 	$
