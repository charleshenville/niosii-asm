.text
/* Program to Count the number of 1’s in a 32-bit word,
located at InputWord */
.global _start
_start:
/* Your code here  */

	movia r8, InputWord
	ldw r4, (r8)
	mov r2, r0
	call ones
	stw r2, (r8)

endiloop: br endiloop
ones:
	

	mainloop:
		beq r4, r0, finished /* We are done when everything is zero */

		slli r11, r4, 31 /* get just LSB from r9 */
		cmpne r11, r11, r0 /* if it is not zero r11 is 1*/
		add r2, r2, r11 /* incr. r10 by r11 */

		srli r4, r4, 1 /* rotate value right by one bit */
		br mainloop /* go again */

	finished:
		movia r8, Answer
		ret

.data
InputWord: .word 0x4a01fead
Answer: .word 0