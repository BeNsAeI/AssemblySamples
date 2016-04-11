.include "m128def.inc"			; Include definition file

.def	mpr = r16				; Multipurpose register

.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	WTime = 100				; Time to wait in wait loop

.cseg							; beginning of code segment


.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt



.org	$0046					; end of interrupt vectors

INIT:
		; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)		; initialize Stack Pointer
		out		SPL, mpr			; Init the 2 stack pointer registers
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low		

		ldi		mpr, $FF		;
		out		PORTB, mpr		;

MAIN:	; The Main program

		ldi		mpr, $FF		;
		out		PORTB, mpr		;		
		rcall	Wait
		ldi		mpr, $00		;
		out		PORTB, mpr		;
		rcall	Wait
		rjmp	MAIN			; Create an infinite while loop to signify the 

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------

Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

