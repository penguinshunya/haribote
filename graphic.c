#include "bootpack.h"
#include "hankaku.h"

void init_palette(void)
{
	static unsigned char table_rgb[16 * 3] = {
		0x00, 0x00, 0x00,
		0xff, 0x00, 0x00,
		0x00, 0xff, 0x00,
		0xff, 0xff, 0x00,
		0x00, 0x00, 0xff,
		0xff, 0x00, 0xff,
		0x00, 0xff, 0xff,
		0xff, 0xff, 0xff,
		0xc6, 0xc6, 0xc6,
		0x84, 0x00, 0x00,
		0x00, 0x84, 0x00,
		0x84, 0x84, 0x00,
		0x00, 0x00, 0x84,
		0x84, 0x00, 0x84,
		0x44, 0x88, 0xcc,
		0x84, 0x84, 0x84,
	};
	set_palette(0, 15, table_rgb);

	/* static char 命令は、データにしか使えないけどDB命令相当 */
}

void set_palette(int start, int end, unsigned char *rgb)
{
	int i, eflags;
	eflags = io_load_eflags();	/* 割り込み許可フラグの値を記録する */
	io_cli();			/* 許可フラグを0にして割り込み禁止にする */
	io_out8(0x03c8, start);
	for (i = start; i <= end; i++) {
		io_out8(0x03c9, rgb[0] / 4);
		io_out8(0x03c9, rgb[1] / 4);
		io_out8(0x03c9, rgb[2] / 4);
		rgb += 3;
	}
	io_store_eflags(eflags);	/* 割り込み許可フラグを元に戻す */
}

void init_screen(unsigned char *vram, int xsize, int ysize)
{
	boxfill8(vram, xsize, COL8_4488CC,          0,          0, xsize -  1, ysize - 29);
	boxfill8(vram, xsize, COL8_C6C6C6,          0, ysize - 28, xsize -  1, ysize - 28);
	boxfill8(vram, xsize, COL8_FFFFFF,          0, ysize - 27, xsize -  1, ysize - 27);
	boxfill8(vram, xsize, COL8_C6C6C6,          0, ysize - 26, xsize -  1, ysize -  1);

	boxfill8(vram, xsize, COL8_FFFFFF,          3, ysize - 24,         59, ysize - 24);
	boxfill8(vram, xsize, COL8_FFFFFF,          2, ysize - 24,          2, ysize -  4);
	boxfill8(vram, xsize, COL8_848484,          3, ysize -  4,         59, ysize -  4);
	boxfill8(vram, xsize, COL8_848484,         59, ysize - 23,         59, ysize -  5);
	boxfill8(vram, xsize, COL8_000000,          2, ysize -  3,         59, ysize -  3);
	boxfill8(vram, xsize, COL8_000000,         60, ysize - 24,         60, ysize -  3);

	boxfill8(vram, xsize, COL8_848484, xsize - 47, ysize - 24, xsize -  4, ysize - 24);
	boxfill8(vram, xsize, COL8_848484, xsize - 47, ysize - 23, xsize - 47, ysize -  4);
	boxfill8(vram, xsize, COL8_FFFFFF, xsize - 47, ysize -  3, xsize -  4, ysize -  3);
	boxfill8(vram, xsize, COL8_FFFFFF, xsize -  3, ysize - 24, xsize -  3, ysize -  3);
}

void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1)
{
	int x, y;
	for (y = y0; y <= y1; y++) {
		for (x = x0; x <= x1; x++) {
			vram[y * xsize + x] = c;
		}
	}
}

void putfont8(unsigned char *vram, int xsize, int x, int y, char c, char *font)
{
	int i;
	unsigned char *p;
	char d;
	for (i = 0; i < 16; i++) {
		p = vram + (y + i) * xsize + x;
		d = font[i];
		if ((d & 0x80) != 0) { p[0] = c; }
		if ((d & 0x40) != 0) { p[1] = c; }
		if ((d & 0x20) != 0) { p[2] = c; }
		if ((d & 0x10) != 0) { p[3] = c; }
		if ((d & 0x08) != 0) { p[4] = c; }
		if ((d & 0x04) != 0) { p[5] = c; }
		if ((d & 0x02) != 0) { p[6] = c; }
		if ((d & 0x01) != 0) { p[7] = c; }
	}
}

void putfonts8_asc(unsigned char *vram, int xsize, int x, int y, char c, char *s)
{
	extern char hankaku[4096];
	for (; *s != 0x00; s++) {
		putfont8(vram, xsize, x, y, c, hankaku + *s * 16);
		x += 8;
	}
}

void putblock8_8(unsigned char *vram, int vxsize, int pxsize,
	int pysize, int px0, int py0, char *buf, int bxsize)
{
	int x, y;
	for (y = 0; y < pysize; y++) {
		for (x = 0; x < pxsize; x++) {
			vram[(py0 + y) * vxsize + (px0 + x)] = buf[y * bxsize + x];
		}
	}
}

void init_mouse_cursor8(unsigned char *mouse, char bc)
{
	static char cursor[16][16] = {
		"****************",
		"*OOOOOOOOOOOOO*.",
		"*OOOOOOOOOOOO*..",
		"*OOOOOOOOOOO*...",
		"*OOOOOOOOOO*....",
		"*OOOOOOOOO*.....",
		"*OOOOOOOO*......",
		"*OOOOOOOO*......",
		"*OOOOOOOOO*.....",
		"*OOOOO**OOO*....",
		"*OOOO*..*OOO*...",
		"*OOO*....*OOO*..",
		"*OO*......*OOO*.",
		"*O*........*OOO*",
		"**..........*OO*",
		"*............***"
	};
	int x, y;

	for (y = 0; y < 16; y++) {
		for (x = 0; x < 16; x++) {
			if (cursor[y][x] == '*') {
				mouse[y * 16 + x] = COL8_000000;
			}
			if (cursor[y][x] == 'O') {
				mouse[y * 16 + x] = COL8_FFFFFF;
			}
			if (cursor[y][x] == '.') {
				mouse[y * 16 + x] = bc;
			}
		}
	}
}
