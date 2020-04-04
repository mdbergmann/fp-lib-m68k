	; Copyright: Manfred Bergmann in 2018

	; test code for binutils_number_normalize
	;
	
	; following is test code that is not executed when calling the subroutine
	move.l	#%00000000001100000000000000000000,d0	; number to be normalized
	move.l	#3,d1					; the previous int part size

	bsr	norm_mantisse

	cmpi.l	#%01000000111000000000000000000000,d7
	bne	error
	
	moveq	#0,d3		;success	
	illegal

error
	moveq	#1,d3		;error
	illegal

	;include
	;
	include	"binutils_number_norma.i"
	