;Test 
	list	p=12f1822,r=hex,w=0	; list directive to define processor
;
	nolist
	include	p12f1822.inc	; processor specific variable definitions
	list
;
	__CONFIG _CONFIG1,_FOSC_INTOSC & _WDTE_OFF & _MCLRE_OFF & _IESO_OFF
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
Param70	EQU	0x70
Param71	EQU	0x71
#Define	myByte	Param70
#Define	_C	0x03,C

	ORG	0x0000	;Reset Vector
	goto	Start
	
	ORG	0x0004	;ISR
	goto	Start
	
Start	MOVLB	0x00
	MOVLW	0x10
	MOVWF	PORTA
	MOVLB	0x03
	CLRF	ANSELA
	MOVLB	0x01
	MOVLW	B'00101111'
	MOVWF	TRISA
	
	BANKSEL	LATA
Loop2	MOVLW	0x10
	XORWF	LATA,F
	CALL	WaitHere1Sec
	goto	Loop2
	
	
	
	
WaitHere1Sec	MOVLW	0x7F
	MOVWF	Param71
Loop1	DECFSZ	Param70,F	
	GOTO	Loop1
	DECFSZ	Param71,F
	GOTO	Loop1
	RETURN
	
	
	
	
	
	END
	