%ifndef __SNAKE__H
%define __SNAKE__H

%include "field.asm"


; type definition
struc	link_t
	.x:	resd	1
	.y:	resd	1
endstruc

; type definition
struc	snake_t

	.head:	resq	1	; struct* link head
	.size:	resd	1	; int size
	.dir:	resd	1	; enum dir { UP=0, DOWN, LEFT, RIGHT };

endstruc

	section .text

snake_init:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 12

; pre checks
	; x < 1
	cmp	edi, 1
	js	.snake_position_invalid

	; y < 1
	cmp	esi, 1
	js	.snake_position_invalid

	; x+sz > FIELD_MAX-1
	mov	eax, edi
	add	eax, edx
	cmp	eax, FIELD_MAX_X-1
	jg	.snake_position_invalid

; sam initialization
	mov	qword [sam+snake_t.head], snake_body_one	; like malloc, but without it :)
	mov	[sam+snake_t.size], edx
	mov	dword [sam+snake_t.dir], RIGHT

; place snake horizontally with head in a right side
	mov	dword -4[rbp], 0	; i=0
; note: you should be careful with args register, so if you modify them don't forget to save it on stack
.loop:
	mov	eax, [sam+snake_t.size]	; sam.size
	cmp	dword -4[rbp], eax	; check i<sam.size;
	jns	.lend


	mov	qword -12[rbp], rbx	; callee must preserve rbx if uses it
	; below line is an error
	;lea	rbx, [sam+snake_t.head+ecx*8]	; get link address; (sam=base, snake_t.head=displacement, ecx=index, 8=scale)
	mov	ecx, dword -4[rbp]	; save index
	mov	rbx, [sam+snake_t.head]	; get head address
	lea	rbx, [rbx+rcx*8]	; get link address; (rbx=base, ecx=index, 8=scale)

	; initialize snake's links in the way, so head will be at the most right
	; todo: explain below code by lines
	sub	eax, 1
	sub	eax, ecx
	add	eax, edi

	; init x point of a link
	mov	[rbx+link_t.x], eax
	; init y point of a link
	mov	[rbx+link_t.y], esi

; loop testing
;	mov	-8[rbp], edi
;	mov	edi, test_msg
;	call	printstr
;	mov	edi, -8[rbp]

	add	dword -4[rbp], 1		; ++i
	jmp	.loop

.lend:
	call update_hide_tail

	mov	rbx, qword -8[rbp]	; callee must restore rbx; i think it doesn't matter to save it before other calls or after, the key idea here is to preserve it to the caller fnction
	mov	rsp, rbp
	pop	rbp
	ret

.snake_position_invalid:
	mov	edi, pos_invalid
	call	printstr

	mov	rdi, 2
	call	exit

; you can use rbx instead save eax on stack; according to this you always should preserve and restore rbx in callee
snake_render:
	push	rbp
	mov	rbp ,rsp
	sub	rsp, 8

	mov	eax, dword [sam+snake_t.size]
	mov	dword -8[rbp], eax

	mov	dword -4[rbp], 0
.loop:
	mov	eax, dword -4[rbp]	; get index again; eax was reset by call after first iteration
	cmp	eax, dword -8[rbp]
	jns	.lend

	mov	edi, dword -4[rbp]
	call	snake_render_link

	add	dword -4[rbp], 1
	jmp	.loop
.lend:
	mov	rsp, rbp
	pop	rbp
	ret

snake_render_link:
	push	rbp
	mov	rbp ,rsp

	mov	eax, dword [sam+snake_t.size]
	cmp	edi, eax
	jge	.no_such_link

	cmp	edi, 0
	js	.no_such_link

	mov	rax, qword [sam+snake_t.head]
	lea	rax, [rax+rdi*8]	; rdi contain link_num

	mov	rdi, field
	mov	rsi, [rax+link_t.x]
	mov	rdx, [rax+link_t.y]
	mov	r10, 4

	call	index_array
	mov	dword [rax], snake

	mov	rsp, rbp
	pop	rbp
	ret

.no_such_link:
	mov	edi, no_link
	call	printstr

	mov	edi, 3
	call	exit


snake_unrender:
	push	rbp
	mov	rbp ,rsp
	sub	rsp, 8

	mov	eax, dword [sam+snake_t.size]
	mov	dword -8[rbp], eax

	mov	dword -4[rbp], 0
.loop:
	mov	eax, dword -4[rbp]	; get index again; eax was reset by call after first iteration
	cmp	eax, dword -8[rbp]
	jns	.lend

	mov	edi, dword -4[rbp]
	call	snake_unrender_link

	add	dword -4[rbp], 1
	jmp	.loop
.lend:
	mov	rsp, rbp
	pop	rbp
	ret


snake_unrender_link:
	push	rbp
	mov	rbp ,rsp

	mov	eax, dword [sam+snake_t.size]
	cmp	edi, eax
	jge	.no_such_link

	cmp	edi, 0
	js	.no_such_link

	mov	rax, qword [sam+snake_t.head]
	lea	rax, [rax+rdi*8]	; rdi contain link_num

	mov	rdi, field
	mov	rsi, [rax+link_t.x]
	mov	rdx, [rax+link_t.y]
	mov	r10, 4

	call	index_array
	mov	dword [rax], empty

	mov	rsp, rbp
	pop	rbp
	ret

.no_such_link:
	mov	edi, no_link
	call	printstr

	mov	edi, 3
	call	exit

; investigate it
update_hide_tail:
	push	rbp
	mov	rbp, rsp

	mov	rax, qword [sam+snake_t.head]
	mov	ecx, dword [sam+snake_t.size]
	sub	ecx, 1
	lea	eax, dword [rax+rcx*8]		; save real tail link	; must be mov here

	mov	rdx, qword [sam+snake_t.head]
	mov	dword [rdx+snake_t.size*8], eax	; update hide tail link	; eax too small here

	mov	rsp, rbp
	pop	rbp
	ret

; move all links forward in memory begin from last; and update head after that
snake_move_forward:
	push	rbp
	push	rbx		; preserve, because we use it
	mov	rbp, rsp
	sub	rsp, 4

	mov	ebx, dword [sam+snake_t.size]
	mov	dword -4[rbp], 0
.loop:
	sub	ebx, 1
	cmp	ebx, dword -4[rbp]
	jle	.lend

	mov	rdi, rbx
	call	snake_move_link_forward

	jmp	.loop
.lend:
	call	sanke_move_head_forward
	mov	rsp, rbp
	pop	rbx
	pop	rbp
	ret

; moves link_num to 1 unit forward in memory, so we can make room fon one link before the link_num
; note: use this with cautions because it resets link_num+1; so you can mess up things very quickly
; (like memcpy, but optimized, because it uses only one memory space :) )
; note: it's actually like memmove (one part of it) rather than memcopy
snake_move_link_forward:
	push	rbp
	mov	rbp, rsp

	; rdi already ontains link_num
	call	snake_get_link_addr
	mov	rcx, qword [rax]	; save link_num value

	lea	rdx, qword [rax+1*8]		; get link_num+1 address
	mov	qword [rdx], rcx

	mov	rsp, rbp
	pop	rbp
	ret

snake_grow:
	push	rbp
	mov	rbp, rsp

	; inc sam size
	; call update_hide
	; thats it
	
	mov	rsp, rbp
	pop	rbp
	ret

snake_get_head_addr:
	push	rbp
	mov	rbp, rsp

	mov	rdi, 0	; head is just a link with 0 index
	call	snake_get_link_addr

	mov	rsp, rbp
	pop	rbp
	ret

snake_get_link_addr:
	push	rbp
	mov	rbp, rsp

	cmp	dword [sam+snake_t.size], 1
	jl	.snake_too_small

	mov	rax, qword [sam+snake_t.head]
	lea	rax, [rax+rdi*8]	; rdi contain link_num

	mov	rsp, rbp
	pop	rbp
	ret

.snake_too_small:
	mov	rdi, no_size
	call	printstr

	mov	rdi, 6
	call	exit

sanke_move_head_forward:
	push	rbp
	mov	rbp, rsp

	call	snake_get_head_addr
.c1:
	cmp	dword [sam+snake_t.dir], RIGHT
	jne	.c2
	add	dword [rax+link_t.x], 1
	jmp	.send
.c2:
	cmp	dword [sam+snake_t.dir], LEFT
	jne	.c3
	sub	dword [rax+link_t.x], 1
	jmp	.send
.c3:
	cmp	dword [sam+snake_t.dir], UP
	jne	.c4
	sub	dword [rax+link_t.y], 1
	jmp	.send
.c4:
	cmp	dword [sam+snake_t.dir], DOWN
	jne	.c5
	add	dword [rax+link_t.y], 1
.c5:
	mov	rdi, unk_dir
	call	printstr

.send:	; switch end
	mov	rsp, rbp
	pop	rbp
	ret

blank:
	push	rbp
	mov	rbp, rsp
	mov	rsp, rbp
	pop	rbp
	ret


	section .data

; sam by deafault is snake_one
sam:

; declaration instance of type snake_t
snake_one:
	istruc snake_t
; just testing struct declaration inside other structure
;		at snake_t.head
;
;			istruc link_t
;				at link_t.x, dd 0
;				at link_t.y, dd 0
;			iend
		at snake_t.head, dq	0
		at snake_t.size, dd	0
		at snake_t.dir, dd	0

	iend


snake_two:
	istruc snake_t
		at snake_t.head, dq	0
		at snake_t.size, dd	0
		at snake_t.dir, dd	0
	iend

pos_invalid	db	"snake position invalid", 10, 0
no_link		db	"snake doesn't have such link", 10, 0
no_size		db	"failed to get snake's link, because snake doesn't even has it.", 10, 0
unk_dir		db	"unknown direction", 10, 0
succ		db	"success", 10, 0
test_msg	db	"\\\just test message\\\", 10, 0

; enum dir { UP=0, DOWN, LEFT, RIGHT };
UP	equ	0
DOWN	equ	1
LEFT	equ	2
RIGHT	equ	3

	section .bss

; reserve memory for two snake's body (assume snake with max size can fill all the field, not count borders)
; so we can swap them when we need to increase snake's size
snake_body_one:
	; link_t_size implicitly defined by 'struc' macros
	; +1 used for hide tail link which is used when snake grow
	resq	link_t_size*(FIELD_MAX_X-2)+(FIELD_MAX_Y-2)+1	

snake_body_two:
	resq	link_t_size*(FIELD_MAX_X-2)+(FIELD_MAX_Y-2)+1
%endif
