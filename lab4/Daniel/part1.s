.global _start

.equ LEDs, 0xff200000
.equ KEYs, 0xff200050
_start:

	movia r8,LEDs #loads address of LEDs into r8
	movia r9,KEYs #loads address of KEYs into r9
	mov r10,r0 #clears r10
	
	check_keys:
		ldwio r10,(r9) #loads current key presses into r10
		beq r10,r0,check_keys #checks if any keys are pressed, if not check again
		
		srli r10,r10,1 #checks if key0 is pressed
		beq r10,r0,KEY0
		
		srli r10,r10,1 #checks if key1 is pressed
		beq r10,r0,KEY1
		
		srli r10,r10,1 #checks if key2 is pressed
		beq r10,r0,KEY2
		
		srli r10,r10,1 #checks if key3 is pressed
		beq r10,r0,KEY3
		
		br check_keys
		
	KEY0:
		movia r11,1 
		stwio r11,(r8) #stores 1 into LEDs
		br empty_keys
		
	KEY1:
		ldwio r10,(r8)
		movia r11,15
		beq r10,r11,empty_keys #checks whether LEDs is already displaying 15
		
		addi r10,r10,1 #adds one to value dispalyed on LEDs
		stwio r10,(r8)
		br empty_keys
		
	KEY2:
		ldwio r10,(r8) 
		movia r11,1
		beq r10,r11,empty_keys #checks whether LEDs is already displaying 1
		beq r10,r0,KEY0 #displays 1 if LEDs are displaying 0 (KEY3 functionality)
		
		subi r10,r10,1 #subs one from values on LEDs
		stwio r10,(r8)
		br empty_keys
	
	KEY3:
		stwio r0,(r8) #resets value on LEDs
		br empty_keys
		
	empty_keys:
		ldwio r10,(r9)
		beq r10,r0, check_keys #checks if keys were released
		br empty_keys
	
	