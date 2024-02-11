.global _start
.equ LEDs,0xff200000
.equ KEYs,0xff200050
.equ TIMER, 0xff202000
.equ DELAY, 25000000

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
	
	mov r13,r0 #resets r13 and loads it into LEDs
	stwio r13,(r8)
	
	
	loop:
		ldwio r12,(r9) #checks if any buttons are actively pressed
		bne r12,r0,pause
		ldwio r12,12(r9) #checks if any button presses were missed
		bne r12,r0,pause
		
		ldwio r12,(r10) #polls T0 to check if 0.25 seconds have passed
		slli r12,r12,31 #isolates T0
		beq r12,r0,loop #checks if T0 flag was raised, if not repeat
		
		stwio r0,(r10) #resets T0
		movia r12,255 #checks if r13/LEDs are at max value
		beq r13,r12,reset
		
		addi r13,r13,1 #increments r13
		stwio r13,(r8) #updates LEDs to show new r13 value
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
		mov r13,r0 #resets r13
		stwio r13,(r8) #resets LEDs
		br loop
	