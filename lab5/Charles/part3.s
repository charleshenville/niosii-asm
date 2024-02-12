.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030
.equ TIMER_BASE, 0xFF202000
.equ KEY_BASE, 0xff200050
.equ LED_BASE, 0xff200000
.section .exceptions, "ax"
IRQ_HANDLER:
        # save registers on the stack (et, ra, ea, others as needed)
        subi    sp, sp, 32          # make room on the stack
        stw     et, 0(sp)
        stw     ra, 4(sp)
        stw     r4, 8(sp)
		stw     r5, 16(sp)
		stw		r8, 20(sp)
		stw		r9, 24(sp)
		stw		r10, 28(sp)

        rdctl   et, ctl4            # read exception type
        beq     et, r0, SKIP_EA_DEC # not external?
        subi    ea, ea, 4           # decrement ea by 4 for external interrupts

SKIP_EA_DEC:
        stw     ea, 12(sp)
        andi    r10, et, 0x2        # check if interrupt is from pushbuttons
        bne     r10, r0, keycall
		andi    r10, et, 0x1
		bne     r10, r0, timercall	# check if interrupt is from timer
		br 		END_ISR # Otherwise Ignore
		keycall:
			call    KEY_ISR 
			br 		END_ISR
		timercall:
			call    TIMER_ISR

END_ISR:
        ldw     et, 0(sp)           # restore registers
        ldw     ra, 4(sp)
        ldw     r4, 8(sp)
        ldw     ea, 12(sp)
		ldw     r5, 16(sp)
		ldw     r8, 20(sp)
		ldw     r9, 24(sp)
		ldw     r10, 28(sp)
        addi    sp, sp, 32          # restore stack pointer
        eret                        # return from exception
TIMER_ISR:
		movia r8, COUNT
		ldw r8, (r8)
		movia r9, RUN
		ldw r9, (r9)
		add r10, r8, r9
		movia r8, COUNT
		stw r10, (r8)
		
		movia r8, TIMER_BASE
		movi r10, 1
		stwio r10, 0(r8) # Reset Timer Done
		ret
		
KEY_ISR:
		movia r9, KEY_BASE
		ldwio r8, 12(r9) # Capture EDGE
		movi r10, 0xf
		and r8, r8, r10
		stwio r8, 12(r9) # Reset EDGE
		movia r9, RUN
		ldw r9,(r9)
		andi r9, r9, 1
		beq r9, r0, sethigh
		mov r8, r0
		br alldone
		sethigh: movi r8, 1
		alldone:
			movia r9, RUN
			stw r8, (r9)
			ret

.text
.global  _start
_start:
    /* Set up stack pointer */
	movia sp, 0x20000
	movi r4, 1
	
    call    CONFIG_TIMER        # configure the Timer
    call    CONFIG_KEYS         # configure the KEYs port
    /* Enable interrupts in the NIOS-II processor */
	
	wrctl ctl0, r4
	movi r4, 3
	wrctl ctl3, r4
	
    movia   r8, LED_BASE        # LEDR base address (0xFF200000)
    movia   r9, COUNT           # global variable
LOOP:
    ldw     r10, 0(r9)          # global variable
    stwio   r10, 0(r8)          # write to the LEDR lights
    br      LOOP

CONFIG_TIMER:
# Set up the timer
	movia r8, TIMER_BASE
	mov r9, r0
	addi r9, r9, 2
	stwio r9, (r8)
	movia r9, 0x7840
	stwio r9, 8(r8)
	movia r9, 0x017D
	stwio r9, 12(r8) # 25 MILLION CYCLES
	movia r9, 7
	stwio r9, 4(r8)
	ret
	
CONFIG_KEYS:
# Set up the keys
	movia r8, KEY_BASE
	stwio r4, 12(r8)
	movi r9, 0xf
	stwio r9, 8(r8)
	ret
	
.data
/* Global variables */
.global  COUNT
COUNT:  .word    0x0            # used by timer

.global  RUN                    # used by pushbutton KEYs
RUN:    .word    0x1            # initial value to increment COUNT

.end