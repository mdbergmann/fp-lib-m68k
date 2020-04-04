	; Copyright: Manfred Bergmann in 2018
	
	; binutils utilities
	; 
	;
	; test code
	
	move.l	d0,-(sp)
	move.l	#%01000001110010000000000000000000,d0
	bsr	extract_num_info
	cmpi.l	#4,d6
	bne	error
	cmpi.l	#%00000000010010000000000000000000,d7
	bne	error
	
	moveq	#0,d7		; success
	illegal
	
error	move.l	(sp)+,d0
	moveq	#1,d7		; error
	illegal


	;include
	;
	include "binutils_number_info.i"
