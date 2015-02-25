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
LED_Count	EQU	0x20
LED_Time	EQU	.100
#Define	LED_Bit	LATA,4	
Param70	EQU	0x70
Param71	EQU	0x71
#Define	myByte	Param70
#Define	_C	0x03,C

	ORG	0x0000	;Reset Vector
	goto	Start
	
;****************************************************************
	ORG	0x0004	;ISR
	MOVLB	0
; Timer 2
	BTFSS	PIR1,TMR2IF
	GOTO	TMR2_End
	
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
	MOVLW	B'00101111'
	MOVWF	TRISA
	
	BANKSEL	PIE1	;Enable Interupts
	BSF	PIE1,TMR2IE
	BSF	INTCON,PEIE
	BSF	INTCON,GIE
	
Loop2	CLRWDT
	
	goto	Loop2
	
	
		
	
	
	
	
	END
	