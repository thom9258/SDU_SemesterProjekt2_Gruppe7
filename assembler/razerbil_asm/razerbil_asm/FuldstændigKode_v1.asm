;
; GemHjul_v1.asm
;
; Created: 29/04/2019 09:57:31
; Author : Thomas Alexgaard
;

.include "m32def.inc"

.org	0x00
	rjmp	SETUP

.org	0x2A



	.def AdcReg = R17
	.def CompReg = R18
	.def straightReg = R19
	.def curveReg = R20



	.equ fastDrive = 120
	.equ slowDrive  = 70


	.equ lowT = 63
	.equ highT = 65

	; -------------------------------------------------------SETUP START
	
	SETUP:
	
	; Stack pointer setup
	LDI		R16,	HIGH(RAMEND)
	OUT		SPH,	R16
	LDI		R16,	LOW(RAMEND)
	OUT		SPL,	R16
	
	;U2X setup (double speed)
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

	LDI R16, 0b11100010 ; intern ref spænding, auto trigger til, gemmer 8 msb bits, læs fra PA2
	OUT ADMUX, R16

	LDI R16, 0b11100011 ; enable adc, start adc, autotrigger, prescaler på 1/8
	; vi bruger en prescaler på 1/8 for at holde den under dens ADC converterns maksimale clock frekvens på 200 kHz
	OUT ADCSR, R16

	
	
	; enable alle hardware interrupts
	LDI R16, (1<<INT0) | (1<<INT1) | (1<<INT2)
	OUT GICR, R16
	


	; PWM opsætning
	ldi r16, 0b01100001 ; phase korrekt, non inverterende, prescaler på 1 
	out tccr2, r16

	LDI R16, fastDrive
	out	OCR2, R16 

	; port d setup

	ldi R16, 0xFF
	OUT ddrd, R16
	Out PORTD, R16

	SEI
	

	rjmp MAINLOOP

	; -------------------------------------------------------SETUP SLUT

	; -------------------------------------------------------INTERRUPT START

	LapInterrupt:
	
	
	RETI

	; -------------------------------------------------------INTERRUPT SLUT


	; -------------------------------------------------------MAIN START

	MAINLOOP: 
	
	IN AdcReg, ADCL
	IN AdcReg, ADCH

	SBIC ADCSR, ADIF ; skipper loopet hvis ADIF er sat i ADCSR (venter)
	CALL SENDADC

	; this code checks if adc input is higher or lower than chosen values, meaning we are turning
	; stadie 1 (dreje)
	LDI CompReg, highT ; inserts 165 into compare register
	CP AdcReg, CompReg ; compares compare register with adc input register
	BRSH Stadie1 ; branch if adcReg > compReg

	LDI CompReg, lowT ; inserts 89 into compare register
	CP ADCReg, CompReg ; compares compare register with adc input register
	BRLO Stadie1 ; branch if adcReg < compReg

	; if the value in adcreg goes through both test cases without beanching, then it means we are going straight
	; stadie 2 (lige ud)
	RJMP Stadie2


	Stadie1: ; when turning
	LDI R16, slowDrive
	out	OCR2, R16
	RJMP MAINLOOP


	Stadie2: ; when going straight
	LDI R16, fastDrive
	out	OCR2, R16
	RJMP MAINLOOP


		; -------------------------------------------------------MAIN SLUT



SENDADC:

	CBI ADCSR , ADIF ; clearer bit
	OUT UDR, AdcReg ; smider værdi ind i kommunikations registeret
RET