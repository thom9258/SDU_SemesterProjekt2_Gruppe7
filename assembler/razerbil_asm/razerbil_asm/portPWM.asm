;
; 2semProjekt.asm
;
; Created: 18-Mar-19 09:39:18
; Author : Claus




setup:
;wgm01:wgm00 = 01 = phase correct pwm (11 = fast pwm)
;com01:com00 = 10 = noninverted (11 = inverted)
;cs02:cs01:cs00 er prescalers
.equ timerOn = 0b01100001; foc0 wgm00 com01 com00 wgm01 cs02 cs01 cs00
.equ timerOff = 0b01100000

	;stack setup
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16 
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	;portc setup
	ldi r16, 0
	out ddrc, r16
	com r16
	out portc, r16

	;portb setup
	.equ pwmOut = 0
	ldi r16, 0b00000001 ;pwm på pb3
	out ddrb, r16

	;sætter pwm
	in r17, pinc
	out	OCR0, R17

	;timer setup
	ldi r16, timerOn 
	out tccr0, r16


;MAIN LOOP
loop:
	pop r17
	in r16, pinc
	cpse r16, r17 ;skip if equal 
	call moveReg
	in      R16, OCR0
    in      R18, TCNT0
    cp      R16, R18            ; OCR0 - TCNT0
    brsh    lightOff
	;lightOn:
	cbi portb, pwmOut
	rjmp loop

	lightOff:
	sbi portb, pwmOut
	rjmp loop

	moveReg:
	mov r17, r16
	ldi r16, timerOff ;stop timer
	out tccr0, r16
	out	OCR0, R17
	ldi r16, timerOn ;start timer
	out tccr0, r16
	ret



;få indput fra Pin 