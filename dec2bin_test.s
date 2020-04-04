	; Copyright: Manfred Bergmann in 2018

	; dec2bin test code
	
	move.l	#12,d0		; integer part => 1010
	move.l	#4500,d1	; fract part
	
	; subroutine expects d0, d1 to be filled
	; result: the IEEE 754 number is in d7
	bsr	dec2bin

	move.l	#%01000001111000111001100110011001,d3	; this what we expect
	cmp.l	d3,d7
	beq	assert_pass
	
	move.l	#1,d3
	bra	assert_end
	
assert_pass
	move.l	#0,d3
	
assert_end
	illegal

		
	;include
	;
	include	"dec2bin.i"
