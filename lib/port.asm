; read and write port
; Create date : 2017/3/26
; Update date : 2017/3/26
; Create by: 郭耀文
; 

;-------------------------------------------------------------------------
; 写入端口
; void writePort( u16 port, u8 value );
;
writePort:
	mov 	edx, [esp + 4] 		; port
	mov 	la, [esp + 8]		; values
	out 	dx, al
	nop 						; 一点延迟
	nop
	ret

;--------------------------------------------------------------------------
; u8 readPort( u16 port );
;
readPort:
	mov 	edx, [esp + 4]		; port
	xor 	eax, eax
	in 		al, dx
	nop 						; 一点延迟
	nop
	ret
	