	; Copyright: Manfred Bergmann in 2018

	; Reverse of bin2dec to get displayable values back after
	; a float operation
	
	; d0: input, float value
	; d6: output, int part
	; d7: output, fraction part
	
bin2dec
	movem.l	d0-d5,-(sp)

	; extract length of int part from exponent
	
	clr.l	d6

.extract_exponent
	move.l	d0,d1
	andi.l	#$7f800000,d1	; mask out all but exp
	move.l	#23,d2
	lsr.l	d2,d1		; right align
	
	; if int part = 0
	cmpi.w	#0,d1
	beq	.extract_sign
	subi.w	#127,d1
	
	; d1 is now the size of int part
		
.extract_mantisse_int

	move.l	d0,d2		; copy
	andi.l	#$007fffff,d2	; mask out all but mantisse
	move.l	#23,d3
	sub.l	d1,d3		; what we figured out above (int part size)
	lsr.l	d3,d2		; right align
	move.l	d2,d6		; result
	
	; d6 now contains the int part
	
.extract_sign

	move.l	d0,d2		;copy
	andi.l	#$80000000,d2
	or.l	d2,d6
	
	; d6 is now with sign
	
.extract_fract_part

	; calculate how many fract bits we have
	moveq	#23,d2
	sub.l	d1,d2		; size of fract part already right aligned
	
	move.l	d0,d3		; copy
	move.l	#$007fffff,d4	; mask out all but fraction part
	lsr.l	d1,d4		; we don't want the int part
	and.l	d4,d3
	
	; d3 now contains fract part

	movem.l	d6,-(sp)	; save on stack so that we can use it here
	 
	clr.l	d7			; prepare output	
	clr.l	d1			; used for division remainder
	move.l	#1,d4		; divisor (1, 2, 4, 8, ... equivalent to 2^-1, 2^-2, 2^-4, ...)
.loop_fract
	subi.l	#1,d2		; d2 current bit to test for '1'
	lsl.l	#1,d4		; divisor - multiply by 2 on each loop
	cmpi.w	#0,d4		; loop end? if 0 we shifted out of the word boundary
	beq	.loop_fract_end

	btst.l	d2,d3		; if set we have to devide
	beq	.loop_fract		; no need to devide if 0
	move.l	#5000,d5	; we devide 5000
	add.l	d1,d5		; add remainder from previous calculation
	divu.w	d4,d5		; divide
	clr.l	d6			; clear for quotient
	add.w	d5,d6		; copy lower 16 bit of the division result (the quotient)
	lsl.l	#1,d6		; *2
	add.l	d6,d7		; accumulate the quotient
	and.l	#$ffff0000,d5	; the new remainder
	move.l	#16,d1		; number of bits to shift remainder word
	lsr.l	d1,d5		; shift
	move.l	d5,d1		; copy new remainder
	bra	.loop_fract

.loop_fract_end

	movem.l	(sp)+,d6	; get from stack
	movem.l	(sp)+,d0-d5
	rts
								