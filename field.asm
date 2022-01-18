%ifndef __FIELD__H
%define __FIELD__H

%define	FIELD_MAX_X 20
%define	FIELD_MAX_Y FIELD_MAX_X

%include "std.asm"
	
	section .text

field_init:
	push	rbp
	mov	rbp, rsp
	; always sub from stack if you are using it or you will fucked up it, i swear
	; edit: you only need it if you want to call some fucntions after save some values in current's stack using rbp offset
	sub	rsp, 12

;	for (size_t y=0; y<FIELD_MAX_Y; ++y)
	mov	dword -4[rbp], 0; y axis
	jmp	.start_y_loop

.pre_y_loop:
	add	dword -4[rbp], 1	; ++y
.start_y_loop:
	cmp	dword -4[rbp], FIELD_MAX_Y
	jns	.end_loop

;	for (size_t x=0; x<FIELD_MAX_X; ++x)
	mov	dword -8[rbp], 0; x var
.start_x_loop:

	cmp	dword -8[rbp], FIELD_MAX_X
	jns	.pre_y_loop

;	get memory address for field[y][x]
	mov	rdi, field
	mov	esi, dword -4[rbp]	; y is a column
	mov	edx, dword -8[rbp]	; x is a row
	mov	r10, 4			; sizeof() of one field point in bytes
	call	index_array

;	field[y][x] = EMPTY;		; all squares are invisible by default
	mov	edx, empty
	mov	[eax], edx

	add	dword -8[rbp], 1	; ++x
	jmp	.start_x_loop

.end_loop:
	call field_init_border

	mov	rsp, rbp
	pop	rbp
	ret

; init right and left borders in another (y axis)
; and top and bottom borders in one loop (x axis)
field_init_border:
	push	rbp
	mov	rbp, rsp

	sub	rsp, 8

	mov	dword -4[rbp], 0	; y axis
.start_y_loop:
	cmp	dword -4[rbp], FIELD_MAX_Y
	jns	.pre_x_loop

	; left vertical border
	mov	rdi, field
	mov	esi, 0			; x is a row
	mov	edx, dword -4[rbp]	; y is a column
	mov	r10d, 4			; sizeof() of one field point in bytes
	call	index_array

	mov	edx, border
	mov	[eax], edx

	; right vertical border
	mov	rdi, field
	mov	esi, FIELD_MAX_X-1	; x is a row
	mov	edx, dword -4[rbp]	; y is a column
	mov	r10, 4			; sizeof() of one field point in bytes
	call	index_array

	mov	edx, border
	mov	[eax], edx

	add	dword -4[rbp], 1
	jmp	.start_y_loop

.pre_x_loop:
	mov	dword -8[rbp], 0	; x axis
.start_x_loop:
	cmp	dword -8[rbp], FIELD_MAX_X
	jns	.end_x_loop

	; top horizontal border
	mov	rdi, field
	mov	esi, dword -8[rbp]	; x is a row
	mov	edx, 0			; y is a column
	mov	r10, 4			; sizeof() of one field point in bytes
	call	index_array

	mov	edx, border
	mov	[eax], edx

	; bottom horizontal border
	mov	rdi, field
	mov	esi, dword -8[rbp]	; x is a row
	mov	edx, FIELD_MAX_Y-1	; y is a column
	mov	r10, 4			; sizeof() of one field point in bytes
	call	index_array

	mov	edx, border
	mov	[eax], edx

	add	dword -8[rbp], 1
	jmp	.start_x_loop

.end_x_loop:
	mov	rsp, rbp
	pop	rbp
	ret

field_render:
	push	rbp
	mov	rbp, rsp

	sub	rsp, 8

	mov	dword -4[rbp], 0	; y axis
	jmp	.start_y_loop
.pre_y_loop:
	add	dword -4[rbp], 1	; ++y
	mov     rdi, 10
	call	printch
.start_y_loop:
	cmp	dword -4[rbp], FIELD_MAX_Y
	jns	.end_loop

	mov	dword -8[rbp], 0; x var
.start_x_loop:
	cmp	dword -8[rbp], FIELD_MAX_X
	jns	.pre_y_loop

	; cursor_move(y, x) here

	mov	rdi, field
	mov	esi, dword -8[rbp]	; x is a row
	mov	edx, dword -4[rbp]	; y is a column
	mov	r10, 4			; sizeof() of one field point in bytes
	call	index_array

	mov	eax, [eax]		; save value of indexed elem

.c1:	; case BORDER:
	cmp	eax, border
	jne	.c2
	mov     rdi, '+'
	call	printch
	mov     rdi, ' '
	call	printch
	jmp	.send
.c2:	; case SNAKE:
	cmp	eax, snake
	jne	.c3
	mov     rdi, '#'
	call	printch
	mov     rdi, ' '
	call	printch
	jmp	.send
.c3:	; case EMPTY:
	cmp	eax, empty
	jne	.c4
	mov     rdi, ' '
	call	printch
	mov     rdi, ' '
	call	printch
	jmp	.send
.c4:	; case FOOD:
	cmp	eax, food
	jne	.c5
	mov     rdi, '*'
	call	printch
	mov     rdi, ' '
	call	printch
	jmp	.send
.c5:	; case DEFAULT:
	mov     rdi, '?'
	call	printch
	mov     rdi, ' '
	call	printch
.send:	; switch end

	add	dword -8[rbp], 1	; ++x
	jmp	.start_x_loop

.end_loop:
	mov	rsp, rbp
	pop	rbp
	ret

	section .data

; field's point types
border	equ	0
snake	equ	1
empty	equ	2
food	equ	3

	section .bss
field	resd	FIELD_MAX_Y*FIELD_MAX_X

%endif
