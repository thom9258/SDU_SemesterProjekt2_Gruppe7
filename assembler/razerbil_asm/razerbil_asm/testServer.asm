.include "m32adef.inc"

.org	0x00
	rjmp	SETUP

/*.org	UDREaddr
	rjmp	ISR_UDRE
*/
.org	0x01A
	rjmp	ISR_URXC

.org	0x2A
	

SETUP:
	;portb setup (camera, light, action)
	ldi		r16,	0xff
	out		ddrb,	r16
	ldi		r16,	0b01010101
	out		portb,	r16
	;pointer x setup
	ldi		XH,		0x00
	ldi		XL,		0x60
	;Stack pointer
	LDI		R16,	HIGH(RAMEND)
	OUT		SPH,	R16
	LDI		R16,	LOW(RAMEND)
	OUT		SPL,	R16

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

	LDI		R17, 0
	SEI							;Aktiver interrupt
SEND:
	;Gør noget her med data:
	
	in R16, SPH
	in R17, SPL
	cpi R16, (HIGH(RAMEND))
	BRGE checkLowerPointer ;branch if lower than 
	rjmp SEND
	checkLowerPointer:
		cpi R17, (LOW(RAMEND))
		BRGE outData ;branch if lower than 
		rjmp SEND
		outData:
			checkDataRegisterEmpty:
				SBIS	UCSRA, UDRE			;loop until data register is empty
				RJMP	checkDataRegisterEmpty
			pop r16
			OUT	UDR, R16
			com R16
			out portb, r16
	//out r16 og reset derefter check om der er mere at sende
	RJMP	SEND
/*

ISR_UDRE:						;Afsender interrupt
	OUT		R16,	UDR
	RETI*/

ISR_URXC:						;Modtager interrupt
	in R18, UDR
	pop R19
	pop R20
	push r18
	push R20
	push r19
	
	RETI