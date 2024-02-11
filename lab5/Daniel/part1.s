/*    Subroutine to display a four-bit quantity as a hex digits (from 0 to F) 
      on one of the six HEX 7-segment displays on the DE1_SoC.
*
 *    Parameters: the low-order 4 bits of register r4 contain the digit to be displayed
		  if bit 4 of r4 is a one, then the display should be blanked
 *    		  the low order 3 bits of r5 say which HEX display number 0-5 to put the digit on
 *    Returns: r2 = bit patterm that is written to HEX display
 */

.global _start
.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030
.equ TIMER, 0xff202000
.equ LEDs, 0xff200000
.equ DELAY, 25000000

_start:
	movia sp, 0x20000

	movia r8, LEDs
	movia r9, TIMER
	movia r10, DELAY
	stwio r0,(r9)
	
	srli r10,r10,16 #store DELAY value into respective counters
	stwio r10,0xC(r9)
	movia r10,DELAY
	andi r10,r10,0xffff
	stwio r10,0x8(r9)
	
	movia r10, 0b110 #set timer to run and continuous
	stwio r10,0x4(r9)
	
	mov r11, r0 #reset r11 nad r12
	mov r12, r0
	
	loop:
		ldwio r10,(r9) #poll TO
		andi r10,r10,1
		bne r10,r0,update_display
		br loop
	
	update_display:
		stwio r0,(r9) #push r8,r9,r11,r12 onto stack
		subi sp,sp,16
		stw r8,(sp)
		stw r9,4(sp)
		stw r11,8(sp)
		stw r12,12(sp)
		mov r4,r11
		mov r5,r12
		
		call HEX_DISP #update HEX displays
		
		ldw r12,12(sp) #pull r8,r9,r11,r12 from stack
		ldw r11,8(sp)
		ldw r9,4(sp)
		ldw r8,(sp)
		addi sp,sp,16
		
		stwio r2,(r8) #load return value of HEX_DISP onto LEDs
		
		addi r11,r11,1 #increment r11
		
		movia r10, 0b10001 #check r11 for over value
		beq r10,r11, reset_count
		br loop
	
	reset_count:
		mov r11, r0
		
		addi r12,r12,1
		
		movia r10, 6 #check r12 for over value
		beq r12,r10, reset_display
		br loop
		
	reset_display:
		mov r12,r0
		br loop
		
	
	


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
			
