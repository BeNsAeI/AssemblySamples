;***********************************************************
;*
;*	main.asm
;*
;*	Implementing the controller for the remotely operated vehicle 
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
.def	EXECUTED = r20			; Holds the address for checking
.def	DATA = r21				; holds data to be sent to Port B 
.def	DATAB= r22				; Data BackupCheck

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)							;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))			;0b11001000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;-----------------------------------------------------------
;*	Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

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

		; empty registers 
		clr		DATA
		clr		DATAB
		clr		EXECUTED

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

		;USART1
		ldi		mpr, (1<<PD3)	 ; Set Port D pin 2 (RXD0) for input
		out		DDRE, mpr 		; and Port D pin 3 (TXD0) for output

		; Set baud rate at 2400
		ldi		mpr, high(832)		; Load high byte of 0x0340
		sts		UBRR1H, mpr 	; UBRR1H in extended I/O space
		ldi		mpr, low(832) 		; Load low byte of 0x0340
		sts		UBRR1L, mpr             ; UBRR1L in extended I/O space

		ldi		mpr,(1<<U2X1)
		sts		UCSR1A,mpr
		; Set frame format: 8 data, 2 stop bits, asynchronous
		ldi		mpr, (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
		sts		UCSR1C, mpr ; UCSR0C in extended I/O space

		; Enable both receiver and transmitter, and receive interrupt
		ldi		mpr, (0<<RXEN1 | 1<<TXEN1 | 0<<RXCIE1)
		sts		UCSR1B, mpr

		; Enable global interrupts (if any are used)
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:	; The Main program
		;Pulling
		clr		mpr
		
		in		mpr,PIND
		cpi		mpr,0b01111111
		breq	CFWD
		

		cpi		mpr,0b10111111
		breq	CBWD
		

		cpi		mpr,0b11011111
		breq	CRWD
		

		cpi		mpr,0b11101111
		breq	CLWD
		

		cpi		mpr,0b11111101
		breq	CHALTI
		

		cpi		mpr,0b11111110
		breq	CFUTURE
		
		rjmp	CONTINUE

CFWD:
		rcall	FWD
		rjmp	CONTINUE
CBWD:
		rcall	BWD
		rjmp	CONTINUE
CRWD:
		rcall	RWD
		rjmp	CONTINUE
CLWD:
		rcall	LWD
		rjmp	CONTINUE
CHALTI:
		rcall	HALTI
		rjmp	CONTINUE
CFUTURE:
		rcall	FUTURE
		rjmp	CONTINUE
CONTINUE:
		;End of Pulling
		cpi		EXECUTED,$00
		breq	NEXT
		push	DATA
		ldi		DATA,0b11101101
		rcall	USART_Transmit		;replace with speed adjustment-
		pop		DATA
		rcall	USART_Transmit

NEXT:	
		out		PORTB,DATA
		rjmp	MAIN			; Create an infinite while loop to signify the 
						; end of the program.


;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; FWD:	Interrupt for speed increase
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
FWD:
		clz
		push	mpr
		
		ldi		DATA, MovFwd
		ldi		EXECUTED, $01

		pop		mpr
		ret
;-----------------------------------------------------------
; BWD:	Interrupt for speed decrease
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
BWD:
		clz
		push	mpr

		ldi		DATA, MovBck
		ldi		EXECUTED, $01

		pop		mpr
		ret
;-----------------------------------------------------------
; RWD:	Interrupt for maximum speed
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
RWD:
		clz
		push	mpr

		ldi		DATA,TurnR
		ldi		EXECUTED, $01

		pop		mpr
		ret
;-----------------------------------------------------------
; LWD:	Interrupt for minimum speed
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
LWD:
		clz
		push	mpr

		ldi		DATA,TurnL
		ldi		EXECUTED, $01

		pop		mpr
		ret
;-----------------------------------------------------------
; HALTI:	Interrupt for minimum speed
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
HALTI:
		clz
		push	mpr

		ldi		DATA,Halt
		ldi		EXECUTED, $01

		pop		mpr
		ret
;-----------------------------------------------------------
; FUTURE:	Interrupt for minimum speed
; Desc:	This function is designed to get triggered by press of the interrupt button for speed adjustment
;-----------------------------------------------------------
FUTURE:
		clz
		push	mpr

		ldi		DATA,0b11111000
		ldi		EXECUTED, $01

		pop		mpr
		ret
;-----------------------------------------------------------
; USART_Transmit:	send Data
; Desc:	This value sonds the value of data
;-----------------------------------------------------------
USART_Transmit:
		clz
		push	mpr
		clr		mpr
		clr		EXECUTED
USART_Transmit_Step:
		lds		mpr,UCSR1A
		sbrs	mpr, UDRE1 ; Loop until UDR1 is empty
		rjmp	USART_Transmit_Step
		sts		UDR1, DATA ; Move data to transmit data buffer

		pop		mpr
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program