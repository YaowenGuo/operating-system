# Kernel Entry Point
# It is same as "KERNEL_ENTRY_PHYADDR" in staticlib.inc
ENTRY_POINT = 0x30400

# offset of entry point in kernel file
# It depends on ENTRY_POINT
ENTRY_OFFSET = 0x400


ASM = nasm
ASMFLAGS = -I boot/include/
ASM_KERNEL_FLAGS = -I include/ -f elf -g
LD = ld
# 在64位机上编译目标文件为32位代码，需使用 -m elf_i386参数
LD_FLAGS = -m elf_i386  -Ttext $(ENTRY_POINT)  #调试时去掉-s参数
CC = gcc
# 在64位机上编译32位目标文件，需要使用-m32参数
C_FLAGS = -I include/ -c  -fno-builtin -m32 -g

# Target program
OS_BOOT = boot/boot.bin boot/loader.bin
OS_KERNEL = kernel/kernel.bin
OBJS = kernel/kernel.o kernel/start.o kernel/global.o kernel/protect.o lib/string.o \
    lib/lib.o lib/i8259A.o lib/port.o kernel/process.o kernel/systemcall.o

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

kernel/kernel.o : kernel/kernel.asm include/protect.h
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<

kernel/protect.o : kernel/protect.c include/protect.h include/type.h \
		include/const.h include/protect.h include/string.h
	$(CC) $(C_FLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/string.h
	$(CC) $(C_FLAGS) -o $@ $<

kernel/global.o : kernel/global.c include/const.h include/type.h
	$(CC) $(C_FLAGS) -o $@ $<

kernel/process.o : kernel/process.c include/process.h include/global.h \
		include/i8259A.h
	$(CC) $(C_FLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<

lib/port.o : lib/port.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<

lib/lib.o : lib/lib.c include/lib.h
	$(CC) $(C_FLAGS) -o $@ $<

lib/i8259A.o : lib/i8259A.c include/port.h
	$(CC) $(C_FLAGS) -o $@ $<

kernel/systemcall.o : kernel/systemcall.asm
	$(ASM) $(ASM_KERNEL_FLAGS) -o $@ $<
