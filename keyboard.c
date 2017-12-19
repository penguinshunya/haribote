#include "bootpack.h"

int keydata0;

void wait_KBC_sendready(void)
{
	/* キーボードコントローラがデータ送信可能になるのを待つ */
	for (;;) {
		if ((io_in8(PORT_KEYSTA) & KEYSTA_SEND_NOTREADY) == 0) {
			break;
		}
	}
}

void init_keyboard(struct FIFO32 *fifo, int data0)
{
	/* 書き込み先のFIFOバッファを記憶 */
	keyfifo = fifo;
	keydata0 = data0;
	/* キーボードコントローラの初期化 */
	wait_KBC_sendready();
	io_out8(PORT_KEYCMD, KEYCMD_WRITE_MODE);
	wait_KBC_sendready();
	io_out8(PORT_KEYDAT, KBC_MODE);
}

void inthandler21(int *esp)
/* PS/2キーボードからの割り込み */
{
	unsigned char data;
	io_out8(PIC0_OCW2, 0x61);	/* IRQ-01受付完了をPICに通知 */
	data = io_in8(PORT_KEYDAT);
	fifo32_put(keyfifo, data + keydata0);
}
