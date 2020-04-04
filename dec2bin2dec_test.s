	; Copyright: Manfred Bergmann in 2018

	; test code for dec2bin2dec
	;
	
	move.l	#12345,d0		; integer part => 1010
	move.l	#5001,d1	; fract part
	
	; subroutine expects d0, d1 to be filled
	; result: the IEEE 754 number is in d7
	bsr	dec2bin

	move.l	d7,d0		; input for the back conversion
		
	bsr	bin2dec

	cmpi.l	#12345,d6
	bne	error
	
	cmpi.l	#5001,d7
	bne	error

	moveq	#0,d0		;success	
	illegal

error
	moveq	#1,d0		;error
	illegal
	
	
	include	"dec2bin.i"
	include "bin2dec.i"
	