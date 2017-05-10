SUBDIRS = devices
# Kernel Entry Point
# It is same as "KERNEL_ENTRY_PHYADDR" in staticlib.inc
ENTRY_POINT = 0x30400

# offset of entry point in kernel file
# It depends on ENTRY_POINT
ENTRY_OFFSET = 0x400

vpath %.c kernel lib
vpath %.asm kernel lib
vpath %.h include
vpath %.o lib kernel devices/driver
ASM = nasm
ASMFLAGS = -I boot/include/
ASM_KERNEL_FLAGS = -I include/ -f elf -g
LD = ld
# 在64位机上编译目标文件为32位代码，需使用 -m elf_i386参数
LD_FLAGS = -m elf_i386  -Ttext $(ENTRY_POINT)  #调试时去掉-s参数
CC := gcc
# 在64位机上编译32位目标文件，需要使用-m32参数
C_FLAGS := -c  -fno-builtin -m32 -g -I include

# devices 


# Target program
OS_BOOT = boot/boot.bin boot/loader.bin
OS_KERNEL = kernel/kernel.bin
OBJS = kernel.o main.o global.o protect.o string.o lib.o process.o systemcall.o \
       clock.o i8259A.o console.o keyboard.o port.o tty.o


TARGET = $(OS_BOOT) $(OS_KERNEL)


.PHONY : all clean install 

all : $(TARGET)

clean :
	rm -f $(TARGET) $(OBJS)

# a.img must exist in current floder
install : 
	dd if=boot/boot.bin of=a.img bs=512 count=1 conv=notrunc
	sudo mount -o loop a.img /mnt/floppy
	sudo cp -fv boot/loader.bin /mnt/floppy
	sudo cp -fv kernel/kernel.bin /mnt/floppy
	sudo umount /mnt/floppy

boot/boot.bin : boot/boot.asm  boot/include/staticlib.inc
	$(ASM) $(ASMFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/staticlib.inc lib/string.asm
	$(ASM) $(ASMFLAGS) -o $@ $<


$(OS_KERNEL) : $(OBJS)
	$(LD) $(LD_FLAGS) -o $(OS_KERNEL) $(OBJS)

kernel.o : kernel.asm protect.h
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<

main.o : main.c global.h keyboard.h clock.h
	$(CC) $(C_FLAGS) -o $@ $<
protect.o : protect.c protect.h type.h const.h protect.h string.h
	$(CC) $(C_FLAGS) -o $@ $<

start.o : start.c string.h
	$(CC) $(C_FLAGS) -o $@ $<

global.o : global.c const.h type.h
	$(CC) $(C_FLAGS) -o $@ $<

process.o : process.c process.h global.h i8259A.h
	$(CC) $(C_FLAGS) -o $@ $<

systemcall.o : systemcall.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<


# lib
string.o : string.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<

lib.o : lib.c lib.h
	$(CC) $(C_FLAGS) -o $@ $<

clock.o: clock.c
	$(CC) $(C_FLAGS) -o $@ $<

# i8259A.o: i8259A.c
# 	$(CC) $(C_FLAGS) -o @
%.o: %.c
	$(CC) $(C_FLAGS) -o $@ $<

%.o: %.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<