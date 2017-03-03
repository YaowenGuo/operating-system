ASM = nasm
ASMFLAGS = -I boot/include/

CC = gcc


# Target program
TARGET = boot/boot.bin boot/loader.bin

.PHONY : all clean install 

all : $(TARGET)

clean :
	rm -f $(TARGET) 


install : 
	dd if=boot/boot.bin of=a.img bs=512 count=1 conv=notrunc
	sudo mount -o loop a.img /mnt/floppy
	sudo cp -fv boot/loader.bin /mnt/floppy
	sudo umount /mnt/floppy

boot/boot.bin : boot/boot.asm  boot/include/staticlib.inc
	$(ASM) $(ASMFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/staticlib.inc
	$(ASM) $(ASMFLAGS) -o $@ $<



# ipl.bin : ipl.asm
# 	yasm ipl.asm -o ipl.bin


# install:ipl.bin
# 	dd if=ipl.bin of=a.img  count=1 conv=notrunc

# clean:
# 	rm  *.bin