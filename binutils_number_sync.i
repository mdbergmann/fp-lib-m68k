	; Copyright: Manfred Bergmann in 2018

	; Synchronize numbers utility
	;
	; This subroutine synchronizes the mantisses of both numbers
	; depending on the exponent.
	; 
	; The shifting happens for the number that has the smaller exponent, 
	; hence the smaller number.
	; 
	; input:
	; d0: number 1 (dec2bin)
	; d1: number 2 (dec2bin)
	;
	; output:
	; d0: the shifted (synchronized number)
	; d1: the other, as is number	
    ;
    ; import: binutils_number_info.i => 'extract_num_info' subroutine
	
synchronize_numbers

	movem.l	d2-d7,-(sp)	; save registers
	
	bsr	extract_num_info
	
	move.l	d6,d4
	move.l	d7,d5
	
	move.l	d1,d0	;awaiting this here
	bsr 	extract_num_info
	
	; d4-d7 now contain number infos; d4,d6 size info

	move.l	d4,d3	; safe	

	sub.l	d6,d4
	cmpi.l	#0,d4
	
	blt	.second_number_smaller
	move.l	d7,d1
	move.l	d5,d0
	
	bra	.synchronize_mantisse

.second_number_smaller
	; we have a negative value in d4
	; make the substraction the other way around to geta positive value
	move.l	d6,d4
	sub.l	d3,d4

	move.l	d5,d1
	move.l	d7,d0
	
.synchronize_mantisse
	lsr.l	d4,d0		; shift the diff to right
	
	; d0 now contains the shifted
	; d1 the other
	
.end
	movem.l	(sp)+,d2-d7
	
	rts

	; includes subroutine
	include	"binutils_number_info.i"
		
