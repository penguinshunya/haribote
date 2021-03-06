	global	io_hlt, io_cli, io_sti, io_stihlt
	global	io_in8, io_in16, io_in32
	global	io_out8, io_out16, io_out32
	global	io_load_eflags, io_store_eflags
	global	load_gdtr, load_idtr
	global	asm_inthandler20, asm_inthandler21, asm_inthandler2c
	global	load_cr0, store_cr0
	global	memtest_sub
	global	get_esp
	global	load_tr, taskswitch3, taskswitch4, farjmp

	extern	inthandler20, inthandler21, inthandler2c

io_hlt:		; void io_hlt(void);
	hlt
	ret

io_cli:		; void io_cli(void);
	cli
	ret

io_sti:		; void io_sti(void);
	sti
	ret

io_stihlt:	; void io_stihlt(void);
	sti
	hlt
	ret

io_in8:		; int io_in8(int port);
	mov	edx, [esp + 4]		; port
	mov	eax, 0
	in	al, dx
	ret

io_in16:	; int io_in16(int port);
	mov	edx, [esp + 4]		; port
	mov	eax, 0
	in	ax, dx
	ret

io_in32:	; int io_in32(int port);
	mov	edx, [esp + 4]		; port
	mov	eax, 0
	in	eax, dx
	ret

io_out8:	; void io_out8(int port, int data);
	mov	edx, [esp + 4]		; port
	mov	al, [esp + 8]		; data
	out	dx, al
	ret

io_out16:	; void io_out16(int port, int data);
	mov	edx, [esp + 4]		; port
	mov	ax, [esp + 8]		; data
	out	dx, ax
	ret

io_out32:	; void io_out32(int port, int data);
	mov	edx, [esp + 4]		; port
	mov	eax, [esp + 8]		; data
	out	dx, eax
	ret

io_load_eflags:		; int io_load_eflags(void);
	pushfd		; push eflags という意味
	pop	eax
	ret

io_store_eflags:	; void io_store_eflags(int eflags);
	mov	eax, [esp + 4]
	push	eax
	popfd		; pop eflags という意味
	ret

load_gdtr:		; void load_gdtr(int limit, int addr);
	mov	ax, [esp + 4]
	mov	[esp + 6], ax
	lgdt	[esp + 6]
	ret

load_idtr:		; void load_idtr(int limit, int addr);
	mov	ax, [esp + 4]
	mov	[esp + 6], ax
	lidt	[esp + 6]
	ret

asm_inthandler20:
	push	es
	push	ds
	pushad
	mov	eax, esp
	push	eax
	mov	ax, ss
	mov	ds, ax
	mov	es, ax
	call	inthandler20
	pop	eax
	popad
	pop	ds
	pop	es
	iretd

asm_inthandler21:
	push	es
	push	ds
	pushad
	mov	eax, esp
	push	eax
	mov	ax, ss
	mov	ds, ax
	mov	es, ax
	call	inthandler21
	pop	eax
	popad
	pop	ds
	pop	es
	iretd

asm_inthandler2c:
	push	es
	push	ds
	pushad
	mov	eax, esp
	push	eax
	mov	ax, ss
	mov	ds, ax
	mov	es, ax
	call	inthandler2c
	pop	eax
	popad
	pop	ds
	pop	es
	iretd

load_cr0:	; int load_cr0(void);
	mov	eax, cr0
	ret

store_cr0:	; void store_cr0(int cr0);
	mov	eax, [esp + 4]
	mov	cr0, eax
	ret

memtest_sub:	; unsigned int memtest_sub(unsigned int start, unsigned int end)
	push	edi			; (ebx, esi, edi も使いたいので)
	push	esi
	push	ebx
	mov	esi, 0xaa55aa55		; pat0 = 0xaa55aa55;
	mov	edi, 0x55aa55aa		; pat1 = 0x55aa55aa;
	mov	eax, [esp + 12 + 4]	; i = start;
mts_loop:
	mov	ebx, eax
	add	ebx, 0xffc		; p = i + 0xffc;
	mov	edx, [ebx]		; old = *p;
	mov	[ebx], esi		; *p = pat0;
	xor	dword [ebx], 0xffffffff	; *p ^= 0xffffffff;
	cmp	edi, [ebx]		; if (*p != pat1) {
	jne	mts_fin
	xor	dword [ebx], 0xffffffff	; *p ^= 0xffffffff;
	cmp	esi, [ebx]		; if (*p != pat0) {
	jne	mts_fin
	mov	[ebx], edx		; *p = old;
	add	eax, 0x1000		; i += 0x1000;
	cmp	eax, [esp + 12 + 8]	; if (i <= end) goto mts_loop;
	jbe	mts_loop
	pop	ebx
	pop	esi
	pop	edi
	ret
mts_fin:
	mov	[ebx], edx		; *p = old
	pop	ebx
	pop	esi
	pop	edi
	ret

get_esp:
	mov	eax, esp
	ret

load_tr:	; void load_tr(int tr);
	ltr	[esp + 4]
	ret

taskswitch3:	; void taskswitch3(void);
	jmp	3 * 8: 0
	ret

taskswitch4:	; void taskswitch4(void);
	jmp	4 * 8: 0
	ret

farjmp:		; void farjmp(int eip, int cs);
	jmp	far [esp + 4]		; eip, cs
	ret
