<h2>Developing a Floating Point library in m68k assembler on Amiga</h2>


<h3>Part 1 - some theory</h3>

Someone told me lately: "If you haven't developed a floating-point library, go home and do it. It's a nice weekend project."

I followed this advice. The Amiga offers a number of programming languages, including C/C++ and more high level languages like Pascal or Oberon, and some Basic dialects like AMOS, BlitzBasic and others.  
But I thought assembler would be nice. The Motorola 68000 series is a very nice assembler.  
I do know it from my old Amiga times. But never really did a lot with it. So I‘m not an expert in assembler. Hence the assembler code introduced here might not be efficient or optimised.

So, while I was away on vacation I've developed this using pen-and-paper and only later wrote and tested it on one of my Amigas.  
I took the assembler specs with me as print-out and studied them while developing the code.

I must say, it took longer than a weekend. :) But it was a great experience.

(I'm posting the full assembler source code at the end of the post.)  
It was developed using the 'DevPac' assembler. A well known macro assembler for the Amiga.)

Let me first write a little about the theory of floating-point numbers.  
But I'm assuming that you know what 'floating-point' numbers are.

One of the floating point standards is IEEE 754.  
It standardises how the number is represented in memory/CPU registers and how it is calculated.  
IEEE 754 is a single-precision 32 bit standard.  
The binary representation is defined as (from high bit to to low bit):  
- 1 bit for the sign (-/+)  
- 8 bit for the exponent  
- 23 bit for the mantissa

The sign is pretty clear, it says whether the number is positive or negative.

The 8 bit exponent basically encodes the 'floating-point' shift value to the left and right.  
Shifting to the left means that a negative exponent has to be encoded.
Shifting to the right a positive.  
In order to encode positive and negative values in 8 bit a so called 'biased-representation' is used. With an ‚excess‘ value of 127 it's possible to encode numbers (and exponents) from -126 to 127.

The 23 bit mantissa combines the integer part of the floating-point number and the fraction part.

The integer part in the mantissa can go through a 'normalisation' process, which means that the first '1' in a binary form of the number matters. And everything before that is ignored, considering the number is in a 32 bit register.  
So only the bits from the first '1' to the end of the number are taken into the mantissa.  
The 'hidden bit' assumes that there is always a '1' as the first bit of a number.  
So that IEEE 754 says that this first '1' does not need to be stored, hence saving one bit for the precision of the fraction part.

Let's take the number 12.45.  
In binary it is: `1100,00101101`  
The left side of the comma, the integer part has a binary value definition of:  
`1100` = `1*2^8 + 1*2^4 + 0*2^2 + 0*2^1`  
The fraction part, right side of the comma:  
`00101101` = `0*2^-2 + 0*2^-4 + 1*2^-8 + 0*2^-16 ...`  

That is how it would be stored in the mantissa.  
Considering the 'hidden bit', the left bit of the integer part does not need to be stored. Hence there is one bit more available to store the fraction part.  
Later, when the number must be converted back into decimal it is important to know the bit size of the integer part (positive exponent), or in case the integer part is 0, how many digits were shifted right to the first 1 bit of the fraction part (negative exponent).


There is more to it, read upon it here if you want: <a href=„https://en.wikipedia.org/wiki/IEEE_754“ target=„_blank“ class=„link“>Wikipedia-IEEE_754</a>



<h3>Part 2 - the implementation - dec2bin (decimal to binary)</h3>

We make a few slight simplifications to the IEEE 754 standard so that this implementation is not fully compliant.  
- the 'hidden bit' is not hidden :)  
- no normalisation, which means we don't have negative exponents, because we don't look into the delivered fraction part for the first '1'.

Now, how does it work in practice to get a decimal number into the computer as IEEE 754 representation.  
The library that is developed here assumes that the integer part (left side of the comma) and the fraction part (right side of the comma) is delivered in separate CPU registers. Because we do not have a ‚float‘ number type where this could be delivered in a combined way.  
It would certainly work to use one register, the upper word for integer part and the lower word for the fraction part. 16 bit for each, that would in many cases fully suffice. But for simplicity, lets take separate registers.

Say, the number is: `12.45`.  
Then `12` (including the sign) would be delivered in register d0.  
The fraction part, `45` in d1.  
The binary floating point number output will be delivered back in register d7.

Converting the integer part into binary form is pretty trivial. We just copy the value `12` into a register and that's it. The CPU does the decimal to binary conversion for us automatically, because the number consists only of positive powers of two. Hence, the input register d0 already contains the binary representation of the number `12`.

As next step we have to calculate the bit length of that number because it is later stored in the exponent.  
The algorithm is to shift the register d0 to left bit-by-bit until register bit 32 is a ‚1‘. We need to count how many times we shifted.  
Subtracting that shift-count from 32 (the bit length of the register) will give as result the bit length of the integer value.

Here is the assembler code for that:

```
	; d0 copied to d6
	; if int_part (d6) = 0 then no need to do anything
	cmpi.l	#0,d6
	beq	.loop_count_int_bits_end
	
	; now shift left until we find the first 1
	; counter in d2
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
```

In register d2 is the result, the bit length of the integer part.

The fraction part is a little more tricky. Bringing it into a binary form requires some thought.  
Effectively the fraction part bit values in binary form is (right of the comma): `2^-2, 2^-4, 2^-8, 2^-16, ...`  
We setup the convention that the fraction value must use 4 digits. `45` then will be expanded to `4500`.  
4 digits is not that much but it suffices for this proof-of-concept.

I found that an algorithm that translates the fraction into binary form depends on the number of digits.  
The algorithm is as follows (assuming a 4 digit fraction part):

1. fraction part > 5000?  
2. if yes then mark a '1' and subtract 5000  
3. if no then mark a '0'  
4. shift 1 bit to left  
(shifting left means multiplication by factor 2)  
5. repeat

This loop can be repeated until there are no more bits in the fraction part.
Or, the loop only repeats for the number of „free“ fraction bits left in the mantissa.  
Remember, we have 23 bits for the mantissa. From those we need some to store the integer part. The rest is used for the fraction part.

The threshold value, 5000 here, depends on the number of digits of the fraction part.  
If the number of digits is 1 the threshold is 5.  
If the number of digits are 2 the threshold is 50.  
And so forth.  
(5 * (if nDigits > 1 then 10 * nDigits else 1))

Here is the code to convert the fraction into binary value:

```
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
```

The above code positions the fraction bit directly into the output register d7. And only so many bits are generated as there is space available in the mantissa.

Now we have the mantissa complete.

What's missing is the exponent.  
We know the size of the integer part, it is saved in register d2.  
That must now be encoded into the exponent.  
What we do is add the integer part bit size to 127, the 'excess' value, and write the 8 bits at the right position of the output regster d7:

```
	; at this point we have the mantissa complete
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
```

Notice, there is a special case. If the integer part is 0, delivered in d0, then we’ll make the exponent 0, too.


*The test*

That's basically it for the decimal to binary operation.  
The output register d7 contains the floating point number.

Test code for that is straight forward.  
The dec2bin operation is coded as a subroutine in a separate source file.
We can now easily create a test source file and include the dec2bin routine.  
Like so:

```
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
```

The test code compares the subroutine output with a manually setup binary number that we expect.  
Is the comparison OK a 1 is written in register d3.  
Otherwise a 0.


<h3>Part 3 - the implementation - bin2dec (binary to decimal)</h3>

We want to convert back from the binary float number to the decimal representation with the integer part (with sign) and the fraction part in separate output registers.  
And we want to assert that we get back what we initially put in.

In register d0 we expect the floating point number as input.  
In d6 will be the integer part output.  
In d7 the fraction part output.

Let's start extracting the exponent, because we need to get the integer part bit length that is encoded there.

We'll make a copy of the input register where we operate on, because we mask out everything but the exponent bits.  
Then we'll right align those and subtract 127 (the 'excess').  
The result is the integer part bit length.  
However, if the exponent is 0 we can skip this part.

```
.extract_exponent
	move.l	d0,d1
	andi.l	#$7f800000,d1	; mask out all but exp
	move.l	#23,d2
	lsr.l	d2,d1			; right align
	
	; if int part = 0
	cmpi.w	#0,d1
	beq	.extract_sign
	subi.w	#127,d1
	
	; d1 is now the size of int part
```

As next step we'll extract the integer part bits.  
Again we make a copy of the input register.  
Then we mask out all but the mantissa, 23 bits.  
It is already right aligned, but we want to shift out all the fraction bits until only the integer bits are in this register.  
Finally we can already copy this to the output register d6.

```
.extract_mantisse_int
	move.l	d0,d2		; copy
	andi.l	#$007fffff,d2	; mask out all but mantisse
	move.l	#23,d3
	sub.l	d1,d3		; what we figured out above (int part size)
	lsr.l	d3,d2		; right align
	move.l	d2,d6		; result
	
	; d6 now contains the int part
```

We also have to extract the sign bit and merge it with the integer part in register d6.

As next important and more tricky step is converting back the fraction part of the mantissa into a decimal representation.  
Basically it is the opposite operation of above.

First we have to extract the mantissa bits again, similarly as we did in the last step.

What do the '1' bits in the fraction mantissa represent?  
Effectively they represent the value 5000 (in our case of 4 digits) for each '1' we have.  
Considering the fraction bit values for the positions right side of the comma: `2^-2, 2^-4, 2^-8, ...`

I.e.: assuming those bits: `11001` the fraction value is: `1/2 + 1/4 + 1/32 = ,78125`

Now, if each '1' represents 5000 we have the following: `5000/2 + 5000/4 + 5000/32`  
But that's not all. We have to add the remainder of each division in the next step, and we have to multiply the quotient by 2 to get back to our initial input.

Here is the code:

```
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
```

If we look at the `divu.w` operation, it only allows a denominator of 16 bit length and we only use a denominator of powers of 2.  
Effectively that is our precision limit.  
Even if we had more fraction bits in the mantissa we couldn't actually use them to accumulate the result.  
So we have some precision loss.

Let's add a test case.

```
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
```

Since we have now both operations, we can use dec2bin and bin2dec in combination.

We provide input for dec2bin, then let the result run through bin2dec and compare original input to the output.

I must say that there is indeed a precision loss.
The last (fourth) digit can be off up-to 5, so we have a precision loss of up-to 5 thousandth.

That can clearly be improved.
But for this little project this result is acceptable.


In the next „parts“ I'd like to implement operations for addition, subtraction, division and multiplication.  
Also rounding, ceil and floor operatiuons could be implemented.
The foundation is in place now.
