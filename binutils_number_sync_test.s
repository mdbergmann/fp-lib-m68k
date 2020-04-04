	; Copyright: Manfred Bergmann in 2018

	; test code for binutils_number_sync
	;

	move.l	#%01000001110100000000000000000000,d0	; smaller number, exp 1, '1000'
	move.l	#%01000010010100000000000000000000,d1	; larger number, exp 2,  '10000'

	bsr	synchronize_numbers

	cmpi.l	#%00000000001010000000000000000000,d0
	bne	error
	
	cmpi.l	#%00000000010100000000000000000000,d1
	bne	error

	moveq	#0,d7		;success	
	illegal

error
	moveq	#1,d7		;error
	illegal

	;include
	;
	include	"binutils_number_sync.i"
	
