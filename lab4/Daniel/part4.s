.global _start
.equ LEDs,0xff200000
.equ KEYs,0xff200050
.equ TIMER, 0xff202000
.equ DELAY, 1000000

_start:
	movia r8, LEDs #sets r8, r9, r10 equal to LED, KEYs, and TIMER addresses
	movia r9, KEYs
	movia r10, TIMER
	
	movia r11,DELAY #sets r11 to delay value needed for 4Hz counter
	srli r11,r11,16 #stores highorder bits of r11 into correct timer reg
	stwio r11,12(r10)
	movia r11,DELAY 
	andi r11,r11,0x0000ffff #stores low order bits of r11 into correct timer reg
	stwio r11,8(r10)
	
	movia r11, 0b0110 #sets timer to continuos and starts it
	stwio r11,4(r10)
	
	mov r13,r0 #resets r13 and r14
	mov r14,r0
	
	mov r15,r0
	stwio r15,(r8) #resets r15 and loads it into LEDs
	
	loop:
		ldwio r12,(r9) #checks if any buttons are actively pressed
		bne r12,r0,pause
		ldwio r12,12(r9) #checks if any button presses were missed
		bne r12,r0,pause
		
		ldwio r12,(r10) #polls T0 to check if 0.25 seconds have passed
		slli r12,r12,31 #isolates T0
		bne r12,r0,hundredthsecond #checks if T0 flag was raised
		
		br loop
		
	hundredthsecond:
		stwio r0,(r10) #resets T0
		
		addi r13, r13, 1 #increments huundredth of a second counter
		
		movia r12, 100 #checks if seconds counter needs to be updated
		beq r12,r13, second
		
		br update_display #branches to update the display
		
	second:
		addi r14,r14, 1 #increments seconds counter
		
		mov r13,r0 #resets hundredths of a second counter
		
		movia r12,9 #checks if entire clock needs to be reset
		beq r12,r14, reset
		
		br update_display
		
	update_display:
		slli r15,r14,7 #stores the seconds value into the bit 7 to bit 10
		add r15,r15,r13 #add the hundredths of a second value to the first 7 bits of reg 15
		stwio r15, (r8) #display the seconds and 1/100 on LEDs
		br loop
		
	pause:
		movia r11, 0b1010 #pauses timer
		stwio r11,4(r10)
		ldwio r12,(r9) #checks to make sure key is released
		bne r12,r0, pause
		movia r12,0xf #reset edge capture reg
		stwio r12,12(r9)
		
	play:
		ldwio r12,12(r9) #checks edgecapture for button release
		beq r12,r0, play
		movia r12,0xf #reset edge capture reg
		stwio r12,12(r9)
		movia r11, 0b0110 #restarts the timer
		stwio r11,4(r10)
		br loop #continues the counter loop
		
	reset:
		mov r14,r0 #resets seconds reg
		stwio r14,(r8) #resets LEDs
		br loop
		
		
		
	