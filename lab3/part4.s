.text
/* Program to Count the number of 1's and Zeroes in a sequence of 32-bit words,
and determines the largest of each */

.global _start
_start:

	/* Your code here  */
	
	movia r12, LargestOnes
	movia r13, LargestZeroes
	movia r8, TEST_NUM
	movia r5, 0xffffffff
	
	mainpos:
		ldw r4, (r8)
		beq r4, r0, resetpointer
		mov r2, r0
		
		call ones
		
		ldw r14, (r12)
		addi r8, r8, 4
		
		bgt r2, r14, storepos
		br mainpos
	resetpointer:
		movia r8, TEST_NUM
	mainneg:
		ldw r4, (r8)
		beq r4, r0, ledsetup
		xor r4, r4, r5 /* flip all bits */
		mov r2, r0
		
		call ones
		
		ldw r14, (r13)
		addi r8, r8, 4
		
		bgt r2, r14, storeneg
		br mainneg
	storepos:
		stw r2, (r12)
		br mainpos
	storeneg:
		stw r2, (r13)
		br mainneg

ledsetup:
	.equ    LEDs, 0xFF200000
	movia r25, LEDs
	movia r5, 0x0300000
	ldw r14, (r12)
	ldw r15, (r13)
endiloop:
	movia r8, 0x00000000
    stwio r14, (r25)
	call waitsubroutine
	movia r8, 0x00000000
	stwio r15, (r25)
	call waitsubroutine
	br endiloop

waitsubroutine:
	
	beq r8, r5, finishedloop
	addi r8, r8, 1
	br waitsubroutine
	finishedloop:
		ret

ones:
	
	onesloop:
		beq r4, r0, finished /* We are done when everything is zero */

		slli r11, r4, 31 /* get just LSB from r9 */
		cmpne r11, r11, r0 /* if it is not zero r11 is 1*/
		add r2, r2, r11 /* incr. r10 by r11 */

		srli r4, r4, 1 /* rotate value right by one bit */
		br onesloop /* go again */

	finished:
		ret

.data
TEST_NUM:  .word 0x4a01fead, 0xF677D671,0xDC9758D5,0xEBBD45D2,0x8059519D
            .word 0x76D8F0D2, 0xB98C9BB5, 0xD7EC3A9E, 0xD9BADC01, 0x89B377CD
            .word 0  # end of list 

LargestOnes: .word 0
LargestZeroes: .word 0
