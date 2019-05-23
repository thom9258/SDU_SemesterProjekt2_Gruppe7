.INCLUDE "m32adef.inc"

.ORG 0x00
	RJMP	SETUP
	
.ORG 0x02 
	RJMP	MAALINTERRUPT

.ORG 0x06
	RJMP	HJULINTERRUPT

.ORG 0x2A


	.DEF AdcReg = R17
	.DEF CompReg = R18
	.DEF StraightReg = R19
	.DEF CurveReg = R20
	.DEF SendReg = R21
	.DEF FastDrive = R22
	.DEF SlowDrive = R23

	.DEF MaalReg = R24
	.DEF DistReg = R25
	.DEF PushAmountRegL = R28
	.DEF PushAmountRegH = R29

; UPPER AND LOWER THRESHOLDS RELATIVE TO ADC OUTPUT TO CHECK FOR TURNS
	.EQU LowT = 70
	.EQU HighT = 200


; -------------------------------------------------------SETUP START-------------------------------------------------------
	SETUP:
	LDI	FastDrive, 140
	LDI	SlowDrive, 60

; RESET REGISTERS
	LDI SendReg, 0
	LDI AdcReg, 0
	LDI CompReg, 0
	LDI StraightReg, 0
	LDI CurveReg, 0
	LDI MaalReg, 0
	LDI DistReg, 0
	LDI PushAmountRegL, 0
	LDI PushAmountRegH, 0

; STACK POINTER SETUP
	LDI		R16,	HIGH(RAMEND)
	OUT		SPH,	R16
	LDI		R16,	LOW(RAMEND)
	OUT		SPL,	R16

; QUEUE STACK POINTER
	LDI		XH,		HIGH(RAMEND)	; XH = R27
	LDI		XL,		LOW(RAMEND)		; XL = R26
	
; U2X SETUP (DOUBLE SPEED) (COMMUNICATION)
	LDI		R16,	0b00000010
	OUT		UCSRA,	R16	

; TURN ON SERIEL COMMUNICATION TRANSMITTER AND RECIEVE
	LDI		R16,	(1<<RXEN)|(1<<TXEN)
	OUT		UCSRB,	R16

; USE UCSRC, SET FRAME SIZE = 8
	LDI		R16,	(1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
	OUT		UCSRC,	R16

; SET BAUD RATE = 9600 
	LDI		R16,	12		
	OUT		UBRRL,	R16

; ADC SETUP
	LDI		R16,	0b01000000
	OUT		DDRA,	R16

	LDI R16,		0b11100001		; INTERN REF VOLTAGE, AUTO TRIGGER ON, SAVES 8 MSB BITS, READ FROM PA1
	OUT ADMUX,		R16

	LDI R16,		0b11100011		; ENABLE ADC, START ADC, AUTOTRIGGER ON, PRESCALER = 1/8 TO KEEP ADC CLOCK UNDER 200 KHZ
	OUT ADCSR,		R16				

	
; ENABLE HARDWARE INTERRUPTS
	LDI R16, (1<<INT0) | (1<<INT2)
	OUT GICR, R16
	
; PWM SETUP
	LDI R16, 0b01100001		; PHASE CORRECT, NON INVERTING, PRESCALER = 1 
	OUT TCCR2, R16
	
	MOV R16, SlowDrive
	OUT	OCR2, R16 
	
; PORT D SETUP TO PWM SIGNAL (PD7) AND INTERRUPT (PD2)
	LDI R16, 0b11111011
	OUT DDRD, R16
	OUT PORTD, R16

; SETUP TO INT0. INT0 ACTIVATES WHEN GOING FROM HIGH TO LOW (FALLING EDGE)
	LDI R16, (1 << ISC01)
	OUT MCUCR, R16

; ENABLE GLOBAL INTERRUPTS
	SEI

	RJMP MAINRUNDE0

; -------------------------------- HJULINTERRUPT -----------------------------------------------------
HJULINTERRUPT:
; IF DistReg != 0 : --DistReg
	LDI CompReg, 0
	CPSE DistReg, CompReg ; COMPARE SKIP IF EQUAL
	DEC DistReg

; BRANCH TO HJULINTERRUPT2, IF MaalReg = 1
	CPI MaalReg, 1
	BREQ HJULINTERRUPT2
	RETI

	HJULINTERRUPT2: 
		; READ FROM ADC
		CLR CompReg
		IN AdcReg, ADCL
		IN AdcReg, ADCH
		ORI AdcReg, 0b00011111
		LDI R16, 0b00011111
		EOR AdcReg, R16

; THIS CODE CHECKS IF ADC OUTPUT IS HIGHER OR LOWER THAN CHOSEN VALUES, MEANING WE ARE TURNING
	; STADIE1 (TURN)
	LDI CompReg, LowT		
	CP AdcReg, CompReg		
	BRLO STADIE1			; BRANCH IF LOWER THAN

	CLR CompReg
	LDI CompReg, HighT		
	CP AdcReg, CompReg		
	BRSH STADIE1			; BRANCH IF HIGHER OR EQUAL TO

; IF THE VALUE IN AdcReg GOES THROUGH BOTH TEST CASES WITHOUT BRANCHING, THEN IT MEANS WE ARE GOING STRAIGHT
	; STADIE2 (GOING STRAIGHT)
	RJMP STADIE2

	STADIE1: ; WHEN TURNING
	INC	CurveReg
	RETI

	STADIE2: ; WHEN GOING STRAIGHT
	INC StraightReg
	RETI


; -------------------------------- MAALINTERRUPT -----------------------------------------------------
MAALINTERRUPT:
	INC MaalReg
	RETI

; -------------------------------- MAINRUNDE0 --------------------------------------------------------
MAINRUNDE0:
	CPI	MaalReg, 1
	BREQ MAINRUNDE1

	RJMP MAINRUNDE0

; -------------------------------- MAINRUNDE1 --------------------------------------------------------
MAINRUNDE1:
; PWM IS SET TO 100 FOR BETTER ADC OUTPUT
	LDI R16, 100
	OUT	OCR2, R16

	CPI	MaalReg, 2
	BRSH MAINRUNDEPREX

; IF StraightReg != 0 GO TO CURVEPUSH
	CPI	StraightReg, 0
	BRNE CURVEPUSH
	
; IF CurveReg != 0 GO TO STRAIGHTPUSH
	CPI	CurveReg, 0
	BRNE STRAIGHTPUSH

; ELSE JUMP TO MAINRUNDE1
	RJMP MAINRUNDE1

	STRAIGHTPUSH:
	; IF TURN GO TO MAINRUNDE1 
		LDI CompReg, LowT		
		CP AdcReg, CompReg		
		BRLO MAINRUNDE1			; BRANCH IF LOWER THAN

		CLR CompReg
		LDI CompReg, HighT		
		CP AdcReg, CompReg		
		BRSH MAINRUNDE1			; BRANCH IF HIGHER THAN OR EQUAL TO

	; IF NOT TURN PUSH StraightReg TO QUEUE
		LDI R16, (1 << PA6)
		OUT PORTA, R16

		PUSH	StraightReg

		CLR		StraightReg
		ADIW	PushAmountRegH:PushAmountRegL, 1
		RJMP	MAINRUNDE1

	CURVEPUSH:
	; IF TURN BRANCH TO CURVEPUSH2 
		LDI CompReg, LowT		
		CP AdcReg, CompReg		
		BRLO CURVEPUSH2			; BRANCH IF LOWER THAN

		CLR CompReg
		LDI CompReg, HighT		
		CP AdcReg, CompReg		; COMPARES ComReg REGISTER WITH ADC OUTPUT REGISTER
		BRSH CURVEPUSH2
		
		RJMP MAINRUNDE1

	; ELLERS PUSHER VI CurveReg PÅ QUEUEN
		CURVEPUSH2:
		SBIS UCSRA, 5

		PUSH	CurveReg
		CLR		CurveReg
		ADIW	PushAmountRegH:PushAmountRegL, 1
		RJMP	MAINRUNDE1
		
; -------------------------------- MAINRUNDEPREX -----------------------------------------------------
MAINRUNDEPREX:
	MOV R16, FastDrive
	OUT OCR2, R16
	RJMP MAINRUNDEX

; -------------------------------- MAINRUNDEX --------------------------------------------------------
MAINRUNDEX:
	LDI R16, 5
	OUT UDR, R16

;CALL DEQUEUE IF DistReg = 0 
	CPI		DistReg, 0
	BREQ	DEQUEUE
	BACKFROMDEQUEUE:
	RJMP	MAINRUNDEX

; -------------------------------- DEQUEUE --------------------------------------------------------
DEQUEUE:
; IF DEQUEUE, CHANGE PWM SIGNAL
	IN CompReg, OCR2
	CP CompReg, FastDrive
	BREQ SETSLOW

	CP CompReg, SlowDrive
	BREQ SETFAST
	
	RETURNDEQUEUE:

	LD		DistReg, X
	OUT		UDR, DistReg

	SUBI	XL, 1
	SBCI	XH, 0 
	
;IF  XL,XH  <  PUSHAMOUNTREG - RAMEND; GOTO RESET DEQUEUE
	SUBI	PushAmountRegL, LOW(RAMEND)
	SBCI	PushAmountRegH, HIGH(RAMEND)

	CP		XL, PushAmountRegL
	CPC		XH, PushAmountRegH
	BRLO	RESETDEQUEUE

	RJMP	BACKFROMDEQUEUE

	RESETDEQUEUE:
		LDI XL, LOW(RAMEND)
		LDI XH, HIGH(RAMEND)
		RJMP MAINRUNDEX


	SETFAST:
		MOV R16, FastDrive
		OUT OCR2, R16
		RJMP RETURNDEQUEUE


	SETSLOW:
		MOV R16, SlowDrive
		OUT OCR2, R16
		RJMP RETURNDEQUEUE
