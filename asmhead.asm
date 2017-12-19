; asmhead.asm
; tab = 8

	org	0xc200

botpak	equ	0x00280000		; bootpackのロード先
dskcac	equ	0x00100000		; ディスクキャッシュの場所
dskcac0	equ	0x00008000		; ディスクキャッシュの場所（リアルモード）
vbemode	equ	0x103

; BOOTINFO関係
cyls	equ	0x0ff0			; ブートセクタが設定する
leds	equ	0x0ff1
vmode	equ	0x0ff2			; 色数に関する情報。何ビットカラーか？
scrnx	equ	0x0ff4			; 解像度のX（screen x）
scrny	equ	0x0ff6			; 解像度のY（screen y）
vram	equ	0x0ff8			; グラフィックバッファの開始番地

; VBE存在確認
	mov	ax, 0x9000
	mov	es, ax
	mov	di, 0
	mov	ax, 0x4f00
	int	0x10
	cmp	ax, 0x004f
	jne	scrn320
; VBEのバージョンチェック
	mov	ax, [es:di+0x04]
	cmp	ax, 0x0200
	jb	scrn320
; 画面モード情報を得る
	mov	cx, vbemode
	mov	ax, 0x4f01
	int	0x10
	cmp	ax, 0x004f
	jne	scrn320
; 画面モード情報の確認
	cmp	byte [es:di+0x19], 8
	jne	scrn320
	cmp	byte [es:di+0x1b], 4
	jne	scrn320
	mov	ax, [es:di+0x00]
	and	ax, 0x0080
	jz	scrn320			; モード属性のbit7が0だったので諦める

	mov	bx, vbemode + 0x4000
	mov	ax, 0x4f02
	int	0x10
	mov	byte [vmode], 8		; 画面モードをメモする
	mov	ax, [es:di+0x12]
	mov	[scrnx], ax
	mov	ax, [es:di+0x14]
	mov	[scrny], ax
	mov	eax, [es:di+0x28]
	mov	[vram], eax
	jmp	keystatus

scrn320:
	mov	al, 0x13
	mov	ah, 0x00		; VGAグラフィックス、320x200x8bitカラー
	int	0x10
	mov	byte [vmode], 8		; 画面モードをメモする
	mov	word [scrnx], 320
	mov	word [scrny], 200
	mov	dword [vram], 0x000a0000

; キーボードのLED状態をBIOSに教えてもらう

keystatus:

	mov	ah, 0x02
	int	0x16
	mov	[leds], al

; PICが一切の割り込みを受け付けないようにする
;	AT互換機の仕様では、PICの初期化をするなら
;	こいつをclI前にやっておかないと、たまにハングアップする
;	PICの初期化はあとでやる

	mov	al, 0xff
	out	0x21, al
	nop				; out命令を連続させるとうまくいかない機種があるらしいので
	out	0xa1, al
	cli				; さらにCPUレベルでも割り込み禁止

; CPUから1MB以上のメモリにアクセスできるように、A20GATEを設定

	call	waitkbdout
	mov	al, 0xd1
	out	0x64, al
	call	waitkbdout
	mov	al, 0xdf		; enable A20
	out	0x60, al
	call	waitkbdout

; プロテクトモード移行

	lgdt	[gdtr0]			; 暫定GDTを設定
	mov	eax, cr0
	and	eax, 0x7fffffff		; bit31を0にする（ページング禁止のため）
	or	eax, 0x00000001		; bit0を1にする（プロテクトモード移行のため）
	mov	cr0, eax
	jmp	pipelineflush
pipelineflush:
	mov	ax, 1 * 8		; 読み書き可能セグメント32bit
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

; bootpackの転送

	mov	esi, bootpack		; 転送元
	mov	edi, botpak		; 転送先
	mov	ecx, 512 * 1024 / 4
	call	memcpy

; ついでにディスクデータも本来の位置へ転送

; まずはブートセクタから

	mov	esi, 0x7c00		; 転送元
	mov	edi, dskcac		; 転送先
	mov	ecx, 512 / 4
	call	memcpy

; 残り全部
	mov	esi, dskcac0 + 512	; 転送元
	mov	edi, dskcac + 512	; 転送先
	mov	ecx, 0
	mov	cl, byte [cyls]		; 読み込んだシリンダ数
	imul	ecx, 512 * 18 * 2 / 4	; 1シリンダあたりのバイト数/4を掛ける
	sub	ecx, 512 / 4		; IPL分を引く
	call	memcpy

; asmheadでしなければいけないことは全部し終わったので
;	あとはbootpackに任せる

; bootpackの起動

	mov	ebx, botpak
	mov	ecx, [ebx + 16]
	add	ecx, 3			; ecx += 3;
	shr	ecx, 2			; ecx /= 4;
	jz	skip			; 転送するべきものがない
	mov	esi, [ebx + 20]		; 転送元
	add	esi, ebx
	mov	edi, [ebx + 12]		; 転送先
	call	memcpy
skip:
	mov	esp, dword [ebx + 12]		; スタック初期値
	jmp	dword 2 * 8 : 0x0000001b

waitkbdout:
	in	al, 0x64
	and	al, 0x02
	in	al, 0x60		; 空読み（受信バッファが悪さをしないように）
	jnz	waitkbdout		; andの結果が0でなければwaitkbdoutへ
	ret

memcpy:
	mov	eax, [esi]
	add	esi, 4
	mov	[edi], eax
	add	edi, 4
	sub	ecx, 1
	jnz	memcpy			; 引き算した結果が0でなければmemcpyへ
	ret
; memcpyはアドレスサイズプリフィクスを入れ忘れなければ、ストリング命令でも書ける

	align	16, db 0
gdt0:
	times	8 db 0				; ヌルセレクタ
	dw	0xffff, 0x0000, 0x9200, 0x00cf	; 読み書き可能セグメント32bit
	dw	0xffff, 0x0000, 0x9a28, 0x0047	; 実行可能セグメント32bit（bootpack用）
	dw	0
gdtr0:
	dw	8 * 3 - 1			; テーブルのバイト数-1
	DD	gdt0				; GDTの場所

	alignb	16, db 0

bootpack:
