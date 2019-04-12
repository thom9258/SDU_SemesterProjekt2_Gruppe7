.include "m32adef.inc"

.org	0x00
	rjmp	SETUP

.org	0x01A
	rjmp	ISR_URXC

.org	0x2A
	

SETUP:
	;Stack pointer setup
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

	;timer0 setup
	ldi		r16,	0
	out		ocr0,	r16
	LDI		R16,	0b01110001 ;fasekorigeret og inverterene med prescaler på 1
	out		TCCR0,	R16
	
	;portb setup
	ldi r16, 0xff
	out ddrb, r16
	out portb, r16

	;Aktiver interrupt
	SEI					

SEND:							;forever loop
	RJMP	SEND

ISR_URXC:						;Modtager interrupt
	in R16,		UDR				;indlæser data
	out ocr0,	R16				;out data til ocr0
	out UDR,	R16				;out data tilbage til senderen
	RETI