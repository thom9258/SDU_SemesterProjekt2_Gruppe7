.include "m32adef.inc"

.org	0x00
	rjmp	SETUP

.org	0x01A
	rjmp	ISR_URXC

.org	0x2A
	

SETUP:
	;portb setup (camera, light, action)
	ldi		r16,	0xff
	out		ddrb,	r16
	ldi		r16,	0b01010101
	out		portb,	r16
	
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

	LDI		R17, 0
	SEI					;Aktiver interrupt

SEND:	//out r16 og reset derefter check om der er mere at sende på stacken
	;indlæs stackpointer
	in R16, SPH
	in R17, SPL
	cpi R16, (HIGH(RAMEND))
	BRGE checkLowerPointer ;branch if lower than (hvis stackpointer ikke er ved dens start)
	rjmp SEND
	checkLowerPointer:
		cpi R17, (LOW(RAMEND))
		BRGE outData ;branch if lower than (hvis stackpointer ikke er ved dens start)
		rjmp SEND
		outData:
			checkDataRegisterEmpty:
				SBIS	UCSRA, UDRE	;loop until data register is empty (venter med at sende data)
				RJMP	checkDataRegisterEmpty
			pop 	r16			;(får data fra stack som skal sendes)
			OUT	UDR, R16		;transmit data
			com 	R16			;invert data
			out 	portb, r16		;display data on 7seg disp.
	RJMP	SEND

ISR_URXC:						;Modtager interrupt
	in R18, UDR					;indlæser data
	pop R19						;gæm 2byte stackpointer
	pop R20						;gæm 2byte stackpointer
	push r18					;læg den indlæste i stack
	push R20					;retuner 2byte stackpointer
	push r19					;retuner 2byte stackpointer
	
	RETI
