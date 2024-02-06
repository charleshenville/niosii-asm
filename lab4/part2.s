.global _start
_start:
	
	.equ KEY_EDGE, 0xFF20005C
	.equ LED_BASE, 0xFF200000
	.equ COUNTER_DELAY, 50000
	.equ MAX, 0xff
	
	movia r9, KEY_EDGE
	movia r10, LED_BASE
	movia r13, MAX
	movia r7, 0xf
	mov r12, r0 ## Current counter value
	
	stop:
		call edge_check
		bne r2, r0, go
		br stop
	go:
		call delay_subroutine
		beq r13, r12, rst
		addi r12, r12, 1
		br cnt
		rst:
			mov r12, r0
		cnt:
			stwio r12, 0(r10)
			call edge_check
			bne r2, r0, stop
			br go
	
edge_check:
	
	ldwio r8, 0(r9)
	and r8, r8, r7
	beq r8, r0, assignlow
	assignhigh:
		movia r2, 1
		stwio r7, 0(r9)
		ret
	assignlow:
		mov r2, r0
		ret

delay_subroutine:
	movia r8, COUNTER_DELAY
	SUB_LOOP:
		subi r8, r8, 1
		bne r8, r0, SUB_LOOP
		ret