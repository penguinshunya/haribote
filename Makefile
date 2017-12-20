CC	= /usr/local/i386elfgcc/bin/i386-elf-gcc
LD	= /usr/local/i386elfgcc/bin/i386-elf-ld
NASM	= nasm
QEMU	= qemu-system-i386
QFLAGS	= -boot a -m 32 -drive file=helloos.img,format=raw,if=floppy

OBJS	:= tsprintf.o nasmfunc.o graphic.o dsctbl.o bootpack-rs.o
OBJS	+= int.o fifo.o keyboard.o mouse.o memory.o sheet.o window.o timer.o
OBJS	+= functions.o memset.o

helloos.img: asmhead.bin bootpack.bin ipl.bin haribote.sys
	mformat -f 1440 -C -B ipl.bin -i helloos.img ::
	mcopy -i helloos.img haribote.sys ::

haribote.sys: asmhead.bin bootpack.bin
	cat asmhead.bin bootpack.bin > haribote.sys

bootpack.bin: $(OBJS) os.ld
	$(LD) -T os.ld -o $@ $(OBJS)

ipl.bin: ipl.asm
	$(NASM) $< -o $@

asmhead.bin: asmhead.asm
	$(NASM) $< -o $@ -l asmhead.lst

%.o: %.asm
	$(NASM) -f elf32 $< -o $@ -l $*.lst

%.o: %.c
	$(CC) -Wall -c -g -fno-pic $< -o $@

bootpack-rs.o: bootpack.rs
	rustc --target i686-unknown-linux-gnu --crate-type staticlib --emit obj -C relocation-model=static -C opt-level=2 bootpack.rs -o bootpack-rs.o

run: helloos.img
	$(QEMU) $(QFLAGS)

debug: helloos.img
	$(QEMU) $(QFLAGS) -s -S

clean:
	rm -f *.o *.lst *.bin haribote.sys helloos.img
