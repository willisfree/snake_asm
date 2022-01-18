	global	_start

%include "std.asm"
%include "field.asm"
%include "snake.asm"

	section .text
_start:
	push	rbp
	mov	rbp, rsp

	call field_init

	mov	edi, 1	; x point
	mov	esi, 1	; y point
	mov	edx, 7	; snake's size

	call snake_init
	call snake_render
	call field_render


	call snake_unrender
	call snake_move_forward
	call snake_render
	call field_render

	call snake_unrender
	call snake_move_forward
	call snake_render
	call field_render


	call snake_unrender
	call snake_move_forward
	call snake_render
	call field_render


	call snake_unrender
	call snake_move_forward
	call snake_render
	call field_render

;	times 3 call nl
;	call snake_unrender
;	call field_render

	;call run

	xor	rdi, rdi	; return value 0
	call exit

run:
	push	rbp
	mov	rbp, rsp
	sub	rsp, 8

	mov	dword -4[rbp], 1
.inf_loop:
	cmp	dword -4[rbp], 1	; infinite loop
	jne	.inf_lend

	call field_render
;	call handle_keys

	;movfloat edi, 0.5
	;call usleep	; which using nanosleep

	call snake_unrender
	call snake_move_forward
;	call snake_food_check
	call snake_render
;	call snake_check_collision
;	call food_spawn
	jmp	.inf_loop

.inf_lend:
	mov	rsp, rbp
	pop	rbp
	ret

	section .data

message	db	"Register = %08X", 10, 0
