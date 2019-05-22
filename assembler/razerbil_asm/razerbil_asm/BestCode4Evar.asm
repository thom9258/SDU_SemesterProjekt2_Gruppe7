.include "m32adef.inc"

.org	0x00
	rjmp	SETUP
	
.org 0x02 ; er ændret fra 0x8 til 0x2 fordi der ikke er interrupt på 0x8
	rjmp	MaalInterrupt

.org 0x06
	rjmp	HjulInterrupt

.org	0x2A



	.def AdcReg = R17
	.def CompReg = R18
	.def straightReg = R19
	.def curveReg = R20
	.def sendReg = R21
	.def fastDrive = R22
	.def slowDrive = R23


	.def maalReg = R24
	.def distReg = R25
	.def pushAmountRegL = R28
	.def pushAmountRegH = R29



	.equ lowT = 70
	.equ highT = 200

	; -------------------------------------------------------SETUP START
	
	SETUP:
	; IKKE BRUG R26 og 27
	ldi	fastDrive, 140
	ldi	slowDrive, 60
	LDI sendReg, 0

	ldi AdcReg, 0
	ldi CompReg, 0
	ldi straightReg, 0
	ldi curveReg, 0
	ldi maalReg, 0
	ldi distReg, 0
	ldi pushAmountRegL, 0
	ldi pushAmountRegH, 0



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


	;Slå seriel kommunikation transmitter og recieve til
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
	ldi		r16,	0b01000000
	out		ddra,	r16

	LDI R16, 0b11100001		; intern ref spænding, auto trigger til, gemmer 8 msb bits, læs fra PA1
	OUT ADMUX, R16

	LDI R16, 0b11100011		; enable adc, start adc, autotrigger, prescaler på 1/8
	OUT ADCSR, R16			; vi bruger en prescaler på 1/8 for at holde den under dens ADC converterns maksimale clock frekvens på 200 kHz

	
	; enable hardware interrupts
	LDI R16, (1<<INT0) | (1<<INT2)
	OUT GICR, R16
	

	; PWM opsætning
	ldi r16, 0b01100001		; phase korrekt, non inverterende, prescaler på 1 
	out tccr2, r16
	
	;ldi r16, slowDrive
	MOV r16, slowDrive
	out	OCR2, R16 
	;call delay_nsec
	
	; port d setup

	ldi R16, 0b11111011
	OUT ddrd, R16
	Out PORTD, R16

	ldi r16, (1 << ISC01)
	out mcucr, r16

	SEI

	rjmp MAINRUNDE0

;Delay, opladning af kondensator
/*DELAY_NSEC:					; For CLK(CPU) = 1 MHz
    LDI     r16,   5*8		; this is n*8 so n is the amount of seconds for the delay
Delay1:
    LDI     r18,   125		; One clock cycle
Delay2:
    LDI     r19,   250      ; One clock cycle
Delay3:
    DEC     r19             ; One clock cycle
    NOP                     ; One clock cycle
    BRNE    Delay3          ; Two clock cycles when jumping to Delay3, 1 clock when continuing to DEC

    DEC     r18             ; One clock cycle
    BRNE    Delay2          ; Two clock cycles when jumping to Delay2, 1 clock when continuing to DEC

    DEC     r16             ; One clock Cycle
    BRNE    Delay1          ; Two clock cycles when jumping to Delay1, 1 clock when continuing to RET*/

HjulInterrupt:
	;if disreg != 0; distreg--
	ldi CompReg, 0
	cpse distReg, CompReg ; compare skip if equal
	dec distReg

	cpi maalReg, 1
	breq HjulInterrupt2
	reti

HjulInterrupt2: ;------------------indlæs fra adc------------------
	CLR CompReg
	IN AdcReg, ADCL
	IN AdcReg, ADCH
	ori AdcReg, 0b00011111
	ldi r16, 0b00011111
	eor AdcReg, r16

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
	;OUT UDR, maalReg	
	RETI

; -------------------------------- MAINRUNDE0 --------------------------------------------------------

MAINRUNDE0:
	CPI	maalREG, 1
	BREQ MAINRUNDE1

	RJMP MAINRUNDE0

; -------------------------------- MAINRUNDE1 --------------------------------------------------------
MAINRUNDE1:

	; SKAL MÅSKE SENDE NOGET TIL COMPUTEREN FOR TEST FORMÅL
	ldi r16, 100
	out	ocr2, r16

/*vent:
sbic	UCSRA,	5	;skip hvis der der ikke er nooget i UDR
rjmp	vent*/

	CPI	maalREG, 2
	BRSH mainrundePreX

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
		ldi r16, (1 << pa6)
		out porta, r16

		;out udr, straightReg
		PUSH	straightReg
		;out udr, straightReg
		clr		straightReg
		adiw	pushAmountRegH:pushAmountRegL, 1
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
		SBIS UCSRA, 5

		PUSH	curveReg
		;out udr, curveReg
		clr		curveReg
		adiw	pushAmountRegH:pushAmountRegL, 1
		rjmp	MAINRUNDE1
		
mainrundePreX:
mov r16, fastDrive
out ocr2, r16
rjmp MAINRUNDEX
; -------------------------------- MAINRUNDEX --------------------------------------------------------
MAINRUNDEX:
	ldi r16, 5
	out udr, r16
	;call dequeue if distreg = 0 (det er den også ved start)
	cpi		distReg, 0
	breq	dequeue
	backFromDequeue:
	; MANGLER AT SKIFTE MELLEM HURTIG OG LANGSOM HASTIGHED
	RJMP	MAINRUNDEX


dequeue:
	; hvis pop, skift hastighedsregister
	IN CompReg, OCR2
	CP CompReg, fastDrive
	BREQ SetSlow

	CP CompReg, slowDrive
	BREQ SetFast
	returnDequeue:


	LD		distReg, x
	out		udr, distReg
;	out		udr,	distreg
	subi	XL, 1
	sbci	XH, 0 ; may cause error!!! \(X_X)/
	
	;if  XL,XH  <  ramend-pushAmountReg; goto reset deququ
	subi	pushAmountRegL, low(RAMEND)
	sbci	pushAmountRegH, high(RAMEND)

	cp		XL, pushAmountRegL
	cpc		XH, pushAmountRegH
	brlo	resetDequeue

	rjmp	backFromDequeue

resetDequeue:
	ldi XL, low(RAMEND)
	ldi XH, High(RAMEND)
	rjmp MAINRUNDEX


SetFast:
mov r16, fastDrive
OUT OCR2, r16
RJMP returnDequeue


SetSlow:
mov r16, slowDrive
OUT OCR2, r16
RJMP returnDequeue
