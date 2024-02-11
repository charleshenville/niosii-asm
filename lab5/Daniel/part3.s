.equ LEDs, 0xff200000
.equ KEYs, 0xff200050
.equ TIMER, 0xff202000
.equ DELAY, 25000000
/******************************************************************************
 * Write an interrupt service routine
 *****************************************************************************/
.section .exceptions, "ax"
IRQ_HANDLER:
# save registers on the stack (et, ra, ea, others as needed) 
	subi sp, sp, 28 # make room on the stack
	stw et, 0(sp)
	stw ra, 4(sp)
	stw r20, 8(sp)
	stw r4, 12(sp)
	stw r5, 16(sp)
	stw r6,20(sp)
	
	rdctl et, ctl4 # read exception type 
	beq et, r0, SKIP_EA_DEC # not external?
	subi ea, ea, 4 # decrement ea by 4 for external interrupts
	
SKIP_EA_DEC:
	stw     ea, 24(sp)
	andi    r20, et, 0x2 # check if interrupt is from pushbuttons
	beq     r20, r0, TIMER_CHECK # if not, go to check timer
	
	subi sp,sp,8 #push r8,r9 onto stack
	stw r8,(sp)
	stw r9,4(sp)
	
	movia r4,KEYs #load address of keys as parameter
	movia r5,RUN
	call    KEY_ISR # if yes, call the pushbutton ISR
	
	ldw r8,(sp)#pop r8,r9 off stack
	ldw r9,4(sp)
	addi sp,sp,8
	
TIMER_CHECK:
	andi r20, et, 0x1 #check if interrupt is from timer
	beq r20,r0, END_ISR #if not, ignore interrupt
	
	subi sp,sp,8 #push r8,r9 onto stack
	stw r8,(sp)
	stw r9,4(sp)
	
	movia r4,TIMER #load address of timner as parameter
	movia r5,COUNT
	movia r6,RUN
	call    TIMER_ISR # if yes, call the timer ISR
	
	ldw r8,(sp)#pop r8,r9 off stack
	ldw r9,4(sp)
	addi sp,sp,8
	
END_ISR:
	ldw     et, 0(sp) # restore registers
	ldw     ra, 4(sp)
	ldw     r20, 8(sp)
	ldw r4,12(sp)
	ldw r5,16(sp)
	ldw r6,20(sp)
	ldw     ea, 24(sp)
	addi    sp, sp, 28 # restore stack pointer
	eret  # return from exception
/*********************************************************************************
 * set where to go upon reset
 ********************************************************************************/
.section .reset, "ax"
	movia   r8, _start
	jmp r8 
/*********************************************************************************
 * Main program
 ********************************************************************************/
.text
.global  _start
_start:
	movia sp, 0x20000
	
	movia r4, KEYs #pass KEYs address as parameter to CONFIG_KEYS
	call CONFIG_KEYS
	
	movia r4, TIMER #pass TIMER address as parameter to CONFIG_TIMER
	movia r5, DELAY
	call CONFIG_TIMER
	
	movia r8,0b11 #enbale timer 1 and button interupts
	wrctl ctl3,r8
	
	movia r8,0b1 #enable processor interuptions
	wrctl ctl0,r8

	movia r8,COUNT	
	stw r0,(r8)
	
	movia r8,RUN
	stw r0,(r8)

	movia r8,LEDs
	movia r9,COUNT
	movia r10,RUN
	
IDLE:
	ldw r11,(r9)
	stwio r11,(r8)
	br IDLE

CONFIG_KEYS:
	movia r8, 0xf
	stwio r8, 0xC(r4) #reset KEYs edge capture
	stwio r8, 8(r4) #turns on interrupt mask register for all KEYs
	
	ret
	
CONFIG_TIMER:
	stwio r0,(r4) #reset T0
	
	srli r8,r5,16 #store upper 16 bits of timer count
	stwio r8,0xC(r4)
	
	andi r8,r5,0xffff #store lower 16 bits of timer count
	stwio r8,8(r4)
	
	movia r8, 0b0111 #set timer to start, cont, and allow interrupts
	stwio r8,4(r4) 
	
	ret
	
KEY_ISR:
	movia r8,0xf
	stwio r8,0xC(r4)
	
	ldw r8,(r5)
	xori r8,r8,1
	stw r8,(r5)
	ret
	
TIMER_ISR:
	mov r8,r0 #reset TO
	stwio r8,(r4)
	
	ldw r8,(r5) #load count
	ldw r9,(r6) #loud run
	
	add r8,r8,r9 #sum and store count
	stw r8,(r5)
	
	ret
	
COUNT: .word 0
RUN: .word 0