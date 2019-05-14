.include "m32adef.inc"

.org	0x00
	rjmp	SETUP

.org 0x06
	rjmp	HjulInterrupt

.org 0x08
	rjmp	MaalInterrupt

.org	0x2A



	.def AdcReg = R17
	.def CompReg = R18
	.def straightReg = R19
	.def curveReg = R20
	.def sendReg = R21
	.def fastDrive = R22
	.def slowDrive = R23
	.def maalReg = R24

	; IKKE BRUG R26 og 27
	ldi	fastDrive, 130
	ldi	slowDrive, 75

	.equ lowT = 55
	.equ highT = 125

	; -------------------------------------------------------SETUP START
	
	SETUP:
	LDI sendReg, 0

	; Stack pointer setup
	LDI		R16,	HIGH(RAMEND)
	OUT		SPH,	R16
	LDI		R16,	LOW(RAMEND)
	OUT		SPL,	R16

	; Queue stack pointer
	LDI		XH,		HIGH(RAMEND)	; XH = r27
	LDI		XL,		LOW(RAMEND)		; XL = r26
	
	;U2X setup (double speed) (Kommunikation)
	LDI		R16,	0b00000010
	OUT		UCSRA,	R16	


	;Slå seriel kommunikation og recieve interrupts til
	LDI		R16,	(1<<RXEN)|(1<<TXEN)
	OUT		UCSRB,	R16

	;Brug UCSRC, sæt frame size = 8
	LDI		R16,	(1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
	OUT		UCSRC,	R16

	;Sæt baud rate = 9600 
	LDI		R16,	12		;UBRR LSB
	OUT		UBRRL,	R16

	
	; ADC Setup

	;porta setup til ADC
	ldi		r16,	0x00
	out		ddra,	r16

	LDI R16, 0b11100001		; intern ref spænding, auto trigger til, gemmer 8 msb bits, læs fra PA1
	OUT ADMUX, R16

	LDI R16, 0b11100011		; enable adc, start adc, autotrigger, prescaler på 1/8
	OUT ADCSR, R16			; vi bruger en prescaler på 1/8 for at holde den under dens ADC converterns maksimale clock frekvens på 200 kHz

	
	; enable alle hardware interrupts
	LDI R16, (1<<INT0) | (1<<INT1) | (1<<INT2)
	OUT GICR, R16
	


	; PWM opsætning
	ldi r16, 0b01100001		; phase korrekt, non inverterende, prescaler på 1 
	out tccr2, r16

	MOV R16, slowDrive

	out	OCR2, R16 
	; port d setup

	ldi R16, 0xFF
	OUT ddrd, R16
	Out PORTD, R16
	SEI
	rjmp MAINRUNDE0


HjulInterrupt:
	CLR CompReg
	IN AdcReg, ADCL
	IN AdcReg, ADCH

	; this code checks if adc input is higher or lower than chosen values, meaning we are turning
	; stadie 1 (dreje)
	LDI CompReg, lowT		; inserts 89 into compare register
	CP ADCReg, CompReg		; compares compare register with adc input register
	BRLO Stadie1			; branch if adcReg < compReg

	CLR CompReg
	LDI CompReg, highT		; inserts 165 into compare register
	CP AdcReg, CompReg		; compares compare register with adc input register
	BRSH Stadie1			; branch if adcReg >= compReg

	; if the value in adcreg goes through both test cases without beanching, then it means we are going straight
	; stadie 2 (lige ud)
	RJMP Stadie2

	Stadie1: ; when turning
	INC	curveReg
	RETI

	Stadie2: ; when going straight
	INC straightReg
	RETI

; -------------------------------- MaalInterrupt --------------------------------------------------------
MaalInterrupt:
	inc maalReg
	RETI

; -------------------------------- MAINRUNDE0 --------------------------------------------------------
MAINRUNDE0:
	CPI	maalREG, 1
	BREQ MAINRUNDE1

	RJMP MAINRUNDE0

; -------------------------------- MAINRUNDE1 --------------------------------------------------------
MAINRUNDE1:
	CPI	maalREG, 2
	BRSH MAINRUNDEX
	; Hvis straightReg != 0, så brancher vi til curvePUSH
	CPI	straightReg, 0
	BRNE curvePUSH
	

	; Hvis curveReg != 0, så brancher vi til straightPUSH
	CPI	curveReg, 0
	BRNE straightPUSH

	; Ellers tilbage til MAINRUNDE1
	RJMP MAINRUNDE1

	straightPUSH:
	; Tjekker om vi er i sving, hvis vi er brancher vi til MAINRUNDE1
		LDI CompReg, lowT		; inserts lowT into compare register
		CP ADCReg, CompReg		; compares compare register with adc input register
		BRLO MAINRUNDE1			; branch if adcReg < compReg

		CLR CompReg
		LDI CompReg, highT		; inserts highT into compare register
		CP AdcReg, CompReg		; compares compare register with adc input register
		BRSH MAINRUNDE1

		; Hvis vi ikke drejer pusher vi vores straightReg til Queuen/stack
		PUSH	straightReg
		clr		straightReg
		RJMP	MAINRUNDE1

	curvePUSH:
	; Tjekker om vi drejer, hvis vi drejer brancher vi til curvePUSH2
		LDI CompReg, lowT		; inserts lowT into compare register
		CP ADCReg, CompReg		; compares compare register with adc input register
		BRLO curvePUSH2			; branch if adcReg < compReg

	; Tjekker om vi drejer, hvis vi drejer brancher vi til curvePUSH2
		CLR CompReg
		LDI CompReg, highT		; inserts highT into compare register
		CP AdcReg, CompReg		; compares compare register with adc input register
		BRSH curvePUSH2
		
		rjmp MAINRUNDE1

		; ellers pusher vi curveReg på Queuen
		curvePUSH2:
		PUSH	curveReg
		clr		curveReg
		rjmp	MAINRUNDE1

; -------------------------------- MAINRUNDEX --------------------------------------------------------
MAINRUNDEX:

	RJMP MAINRUNDEX

