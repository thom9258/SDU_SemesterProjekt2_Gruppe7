;
; 2semProjekt.asm
;
; Created: 18-Mar-19 09:39:18
; Author : Clas
;


;MAIN LOOP
MAIN:
;få indput fra Pin a
LDI		R16, 0xFF
OUT		DDRA, R16
IN		R16, PINA

;compare PA1 ved at rotere den ud til carry
ror		R16
ror		R16
brcs	LED		;branch if carry = 1

;hvis ikke der er input fra PA1, sluk led
ldi		R16, 0
out		ddra, R16
out		porta, R16

RJMP	MAIN
 
LED:
LDI		R16, 0x00
OUT		DDRA, R16
LDI		R16, 0b01000000
OUT		PORTA, R16

RJMP	MAIN