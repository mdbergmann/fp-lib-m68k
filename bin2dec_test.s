	; Copyright: Manfred Bergmann in 2018
	; test code for bin2dec
	;
	
	; test number in float
	move.l	#%01000001111000111001100110011001,d0	; exp: 4, 12,4500

	bsr	bin2dec

	cmpi.l	#12,d6
	bne	error
	
	cmpi.l	#4500,d7
	bne	error

	moveq	#0,d0		;success	
	illegal

error
	moveq	#1,d0		;error
	illegal

	;include
	;
	include	"bin2dec.i"
	