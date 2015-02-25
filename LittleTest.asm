;Test 
	list	p=12f1822,r=hex,w=0	; list directive to define processor
;
	nolist
	include	p12f1822.inc	; processor specific variable definitions
	list
;
	__CONFIG _CONFIG1,_FOSC_INTOSC & _WDTE_ON & _MCLRE_OFF & _IESO_OFF
;
;
;
; INTOSC oscillator: I/O function on CLKIN pin
; WDT disabled
; PWRT disabled
; MCLR/VPP pin function is digital input
; Program memory code protection is disabled
; Data memory code protection is disabled
; Brown-out Reset enabled
; CLKOUT function is disabled. I/O or oscillator function on the CLKOUT pin
; Internal/External Switchover mode is disabled
; Fail-Safe Clock Monitor is enabled
;
	__CONFIG _CONFIG2,_WRT_OFF & _PLLEN_OFF & _LVP_OFF
;
; Write protection off
; 4x PLL disabled
; Stack Overflow or Underflow will cause a Reset
; Brown-out Reset Voltage (Vbor), low trip point selected.
; Low-voltage programming Disabled ( allow MCLR to be digital in )
;  *** must set apply Vdd before Vpp in ICD 3 settings ***
;
; '__CONFIG' directive is used to embed configuration data within .asm file.
; The lables following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.
;
OSCCON_Value	EQU	b'01110010'	;8MHz
T2CON_Value	EQU	b'01001110'	;T2 On,/16 pre, /10 post
PR2_Value	EQU	.125
;
; 0.5uS res counter from 8MHz OSC
CCP1CON_Clr	EQU	b'00001001'	;Clear output on match
CCP1CON_Set	EQU	b'00001000'	;Set output on match
T1CON_Val	EQU	b'00000001'	;PreScale=1,Fosc/4,Timer ON
;
CCP1CON_Value	EQU	0x00	;CCP1 off
;
	cblock	0x20
;
	LED_Count
;
	Timer1Lo		;1st 16 bit timer
	Timer1Hi		; one second RX timeiout
;
	Timer2Lo		;2nd 16 bit timer
	Timer2Hi		;
;
	Timer3Lo		;3rd 16 bit timer
	Timer3Hi		;GP wait timer
;
	Timer4Lo		;4th 16 bit timer
	Timer4Hi		; debounce timer
	endc
;
LED_Time	EQU	.100
#Define	LED_Bit	LATA,4	
Param70	EQU	0x70
Param71	EQU	0x71
#Define	myByte	Param70
#Define	_C	0x03,C
kStepTime	EQU	.500

	ORG	0x0000	;Reset Vector
	goto	Start
	
;****************************************************************
	ORG	0x0004	;ISR
	MOVLB	0
; Timer 2
	BTFSS	PIR1,TMR2IF
	GOTO	TMR2_End
;Decrement timers until they are zero
; 
	call	DecTimer1	;if timer 1 is not zero decrement
; 
	call	DecTimer2
; GP, Wait loop timer
	call	DecTimer3
; 
	call	DecTimer4
;
	BANKSEL	LATA
	BCF	LED_Bit
	MOVLB	0
	DECFSZ	LED_Count,F
	GOTO	TMR2_Done
	MOVLW	LED_Time
	MOVWF	LED_Count
	BANKSEL	LATA
	BSF	LED_Bit
	
	MOVLB	0
TMR2_Done	BCF	PIR1,TMR2IF
TMR2_End:
;
IRQ_MotorMove	MOVLB	0	;bank 0
	BTFSS	PIR1,CCP1IF
	GOTO	IRQ_MotorMove_End
	MOVLB	0x05
	CLRF	CCP1CON
	BANKSEL	LATA
	BCF	LATA,5
	MOVLB	0x05
	MOVLW	LOW kStepTime
	ADDWF	CCPR1L,F
	MOVLW	HIGH kStepTime
	ADDWFC	CCPR1H,F
	MOVLW	CCP1CON_Set
	MOVWF	CCP1CON
	MOVLB	0	;bank 0
	BCF	PIR1,CCP1IF
IRQ_MotorMove_End:
	RETFIE
;
;*******************************************************************
;
;*******************************************************************
;	
Start:
	CLRWDT
	BANKSEL	OSCCON	;Setup OSC
	MOVLW	OSCCON_Value
	MOVWF	OSCCON
	
	BANKSEL	T2CON	;Setup T2 for 100/s
	MOVLW	T2CON_Value
	MOVWF	T2CON
	BANKSEL	PR2
	MOVLW	PR2_Value
	MOVWF	PR2
	
	MOVLB	0x00	;Setup Port A
	MOVLW	0x10
	MOVWF	PORTA
	MOVLB	0x03
	CLRF	ANSELA
	MOVLB	0x01
	MOVLW	B'00001011'
	MOVWF	TRISA
;
; setup timer 1 for 0.5uS/count
;
	BANKSEL	T1CON	; bank 0
	MOVLW	T1CON_Val
	MOVWF	T1CON
	bcf	T1GCON,TMR1GE
; Setup ccp1
	BANKSEL	APFCON
	BSF	APFCON,CCP1SEL	;RA5
	BANKSEL	CCP1CON
	CLRF	CCP1CON
	MOVLW	CCP1CON_Set
	MOVWF	CCP1CON
;	
	BANKSEL	PIE1	;Enable Interupts
	BSF	PIE1,TMR2IE
	bsf	PIE1,CCP1IE
;
	BSF	INTCON,PEIE
	BSF	INTCON,GIE
	
Loop2	CLRWDT
;
	BANKSEL	Timer4Hi
	MOVF	Timer4Hi,W
	IORWF	Timer4Lo,W
	SKPZ
	GOTO	NOTZERO
;
MyTime	EQU	.100
	MOVLW	Low MyTime
	MOVWF	Timer4Lo
	MOVLW	High MyTime
	MOVWF	Timer4Hi
;	BANKSEL	LATA
;	BSF	LATA,2
;	NOP
;	BCF	LATA,2
; Do something here
NOTZERO:
	goto	Loop2
	
;=========================================================================================================
; Decrement routine for 16 bit timers
;
DecTimer4	movlw	Timer4Hi
	goto	DecTimer
DecTimer3	movlw	Timer3Hi
	goto	DecTimer
DecTimer2	movlw	Timer2Hi
	goto	DecTimer
DecTimer1	movlw	Timer1Hi
;DecTimer
; entry: FSR=Timer(n)Hi
DecTimer	MOVWF	FSR0
	MOVF	INDF0,W	;TimerNHi
	DECF	FSR0,F
	IORWF	INDF0,W	;TimerNLo
	SKPNZ
	RETURN
	MOVLW	0x01
	SUBWF	INDF0,F	;TimerNLo
	INCF	FSR0,F
	MOVLW	0x00
	SUBWFB	INDF0,F	;TimerNHi
	RETURN
;
	
	END
	