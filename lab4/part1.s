.global _start
_start:
	
	.equ KEY_BASE, 0xFF200050
	.equ LED_BASE, 0xFF200000
	
	movia r8, KEY_BASE
	movia r10, LED_BASE
	
	movia r4, 1
	call checkipoll
		
	movia r11, 1
	stwio r11, 0(r10)
	
	movia r4, 14
	mov r7, r0
	mov r15, r11
	
	pollfunctions:
	
		ldwio r6, 0(r8)
		and r6, r6, r4
		
		call checki # Will encode necessary actions into its return, r2
		
		mov r5, r2
		mov r2, r15
		mov r7, r6
		
		call calcnew
		
		mov r15, r2
		stwio r15, 0(r10)
		
		br pollfunctions
	.equ MAX, 0xe # We only add if we are below or at here
	.equ MIN, 0x2 # We only sub if we are below or at here
	
checkipoll:
	pollon: # Poll KEYi in r4
		ldwio r9, 0(r8)
		and r9, r9, r4
		beq r9, r0, pollon
	polloff:
		ldwio r9, 0(r8)
		and r9, r9, r4
		bne r9, r0, polloff
		ret
		
checki:

	# r6 is current state
	# r7 is previous state
	mov r2, r0
	c1:
		andi r9, r7, 2
		beq r9, r0, c2
		andi r11, r6, 2
		beq r9, r11, c2
		addi r2, r2, 2
	c2:
		andi r9, r7, 4
		beq r9, r0, c3 
		andi r11, r6, 4
		beq r9, r11, c3
		addi r2, r2, 4
	c3:
		andi r9, r7, 8
		beq r9, r0, returnc
		andi r11, r6, 8
		beq r9, r11, returnc
		addi r2, r2, 8
	returnc:
		ret
	
calcnew:
	
	movia r12, MAX
	movia r13, MIN
	ldwio r11, 0(r10)
	
	d1:
		andi r9, r5, 2
		beq r9, r0, d2
		mov r14, r12
		bgt r11, r14, d2
		addi r2, r2, 1
	d2:
		andi r9, r5, 4
		beq r9, r0, d3 
		mov r14, r13
		beq r2, r0, s1
		blt r11, r14, d3
		subi r2, r2, 1
	d3:
		andi r9, r5, 8
		beq r9, r0, returnd
		mov r2, r0
	returnd:
		ret
	s1:
		addi r2, r2, 1
		br returnd
	

	
	
	
	