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