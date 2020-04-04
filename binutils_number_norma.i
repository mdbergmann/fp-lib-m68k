	; Copyright: Manfred Bergmann in 2018

	; (re)normalize mantisse (subroutine)
	; 
	; d0: input (float number)
	; d1: size of int part
	; d7: output
	
norm_mantisse
	movem.l	d0-d6,-(sp)

	; the new '1' must be somewhere between the 2. and 32-9-d1 bit
	; previous largest int part in d1
	
	clr.l	d3	;used for shift counter
	addi	#31,d3
	
	clr.l	d6		;left->right counter
	move.l	#$80000000,d4	;mask
	move.l	d0,d5		;safe

.loop_first_1
	move.l	d5,d0		;copy back after each loop
	cmpi.l	#0,d3		;shift counter off?
	beq	.loop_first_1_max_end
	lsr.l	#1,d4
	subi	#1,d3		;decrement counter
	addi	#1,d6		;increment counter
	and.l	d4,d0		;is '1'?
	
	cmpi.l	#0,d0
	beq	.loop_first_1
	
	; d6 contains count to first '1'
	
	bra	.loop_first_1_end

.loop_first_1_max_end
	clr.l	d6	; clear d6 as the count is 0

.loop_first_1_end

	; d6 now contains the shift count to the first '1'
	; now calculate the number of bits to shift the mantisse to be within
	; its 23 bit boundary

	; if d6 = 0 there is nothing to shift and the int part is still 0
	cmpi.l	#0,d6
	beq	.build_new_exponent_end
	
	move.l	#32,d4
	sub.l	d6,d4
	subi.l	#23,d4	

	move.l	d5,d0		; restore original value
	and.l	#$80000000,d5	; safe sign

	move.l	d4,d3		; safe
.shift_mantisse	
	; check for shift left or right
	cmpi.l	#0,d4
	beq	.shift_end
	blt	.shift_left
.shift_right
	lsr.l	#1,d0
	subi.l	#1,d4
.shift_left
	lsl.l	#1,d0		; shift mantisse	
	addi.l	#1,d4
	bra	.shift_mantisse

.shift_end
	or.l	d5,d0		; restore sign

.build_new_exponent
	add.l	d3,d1		; new int part size
	move.l	#127,d2
	add.l	d1,d2
	moveq	#23,d6
	lsl.l	d6,d2		; shift 15 bits to left
	or.l	d2,d0	

.build_new_exponent_end
	move.l	d0,d7		; copy result
	
	movem.l	(sp)+,d0-d6

.norm_mantisse_end
	rts

