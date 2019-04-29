;
; AdcToSerial_v1.asm
;
; Created: 23/04/2019 11:07:57
; Author : Thomas Alexgaard
;

.include "m32adef.inc"

.org	0x00
	rjmp	SETUP

.org	0x2A

	.def AdcCReg = R17

SETUP:
		;porta setup til ADC
	ldi		r16,	0x00
	out		ddra,	r16

	; Stack pointer setup
	LDI		R16,	HIGH(RAMEND)
	OUT		SPH,	R16
	LDI		R16,	LOW(RAMEND)
	OUT		SPL,	R16

	;U2X setup (double speed)
	LDI		R16,	0b00000010
	OUT		UCSRA,	R16	


	;Slå seriel kommunikation og recieve interrupts til
	LDI		R16,	(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)
	OUT		UCSRB,	R16

	;Brug UCSRC, sæt frame size = 8
	LDI		R16,	(1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
	OUT		UCSRC,	R16

	;Sæt baud rate = 9600 
	LDI		R16,	12		;UBRR LSB
	OUT		UBRRL,	R16

	; ADC Setup
	LDI R16, 0b11100010 ; intern ref spænding, auto trigger til, gemmer 8 msb bits, læs fra PA2
	OUT ADMUX, R16

	LDI R16, 0b11100011 ; enable adc, start adc, ingen autotrigger, prescaler på 1/8
	; vi bruger en prescaler på 1/8 for at holde den under dens ADC converterns maksimale clock frekvens på 200 kHz
	OUT ADCSR, R16




	MAINLOOP:

	SBIS ADCSR, ADIF ; skipper loopet hvis ADIF er sat i ADCSR (venter)
	RJMP MAINLOOP

	CBI ADCSR , ADIF ; clearer bit

	IN R16, ADCL ; gemmer adc værdi
	IN R16, ADCH

	//LDI TestReg, 155
	OUT UDR, R16 ; smider værdi ind i kommunikations registeret

	RJMP MAINLOOP


