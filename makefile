# Kernel Entry Point
# It is same as "KERNEL_ENTRY_PHYADDR" in staticlib.inc
ENTRY_POINT = 0x30400

# offset of entry point in kernel file
# It depends on ENTRY_POINT
ENTRY_OFFSET = 0x400


ASM = nasm
ASMFLAGS = -I boot/include/
ASM_KERNEL_FLAGS = -I include -f elf
LD = ld
# 在64位机上编译目标文件为32位代码，需使用 -m elf_i386参数
LD_FLAGS = -m elf_i386 -s -Ttext $(ENTRY_POINT)
CC = gcc
# 在64位机上编译32位目标文件，需要使用-m32参数
C_FLAGS = -I include/ -c -fno-builtin -m32

# Target program
OS_BOOT = boot/boot.bin boot/loader.bin
OS_KERNEL = kernel/kernel.bin
OBJS = kernel/kernel.o kernel/start.o lib/string.o 

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

kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/const.h include/protect.h \
	include/type.h include/string.h
	$(CC) $(C_FLAGS) -o $@ $<
lib/string.o : lib/string.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<
