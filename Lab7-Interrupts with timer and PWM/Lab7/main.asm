;***********************************************************
;*
;*	main.asm
;*
;*	Implementing the timer/counter behavior for the Atmega 128 board
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Behnam Saeedi, Meagan Olsen
;*	   Date: 2/17/2016
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	IReg = r20
.def	IRegB = r21
.def	A = R17 ; General purpose register A
.def	B = R18 ; General purpose register B

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;-----------------------------------------------------------
;*	Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0002	
		rcall	ISI
		reti
.org	$0004
		rcall	ISD
		reti
.org	$0006
		rcall	ISMAX
		reti
.org	$0008
		rcall	ISMIN
		reti
.org	$0012
		rcall	TIM2_COMP
		reti
.org	$001E
		rcall	TIM0_COMP
		reti
				; End of Interrupt Vectors


.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)		; initialize Stack Pointer
		out		SPL, mpr			; Init the 2 stack pointer registers
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Configure I/O ports
		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low		

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize TekBot Forward Movement
		ldi		mpr, $00		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors

		; Initialize external interrupts
		; Set the Interrupt Sense Control to rising edge 
		ldi		mpr,(1<<ISC01)|(1<<ISC00)|(1<<ISC11)|(1<<ISC10)|(1<<ISC21)|(1<<ISC20)|(1<<ISC31)|(1<<ISC30)
		sts		EICRA,mpr
		; Configure the External Interrupt Mask
		ldi		mpr,(1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
		out		EIMSK,mpr

		; Configure 8-bit Timer/Counters

		; Initialize TCNT0
		sbi		DDRB, PB4 ; Set bit 4 of port B (OC0) for output
		ldi		mpr, 0b01101001 ; Activate Fast PWM mode, OC0 disconnected,
		out		TCCR0, mpr ; and set prescalar to 0 


		; Initialize TCNT2
		sbi		DDRB, PB7 ; Set bit 7 of port B (OC2/0C1C) for output
		ldi		mpr, 0b01101001 ; Activate Fast PWM mode, OC2 disconnected,
		out		TCCR2, mpr ; and set prescalar to 0

		; Setting the Mask for TIFR
		ldi		mpr, 0b10000010
		out		TIMSK, mpr

		; Set initial speed, display on Port B pins 3:0
		ldi		IReg, 0
		ldi		IRegB, 0

		; Enable global interrupts (if any are used)
		sei
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:	; The Main program
		ldi		mpr, $00
		clz
		cp		IReg,IRegB
		breq	NEXT
		rcall	SpeedSet		;replace with speed adjustment
NEXT:	
		rjmp	MAIN			; Create an infinite while loop to signify the 
						; end of the program.


;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; ISA:	Interrupt for speed increase
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
ISI:
		cli
		ldi		mpr,(1<<INTF0)
		out		EIFR,mpr
		ldi		mpr,0b00000000
		out		EIMSK,mpr
		

		cpi		IReg, $0F
		breq	skipISI
		inc		IReg
skipISI:
		ldi		mpr,(1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
		out		EIMSK,mpr
		ret
;-----------------------------------------------------------
; ISB:	Interrupt for speed decrease
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
ISD:
		cli
		ldi		mpr,(1<<INTF1)
		out		EIFR,mpr
		ldi		mpr,0b00000000
		out		EIMSK,mpr

		cpi		IReg, $00
		breq	skipISD
		dec		IReg
skipISD:
		ldi		mpr,(1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
		out		EIMSK,mpr
		ret
;-----------------------------------------------------------
; ISB:	Interrupt for maximum speed
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
ISMAX:
		cli
		ldi		mpr,(1<<INTF2)
		out		EIFR,mpr
		ldi		mpr,0b00000000
		out		EIMSK,mpr

		clr		IReg
		ldi		IReg,$0F

		ldi		mpr,(1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
		out		EIMSK,mpr
		ret
;-----------------------------------------------------------
; ISB:	Interrupt for minimum speed
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
ISMIN:
		cli
		ldi		mpr,(1<<INTF3)
		out		EIFR,mpr
		ldi		mpr,0b00000000
		out		EIMSK,mpr

		clr		IReg
		ldi		IReg,$00

		ldi		mpr,(1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
		out		EIMSK,mpr
		ret
;-----------------------------------------------------------
; TIM2_COMP:	Interrupt for timer comparing
; Desc:			This function is designed to get triggered by timer 2 as it is checking the flag
;-----------------------------------------------------------
TIM2_COMP:
		cli
		ret				; Return from subroutine
;-----------------------------------------------------------
; TIM0_COMP:	Interrupt for timer comparing
; Desc:			This function is designed to get triggered by timer 0 as it is checking the flag
;-----------------------------------------------------------
TIM0_COMP:
		cli
		ret				; Return from subroutine
;-----------------------------------------------------------
; SpeedSet:	set speed
; Desc:	This function is designed to set the speed of the motor by reading the value at IReg
;-----------------------------------------------------------
SpeedSet:
		cli
		push	mpr						; Save mpr register
		in	mpr, SREG					; Save program state
		push	mpr		
		push	IReg
		pop	IRegB
		push	IReg

		in		mpr,EIFR
		out		EIFR,mpr
		ldi		mpr,0b00000000
		out		EIMSK,mpr

		clz
		clr		A
		clr		B
		mov		A,IReg
		ldi		B,$11
		mul		A, B
		out		OCR0, r0
		out		OCR2, r0
		ldi		mpr, (0b00000000)
		cpi		IReg,$00
		breq	SIGOFF
		ldi		mpr, (0b01100000)
SIGOFF:
		add		mpr, IReg
		out		PORTB,mpr

		ldi		mpr,(1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
		out		EIMSK,mpr

		pop		IReg
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		mpr		; Restore mpr
		sei
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program





