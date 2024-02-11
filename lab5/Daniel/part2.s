/******************************************************************************
 * Write an interrupt service routine
 *****************************************************************************/
.section .exceptions, "ax"
IRQ_HANDLER:
        # save registers on the stack (et, ra, ea, others as needed)
        subi    sp, sp, 16          # make room on the stack
        stw     et, 0(sp)
        stw     ra, 4(sp)
        stw     r20, 8(sp)

        rdctl   et, ctl4            # read exception type
        beq     et, r0, SKIP_EA_DEC # not external?
        subi    ea, ea, 4           # decrement ea by 4 for external interrupts

SKIP_EA_DEC:
        stw     ea, 12(sp)
        andi    r20, et, 0x2        # check if interrupt is from pushbuttons
        beq     r20, r0, END_ISR # if not, ignore this interrupt
		
		subi sp,sp,20
		stw r8,(sp)
		stw r9,4(sp)
		stw r10,8(sp)
		stw r11,12(sp)
		stw r7,16(sp)
		
        call    KEY_ISR # if yes, call the pushbutton ISR
		
		ldw r8,(sp)
		ldw r9,4(sp)
		ldw r10,8(sp)
		ldw r11,12(sp)
		ldw r7,16(sp)
		addi sp,sp,20

END_ISR:
        ldw     et, 0(sp)           # restore registers
        ldw     ra, 4(sp)
        ldw     r20, 8(sp)
        ldw     ea, 12(sp)
        addi    sp, sp, 16          # restore stack pointer
        eret                        # return from exception

/*********************************************************************************
 * set where to go upon reset
 ********************************************************************************/
.section .reset, "ax"
        movia   r8, _start
        jmp    r8

/*********************************************************************************
 * Main program
 ********************************************************************************/
.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030
.equ KEYs, 0xff200050
.text
.global  _start
_start:
        /*
        1. Initialize the stack pointer
        2. set up keys to generate interrupts
        3. enable interrupts in NIOS II
        */
		
		movia sp,0x20000
		movia r8, KEYs
		movia r9, 0xf
		
		stwio r9,0xC(r8)
		stwio r9,8(r8)
		
		movia r9,0b10
		wrctl ctl3,r9
		
		movia r9,1
		wrctl ctl0,r9
		
		
IDLE:   br  IDLE


KEY_ISR:
	subi sp,sp,16
	stw r2,(sp)
	stw r4,4(sp)
	stw r5,8(sp)
	stw ra,12(sp)
	
	movia r8, KEYs
	movia r9,HEX_BASE1
	
	ldwio r10,0xC(r8)
	ldwio r11,(r9)
	
	srli r10,r10,1
	bne r10,r0,KEY_1
	andi r11,r11,0x7f
	
	beq r11,r0,disp_HEX0
	
	movia r4,0b10000
	mov r5,r0
	br disp
	
disp_HEX0:
	mov r4,r0
	mov r5,r0
	br disp
	
KEY_1:
	srli r10,r10,1
	bne r10,r0,KEY_2
	andi r11,r11,0x7f00
	
	beq r11,r0,disp_HEX1
	
	movia r4,0b10000
	movia r5,1
	br disp
	
disp_HEX1:
	movia r4,1
	movia r5,1
	br disp
	
KEY_2:
	srli r10,r10,1
	bne r10,r0,KEY_3
	srli r11,r11,16
	andi r11,r11,0x7f
	
	beq r11,r0,disp_HEX2
	
	movia r4,0b10000
	movia r5,2
	br disp
	
disp_HEX2:
	movia r4,2
	movia r5,2
	br disp
	
KEY_3:
	srli r11,r11,16
	andi r11,r11,0x7f00
	
	beq r11,r0,disp_HEX3
	
	movia r4,0b10000
	movia r5,3
	br disp
	
disp_HEX3:
	movia r4,3
	movia r5,3
	br disp
	
disp:
	subi sp,sp,16
	stw r8,(sp)
	stw r9,4(sp)
	stw r10,8(sp)
	stw r11,12(sp)

	call HEX_DISP
	
	ldw r8,(sp)
	ldw r9,4(sp)
	ldw r10,8(sp)
	ldw r11,12(sp)
	addi sp,sp,16
	
	movia r11,0xf
	stwio r11,12(r8)
	
	ldw r2,(sp)
	ldw r4,4(sp)
	ldw r5,8(sp)
	ldw ra,12(sp)
	addi sp,sp,16
	ret

HEX_DISP:   movia    r8, BIT_CODES         # starting address of the bit codes
	    andi     r6, r4, 0x10	   # get bit 4 of the input into r6
	    beq      r6, r0, not_blank 
	    mov      r2, r0
	    br       DO_DISP
not_blank:  andi     r4, r4, 0x0f	   # r4 is only 4-bit
            add      r4, r4, r8            # add the offset to the bit codes
            ldb      r2, 0(r4)             # index into the bit codes

#Display it on the target HEX display
DO_DISP:    
			movia    r8, HEX_BASE1         # load address
			movi     r6,  4
			blt      r5,r6, FIRST_SET      # hex4 and hex 5 are on 0xff200030
			sub      r5, r5, r6            # if hex4 or hex5, we need to adjust the shift
			addi     r8, r8, 0x0010        # we also need to adjust the address
FIRST_SET:
			slli     r5, r5, 3             # hex*8 shift is needed
			addi     r7, r0, 0xff          # create bit mask so other values are not corrupted
			sll      r7, r7, r5 
			addi     r4, r0, -1
			xor      r7, r7, r4  
    			sll      r4, r2, r5            # shift the hex code we want to write
			ldwio    r5, 0(r8)             # read current value       
			and      r5, r5, r7            # and it with the mask to clear the target hex
			or       r5, r5, r4	           # or with the hex code
			stwio    r5, 0(r8)		       # store back
END:			
			ret
			
BIT_CODES:  .byte     0b00111111, 0b00000110, 0b01011011, 0b01001111
			.byte     0b01100110, 0b01101101, 0b01111101, 0b00000111
			.byte     0b01111111, 0b01100111, 0b01110111, 0b01111100
			.byte     0b00111001, 0b01011110, 0b01111001, 0b01110001

            .end
			

