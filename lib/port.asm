; read and write port
; Create date : 2017/3/26
; Update date : 2017/3/26
; Create by: 郭耀文
; 
global writePort
global readPort
global disableIRQ
global enableIRQ
global disableInte
global enableInte
global seePort

INTE_MASTER_EVEN    equ 0x20 ; Master chip even control port
INTE_MASTER_ADD     equ 0x21
INTE_SLAVE_ADD      equ 0xA1
[section text]
;-------------------------------------------------------------------------
; 写入端口
; void writePort( u16 port, u8 value );
;
writePort:
    mov     edx, [esp + 4]      ; port
    mov     al, [esp + 8]       ; values
    out     dx, al
    nop                         ; 一点延迟
    nop
    ret

;--------------------------------------------------------------------------
; u8 readPort( u16 port );
;
readPort:
    mov     edx, [esp + 4]      ; port
    xor     eax, eax
    in      al, dx
    nop                         ; 一点延迟
    nop
    ret

; -----------------------------------------------------------------------
; void disable_IRQ(int IRQ);
;
; Disable an interrupt request line by setting an 8259 bit.
; Equivalent code:
;   if(IRQ < 8)
;       out_byte(INTE_MASTER_ADD, in_byte(INTE_MASTER_ADD) | (1 << IRQ));
;   else
;       out_byte(INTE_SLAVE_ADD, in_byte(INTE_SLAVE_ADD) | (1 << IRQ));
disableIRQ:
        mov     ecx, [esp + 4]          ; IRQ
        pushf
        cli
        mov     ah, 1
        rol     ah, cl                  ; ah = (1 << (IRQ % 8))
        cmp     cl, 8
        jae     .slave                  ; disable IRQ >= 8 at the slave 8259
.master:
        in      al, INTE_MASTER_ADD
        test    al, ah
        jnz     .disableOk              ; already disabled?
        or      al, ah
        out     INTE_MASTER_ADD, al     ; set bit at master 8259
        popf
        mov     eax, 1                  ; disabled by this function
        ret
.slave:
        in      al, INTE_SLAVE_ADD
        test    al, ah
        jnz     .disableOk              ; already disabled?
        or      al, ah
        out     INTE_SLAVE_ADD, al      ; set bit at slave 8259
        popf
        mov     eax, 1                  ; disabled by this function
        ret
.disableOk:
        popf
        xor     eax, eax                ; already disabled
        ret

; -----------------------------------------------------------------------
; void enableIRQ(int IRQ);
;
; Enable an interrupt request line by clearing an 8259 bit.
; Equivalent code:
;       if(IRQ < 8)
;               out_byte(INTE_MASTER_ADD, in_byte(INTE_MASTER_ADD) & ~(1 << IRQ));
;       else
;               out_byte(INTE_SLAVE_ADD, in_byte(INTE_SLAVE_ADD) & ~(1 << IRQ));
;
enableIRQ:
        mov     ecx, [esp + 4]          ; IRQ
        pushf
        cli
        mov     ah, ~1
        rol     ah, cl                  ; ah = ~(1 << (IRQ % 8))
        cmp     cl, 8
        jae     .slave                  ; enable IRQ >= 8 at the slave 8259
.master:
        in      al, INTE_MASTER_ADD
        and     al, ah
        out     INTE_MASTER_ADD, al       ; clear bit at master 8259
        popf
        ret
.slave:
        in      al, INTE_SLAVE_ADD
        and     al, ah
        out     INTE_SLAVE_ADD, al       ; clear bit at slave 8259
        popf
        ret


disableInte:
    cli
    ret

enableInte:
    sti
    ret


;-----------------
; seePort(port);
; 
seePort:
    push    ebp
    mov     ebp, esp
    push    edx
    mov     bx, [esp + 8]
    xor     eax, eax
    in      al, dx
    pop     edx
    pop     ebp
    ret