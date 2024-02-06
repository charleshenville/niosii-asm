.text
/* Program to Count the number of 1’s in a 32-bit word,
located at InputWord */
.global _start
_start:
/* Your code here  */

	movia r8, InputWord
	ldw r9, (r8)
	mov r10, r0

mainloop:
	beq r9, r0, finished /* We are done when everything is zero */
	
	slli r11, r9, 31 /* get just LSB from r9 */
	cmpne r11, r11, r0 /* if it is not zero r11 is 1*/
	add r10, r10, r11 /* incr. r10 by r11 */
	
	srli r9, r9, 1 /* rotate value right by one bit */
	br mainloop /* go again */

finished:
	movia r8, Answer
	stw r10, (r8)
endiloop: br endiloop
.data
InputWord: .word 0x4a01fead
Answer: .word 0