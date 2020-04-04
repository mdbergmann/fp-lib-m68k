	; Copyright: Manfred Bergmann in 2018

; --------------------------------------
; Extracts the mantisse bits, the sign and the integer part size
; 
; d7 => output sign and mantisse bits
; d6 => output size of int part
; d0 => input as of dec2bin

extract_num_info
	movem.l	d0-d5,-(sp)
	move.l	d0,d1				;copy
	andi.l	#$7F800000,d1		;exponent
	andi.l	#$807fffff,d0		;sign + mantisse
	moveq	#23,d2
	lsr.l	d2,d1				;right align

	cmpi	#0,d1
	beq	.end

	subi	#127,d1
		
.end
	move.l	d1,d6
	move.l	d0,d7
	movem.l	(sp)+,d0-d5
	
	rts
