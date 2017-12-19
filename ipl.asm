; ipl.asm
; tab = 8

	org	0x7c00

cyls	equ	10

	jmp	entry
	db	0x90

	db	"HELLOIPL"	; ブートセクタの名前を自由に書いてよい（8バイト）
	dw	512		; 1セクタの大きさ（512にしなければいけない）
	db	1		; クラスタの大きさ（1セクタにしなければいけない）
	dw	1		; FATがどこから始まるか（普通は1セクタ目からにする）
	db	2		; FATの個数（2にしなければいけない）
	dw	224		; ルートディレクトリ領域の大きさ（普通は224エントリにする）
	dw	2880		; このドライブの大きさ（2880にしなければいけない）
	db	0xf0		; メディアのタイプ（0xf0にしなければいけない）
	dw	9		; FAT領域の長さ（9セクタにしなければいけない）
	dw	18		; 1トラックにいくつのセクタがあるか（18にしなければいけない）
	dw	2		; ヘッドの数（2にしなければいけない）
	dd	0		; パーティションを使ってないのでここは必ず0
	dd	2880		; このドライブの大きさをもう一度書く
	db	0, 0, 0x29	; よく分からないけどこの値にしておくといいらしい
	dd	0xffffffff	; たぶんボリュームシリアル番号
	db	"HELLO-OS   "	; ディスクの名前（11バイト）
	db	"FAT12   "	; フォーマットの名前（8バイト）
	times	18 db 0		; とりあえず18バイトあけておく

entry:
	mov	ax, 0		; レジスタ初期化
	mov	ss, ax
	mov	sp, 0x7c00
	mov	ds, ax

	mov	ax, 0x0820
	mov	es, ax
	mov	ch, 0		; シリンダ0
	mov	dh, 0		; ヘッド0
	mov	cl, 2		; セクタ2
readloop:
	mov	si, 0		; 失敗回数を数えるレジスタ
retry:
	mov	ah, 0x02	; ah=0x02 : ディスク読み込み
	mov	al, 1		; 1セクタ
	mov	bx, 0
	mov	dl, 0x00	; Aドライブ
	int	0x13		; ディスクBIOS呼び出し
	jnc	next		; エラーが起きなければnextへ
	add	si, 1		; siに1を足す
	cmp	si, 5		; siと5を比較
	jae	error		; si >= 5 だったらerrorへ
	mov	ah, 0x00
	mov	dl, 0x00	; Aドライブ
	int	0x13		; ドライブのリセット
	jmp	retry
next:
	mov	ax, es		; アドレスを0x200進める
	add	ax, 0x0020
	mov	es, ax		; add es, 0x020 という命令がないのでこうしている
	add	cl, 1		; clに1を足す
	cmp	cl, 18		; clと18を比較
	jbe	readloop	; cl <= 18 だったらreadloopへ
	mov	cl, 1
	add	dh, 1
	cmp	dh, 2
	jb	readloop	; dh < 2 だったらreadloopへ
	mov	dh, 0
	add	ch, 1
	cmp	ch, cyls
	jb	readloop	; ch < cyls だったらreadloopへ

	mov	[0x0ff0], ch
	jmp	0xc200

error:
	mov	si, msg
putloop:
	mov	al, [si]
	add	si, 1		; siに1を足す
	cmp	al, 0
	je	fin
	mov	ah, 0x0e	; 一文字表示ファンクション
	mov	bx, 15		; カラーコード
	int	0x10		; ビデオBIOS呼び出し
	jmp	putloop
fin:
	hlt
	jmp	fin
msg:
	db	0x0a, 0x0a	; 改行を2つ
	db	"load error"
	db	0x0a		; 改行
	db	0

	times	0x1fe - ($ - $$) db 0

	db	0x55, 0xaa
