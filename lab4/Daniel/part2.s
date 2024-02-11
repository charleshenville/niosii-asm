.global _start
.equ LEDs,0xff200000
.equ KEYs,0xff200050
.equ DELAY, 10000000

_start:
	movia r8, LEDs #stores LEDs and KEY addresses into r8 and r9 respectively
	movia r9, KEYs
	mov r10,r0 #resets r10
	stwio r10,(r8) #resets LEDs
	
	add_delay:
		movia r11, DELAY #sets r11 to delay value
		movia r12, 256 #checks if r10 needs to be reset (i.e. r10 == 256)
		beq r10,r12, reset
	loop:
		ldwio r12,(r9) #checks if any buttons are actively pressed
		bne r12,r0,pause
		ldwio r12,12(r9) #checks if any button presses were missed
		bne r12,r0,pause
		
		subi r11,r11,1 #subs one from delay counter
		bne r11,r0,loop
		
		stwio r10,(r8) #updates LEDs 
		addi r10,r10,1 #incremenst r10 count
		
		br add_delay #loops to reset delay counter
		
	pause:
		ldwio r12,(r9) #checks to make sure key is released
		bne r12,r0, pause
		movia r12,0xf #resets edgecapture reg
		stwio r12,12(r9)
		
	play:
		ldwio r12,12(r9) #checks edgecapture for button release
		beq r12,r0, play
		movia r12,0xf #resets edge capture reg
		stwio r12,12(r9)
		
		br loop #continues delay loop
		
	reset:
		mov r10,r0 #resets r10 to 0
		br loop
	