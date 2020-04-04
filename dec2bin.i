	; Copyright: Manfred Bergmann in 2018

	; -------------------------------
	; dec2bin
    ; input:
    ; d0: integer part of number + sign
    ; d1: fraction part of number
	; -------------------------------
dec2bin
	movem.l	d0-d6,-(sp)	; safe regs
	
	; copy sign
.copy_sign
	move.l	d0,d7
	rol.l	#1,d7
	andi.l	#1,d7
	ror.l	#1,d7
.copy_sign_end

	move.l	d0,d6		; copy d0
	
	; copy integer part to the dest register at the right place => bit 10 -> 32
	clr.l	d2		; counter
	and.l	#$7fffffff,d6	; remove sign
	
	; if int_part (d) = 0 then no need to do anything
	cmpi.l	#0,d6
	beq	.loop_count_int_bits_end
	
	; now shift left until we find the first 1
.loop_count_int_bits
	btst.l	#$1f,d6		; bit 32 set?
	bne.s	.loop_count_int_bits_done
	addq	#1,d2		; inc counter
	lsl.l	#1,d6
	bra	.loop_count_int_bits

.loop_count_int_bits_done

	move.l	#32,d3
	sub.l	d2,d3		; 32 - 1. bit of int
	move.l	d3,d2

.loop_count_int_bits_end

	; in d2 we now have the bit size of the int part
	; now this must be copied to our mantisse bits and normalized

	; now shift bits to right position in d0 in order to then OR them over to d7
	; start in d7 = bit 10 (from left)
	; or 23 (from right)
	
	move.l	#23,d3
	sub.l	d2,d3
	
	move.l	d0,d6		; we still need d0
	
	; d3 now contains the number of bits to shift left
	lsl.l	d3,d6
	; now d0 is in the right position
	or.l	d6,d7

	; the integer part is now in the result register d7
	; d0 still contains the source integer value
	; d2 contains the bit size of the int part

	; now prepare fraction in d1

.prepare_fract_bits

	; the algorithm is to:
	; check if d1 > 5000 (4 digits)
	; if yes -> mark '1' and substract 5000
	; if no  -> mark '0'
	; shift left (times 2)
	; repeat until no more available bits in mantisse, which here is d3
	
	move.l	#5000,d4	; threshold
.loop_fract_bits
	subi.l	#1,d3		; d3 is position of where to set the bit that represents 5000
	clr.l	d6
	cmp.l	d4,d1	
	blt	.fract_under_threshold
	sub.l	d4,d1
	bset	d3,d6
.fract_under_threshold
	or.l	d6,d7
	lsl.l	#1,d1		; d1 * 2
	cmpi.l	#0,d3		; are we done?
	bgt	.loop_fract_bits	

.prepare_fract_bits_end

	; at this point we have the mantisse complete
	; d0 still holds the source integer part
	; d2 still holds the exp. data (int part size, which is 0 for d0 = 0 because we don't hide the 'hidden bit')
	; d7 is the result register
	; all other registers may be used freely
	
	; if d0 = 0 goto end
	cmpi.l	#0,d0
	beq	.prepare_exp_bits_end
	
.prepare_exp_bits
	; Excess = 127
	move.l	#127,d0		; we don't need d0 any longer
	add.l	d2,d0		; size of int part on top of excess
	move.l	#23,d3
	lsl.l	d3,d0		; shift into right position
	or.l	d0,d7
			
.prepare_exp_bits_end		
	movem.l	(sp)+,d0-d6
	rts	
	
