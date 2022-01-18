%ifndef __STD__H
%define __STD__H

%include "field.asm" ; FIELD_MAX_X and FIELD_MAX_Y consts here

	section .text

; alghorithm
; sz = sizeof(1 elem)
; row = MAX_X * sz * row_n
; col = col_n * sz
; index address = row + col
index_array:
	push	rbp
	mov	rbp, rsp

	; mul clobber RDX register, so save it on stack first
	mov	dword -4[rbp], edx

	; calculate row	
	xor	rax, rax
	mov	rax, FIELD_MAX_X	; MAX_X

	mul	r10d			; * sz	; mul save in eax or in reg:reg (see docs)
	mul	esi			; * row_n
	mov	dword -8[rbp], eax	; save row on stack

	; calculate col	
	xor	rax, rax
	mov	eax, dword -4[rbp]	; col_n
	mul	r10d			; * sz
	mov	dword -12[rbp], eax	; save col on stack

	; get index address
	mov	rax, rdi		; array address
	; make offset
	add	eax, dword -8[rbp]
	add	eax, dword -12[rbp]

	pop	rbp
	ret

printch:
	push	rbp
	mov	rbp, rsp

	mov	rax, 1			; write syscall
					; using -4 offset, so stack will be aligned
	mov	byte -4[rbp], dil	; save char (one byte) from edi on stack, because write syscall gets pointer to buffer
	lea	rsi, dword -4[rbp]	; address of char for print
	mov	rdi, 1			; stdout
	mov	rdx, 1			; one byte
	syscall

	pop	rbp
	ret

; note: not efficient implementation because of multiple write syscalls
printstr:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 8

	mov	dword -4[rbp], edi	; save cstr pointer
	mov	dword -8[rbp], 0
.loop:
	mov	eax, dword -4[rbp]	; cstr pointer
	mov	edx, dword -8[rbp]	; char index
	cmp	byte [eax+edx], 0	; cstring contain 0 at the end
	jle	.end

	movzx	edi, byte [eax+edx]
	call	printch

	add	dword -8[rbp], 1
	jmp	.loop

.end:
	mov	rsp, rbp
	pop	rbp
	ret

nl:
	mov	edi, 10
	call	printch
	ret

exit:
	mov	rax, 60
	; return code already in rdi
	syscall

%endif
