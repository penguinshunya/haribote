_test:
	push	rbp
	mov	rbp, rsp
	mov	dword [rbp - 4], 1
	mov	dword [rbp - 8], 2
	mov	dword [rbp - 12], 3
	pop	rbp
	ret
