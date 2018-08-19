;#########################################################################################################################################################
;Copyright (c) 2018 Peter Shabino
;
;Permission is hereby granted, free of charge, to any person obtaining a copy of this hardware, software, and associated documentation files 
;(the "Product"), to deal in the Product without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
;distribute, sublicense, and/or sell copies of the Product, and to permit persons to whom the Product is furnished to do so, subject to the 
;following conditions:
;
;The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Product.
;
;THE PRODUCT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
;MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
;FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
;WITH THE PRODUCT OR THE USE OR OTHER DEALINGS IN THE PRODUCT.
;#########################################################################################################################################################
; 09Jun18 V0 PJS New
; 08Jul18 V3 PJS 8 and 12 bit menue entry working 
; 15Jul18 V4 PJS Custom colors fully working (including blink), custom Larson scanner working, Split code over 3 pages of flash (4th rsvd for vibe if needed) 
; 01Aug18 V5 PJS Saving of setting to eeprom working and "direct remote" code mostly working
	
#define CODE_VER 0x05
#define	CODE_VER_STRING "Peter Shabino 01Aug18 code for Mr Stash 2018 V5 www.wire2wire.org!" ;Just in ROM !!! update vars below with true level!!
ver_a	equ	0x33
ver_b	equ	0x00
ver_c	equ	0x00
ver_d	equ	0x00
	
; NOTES
; SAF is high endurance flash (128 words) at the end of flash. Not usable as program space when enabled in config words 

;****************************************************************************************
; port list [SSOP28]
; Vss(8,19)
; Vdd(20)
; RA0(2)	LIR
; RA1(3)	B
; RA2(4)	LR4
; RA3(5)	LG4
; RA4(6)	LB4
; RA5(7)	Set
; RA6(10)	LG3
; RA7(9)	LR3
; RB0(21)	A
; RB1(22)	SIR
; RB2(23)	M1
; RB3(24)	SCL
; RB4(25)	SDA
; RB5(26)	M2
; RB6(27)	[ISPCLK] BBtx
; RB7(28)	[ICSPDAT] BBrx
; RC0(11)	LB3
; RC1(12)	LR2
; RC2(13)	LG2
; RC3(14)	LB2
; RC4(15)	Sel
; RC5(16)	LR1
; RC6(17)	LG1
; RC7(18)	LB1
; RE3(1)	[MCLR]	
;****************************************************************************************

	
; PIC16F15355 Configuration Bit Settings
#include "p16f15355.inc"
; CONFIG1
; __config 0xFF8C
 __CONFIG _CONFIG1, _FEXTOSC_OFF & _RSTOSC_HFINT32 & _CLKOUTEN_OFF & _CSWEN_ON & _FCMEN_ON
; CONFIG2
; __config 0xF7FD
 __CONFIG _CONFIG2, _MCLRE_ON & _PWRTE_ON & _LPBOREN_OFF & _BOREN_ON & _BORV_LO & _ZCD_OFF & _PPS1WAY_OFF & _STVREN_ON
; CONFIG3
; __config 0xFF9F
 __CONFIG _CONFIG3, _WDTCPS_WDTCPS_31 & _WDTE_OFF & _WDTCWS_WDTCWS_7 & _WDTCCS_SC
; CONFIG4
; __config 0xDFEF
 __CONFIG _CONFIG4, _BBSIZE_BB512 & _BBEN_OFF & _SAFEN_ON & _WRTAPP_OFF & _WRTB_OFF & _WRTC_ON & _WRTSAF_OFF & _LVP_OFF
; CONFIG5
; __config 0xFFFE
 __CONFIG _CONFIG5, _CP_ON	
 
 
;#define __LED_TEST_MODE__
 
;------------------
; constants
;------------------	
; Default USER ID to load
UserID  code 0x8000
	dw 0x3FFF
    ;dw 0x3F00	

; test code for load from flash storage	/ test modes
;Settings  code 0x1F80
;	dw 0x3F03	
;	dw 0x3F0C
;	dw 0x3F30
;	dw 0x3FC3	
;	dw 0x3F06	
;	dw 0x3F20	
;	dw 0x3F00	

	
START_OF_REGS			equ 0x65			; constant to first reg that should be restored from flash assumes 0x6F is the end. 		
IR_PULSE_WIDTH			equ 0x35			; pulse width set to 10% (0x69 = 50%, 0x35 = 25%, 0x15 = 10%, 0x0A = 5%)
IR_B_ON_PWM				equ 0xFF
IR_B_ON_TIME			equ 0x12			; on time for beacon buzzer 
IR_DIRECT_RMT_ON_PWM	equ 0xFF
IR_DIRECT_RMT_ON_TIME	equ 0x12			; on time for direct remote buzzer (on till next IR input cycle...) 
TOUCH_TRIP				equ 0x50			; trip point delta on ADC value (tune to prevent false touches)
BUTTON_DEBOUNCE			equ 0x02			; how many cycles of no press to wait before taking next entry (larger = less twitchy but slower max updates)
BEACON_TIME_L			equ 0xF6			; delay between beacon sends
BEACON_TIME_H			equ 0x04		
;------------------
; vars (0x20 - 0x6f) bank 0
;------------------
LED1			equ 0x20			; 0-1 red, 2-3 green, 4-5 blue, 6-7 blink
LED2			equ 0x21			; 0-1 red, 2-3 green, 4-5 blue, 6-7 blink
LED3			equ 0x22			; 0-1 red, 2-3 green, 4-5 blue, 6-7 blink
LED4			equ 0x23			; 0-1 red, 2-3 green, 4-5 blue, 6-7 blink
led_seq			equ 0x24
porta_temp		equ 0x25		
portc_temp		equ 0x26		
blink_seq		equ 0x27
beacon_timer_l	equ 0x28
beacon_timer_h	equ 0x29
ir_status		equ 0x2A			; 
badge_id		equ 0x2B
ir_cmd			equ 0x2C		
ir_data			equ 0x2D
ir_chksum		equ 0x2E
ir_tx_seq		equ 0x2F	
ir_rx_seq		equ 0x30
ir_rx_chksum	equ 0x31
ir_rx_data		equ 0x32
ir_rx_id		equ 0x33
ir_rx_cmd		equ 0x34					
temp			equ 0x35
beacon_b_timer	equ 0x36
mode_ctl		equ 0x37
no_press_cnt	equ 0x38
led_timer_low	equ 0x39
led_timer_high	equ 0x3A
sequence		equ 0x3B
mode_reg		equ 0x3C
led_display_seq	equ 0x3D		
temp2			equ 0x3E	
temp3			equ 0x3F
call_temp		equ	0x40
direct_m1_timer	equ 0x41
direct_m2_timer	equ 0x42
ir_data_temp	equ	0x43	
vibe_cycle		equ 0x44
vibe_timer_low	equ 0x45
vibe_timer_high equ 0x46	
vibe_sequence	equ 0x47
vibe_stop		equ 0x48
vibe_temp		equ 0x49
vibe_subloop	equ 0x4A
		
		
; UPDTATE START_OF_REGS in constants if you add any more saved vars to this section!!!	
	
vibe_speed_l	equ	0x65
vibe_speed_h	equ	0x66
vibe_rpt		equ 0x67	
vibe_mode 		equ	0x68	
cust_led4		equ	0x69	
cust_led3		equ	0x6A		
cust_led2		equ	0x6B	
cust_led1		equ	0x6C		
led_mode_reg	equ 0x6D
speed_low		equ 0x6E		
speed_high		equ 0x6F		

;------------------
; vars (0xA0 - 0xef) bank 1
;------------------
adc_seq			equ 0xA0
button1_cur		equ 0xA1
button2_cur		equ 0xA2
button3_cur		equ 0xA3
button4_cur		equ 0xA4
button1_last	equ 0xA5
button2_last	equ 0xA6
button3_last	equ 0xA7
button4_last	equ 0xA8

;------------------
; vars (0x120 - 0x16f) bank 2
;------------------
LFSR_0			equ	0x120
LFSR_1			equ	0x121
LFSR_2			equ	0x122
LFSR_3			equ	0x123

;------------------
; vars (0x1A0 - 0x1ef) bank 3
;------------------

;------------------
; vars (0x220 - 0x26f) bank 4
;------------------

;------------------
; vars (0x2A0 - 02xef) bank 5
;------------------
 
;------------------
; vars (0x320 - 0x36f) bank 6 (55 part only 0x320 to 0x32F on 54 part) 
;------------------
		
;------------------
; vars (0x3A0 - 0x3ef) bank 7 (55 part only)
;------------------

;------------------
; vars (0x420 - 0x46f) bank 8 (55 part only) 
;------------------

;------------------
; vars (0x4A0 - 0x4ef) bank 9 (55 part only)
;------------------

;------------------
; vars (0x520 - 0x56f) bank 10 (55 part only) 
;------------------

;------------------
; vars (0x5A0 - 0x5ef) bank 11 (55 part only)
;------------------

 ;------------------
; vars (0x620 - 0x64f) bank 12 (55 part only) 
;------------------

;------------------
; vars (0x70 - 0x7F) global regs
;------------------
bsr_save		equ 0x70
gtemp			equ 0x71
delay_cntL		equ 0x72
delay_cntH		equ 0x73
buttons			equ 0x74	


 
;put the following at address 0000h
	org     0000h
	goto    START			    ;vector to initialization sequence

;put the following at address 0004h
	org     0004h
	clrf	PCLATH				; this MUST be cleared before the IRQ goto else will jump to god knows where. 
	goto    IRQ			    

; stuff in the 	code description at the top of the code. 
	de	CODE_VER_STRING
	
;###########################################################################################################################
; intrupt routine
;###########################################################################################################################
IRQ		
	; following regs are autosaved
	; W
	; STATUS (except TO and PD)
	; BSR
	; FSR
	; PCLATH
	
	;******************************************************************
	; check if ADC IRQ
	;******************************************************************
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	btfss	PIR1, ADIF			; check if IRQ is currently set
	goto	IRQ_not_ADC
	bcf		PIR1, ADIF	
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------
	
	
	
	movf	adc_seq, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	IRQ_ADC_button3
	movf	ADRESH, W
	movwf	button4_cur
	;------------------
	clrf	BSR		
	;------------------
	bcf		TRISA, 1			; pin output
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------		
	incf	adc_seq, F
	goto	IRQ_not_ADC

IRQ_ADC_button3
	movf	adc_seq, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	IRQ_ADC_button2
	movf	ADRESH, W
	movwf	button3_cur
	;------------------
	clrf	BSR		
	;------------------
	bcf		TRISA, 5			; pin output
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------		
	incf	adc_seq, F
	goto	IRQ_not_ADC

IRQ_ADC_button2
	movf	adc_seq, W
	xorlw	0x08
	btfss	STATUS, Z
	goto	IRQ_ADC_button1
	movf	ADRESH, W
	movwf	button2_cur
	;------------------
	clrf	BSR		
	;------------------
	bcf		TRISC, 4			; pin output
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------		
	incf	adc_seq, F
	goto	IRQ_not_ADC

IRQ_ADC_button1
	movf	adc_seq, W
; in case things get out of seq just default to this case to clear things up	
;	xorlw	0x0b
;	btfss	STATUS, Z
;	goto	IRQ_ADC_button0
	; see if touch sensor is over threshold
	movf	ADRESH, W
	movwf	button1_cur
	;------------------
	clrf	BSR		
	;------------------
	bcf		TRISB, 0			; pin output
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------		
	clrf	adc_seq
	
	; if ADC = 0 button tripped
	movf	button1_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 0
	; if ADC = FF button tripped
	comf	button1_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 0
	; if ADC value is more than TOUCH_TRIP above last read 
	movf	button1_last, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b1_gt_carry
	subwf	button1_cur, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 0	
IRQ_ADC_b1_gt_carry	
	; if ADC value is more than TOUCH_TRIP below last read 
	movf	button1_cur, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b1_lt_carry
	subwf	button1_last, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 0	
IRQ_ADC_b1_lt_carry	
	movf	button1_cur, W
	movwf	button1_last
	
	; if ADC = 0 button tripped
	movf	button2_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 1
	; if ADC = FF button tripped
	comf	button2_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 1
	; if ADC value is more than TOUCH_TRIP above last read 
	movf	button2_last, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b2_gt_carry
	subwf	button2_cur, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 1	
IRQ_ADC_b2_gt_carry	
	; if ADC value is more than TOUCH_TRIP below last read 
	movf	button2_cur, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b2_lt_carry
	subwf	button2_last, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 1	
IRQ_ADC_b2_lt_carry	
	movf	button2_cur, W
	movwf	button2_last

	; if ADC = 0 button tripped
	movf	button3_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 2
	; if ADC = FF button tripped
	comf	button3_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 2
	; if ADC value is more than TOUCH_TRIP above last read 
	movf	button3_last, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b3_gt_carry
	subwf	button3_cur, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 2	
IRQ_ADC_b3_gt_carry	
	; if ADC value is more than TOUCH_TRIP below last read 
	movf	button3_cur, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b3_lt_carry
	subwf	button3_last, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 2	
IRQ_ADC_b3_lt_carry	
	movf	button3_cur, W
	movwf	button3_last
	
	; if ADC = 0 button tripped
	movf	button4_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 3
	; if ADC = FF button tripped
	comf	button4_cur, W
	btfsc	STATUS, Z
	bsf		buttons, 3
	; if ADC value is more than TOUCH_TRIP above last read 
	movf	button4_last, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b4_gt_carry
	subwf	button4_cur, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 3	
IRQ_ADC_b4_gt_carry	
	; if ADC value is more than TOUCH_TRIP below last read 
	movf	button4_cur, W
	addlw	TOUCH_TRIP
	btfsc	STATUS, C
	goto	IRQ_ADC_b4_lt_carry
	subwf	button4_last, W		; F - W 
	btfsc	STATUS, C
	bsf		buttons, 3	
IRQ_ADC_b4_lt_carry	
	movf	button4_cur, W
	movwf	button4_last

	; set bit to indicate update is done
	bsf		buttons, 4	

IRQ_ADC_debug_leds	
#ifdef __LED_TEST_MODE__
	; for button debug only... 
	;------------------
	clrf	BSR		
	;------------------	
	clrf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	btfss	buttons, 0
	goto	debug_skip0
	movlw	0x3F
	movwf	LED1
debug_skip0
	btfss	buttons, 1
	goto	debug_skip1
	movlw	0x3F
	movwf	LED2
debug_skip1
	btfss	buttons, 2
	goto	debug_skip2
	movlw	0x3F
	movwf	LED3
debug_skip2
	btfss	buttons, 3
	goto	debug_skip3
	movlw	0x3F
	movwf	LED4
debug_skip3
	clrf	buttons
#endif
	
IRQ_not_ADC		
	
	;******************************************************************
	; check if TMR0 IRQ
	;******************************************************************
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	btfss	PIR0, TMR0IF
	goto	IRQ_not_TMR0
	bcf	PIR0, TMR0IF
	;------------------
	clrf	BSR		
	;------------------	
	; if the delay_cnt is not 0 subtract 1
	movf	delay_cntL, F
	btfsc	STATUS, Z
	goto	IRQ_delay_L_0
	decf	delay_cntL, F
	goto	IRQ_delay_done
IRQ_delay_L_0	
	movf	delay_cntH, F
	btfsc	STATUS, Z
	goto	IRQ_delay_done
	decf	delay_cntL, F
	decf	delay_cntH, F
IRQ_delay_done	
	
	; if the delay_cnt is not 0 subtract 1
	movf	led_timer_low, F
	btfsc	STATUS, Z
	goto	IRQ_delay_led_0
	decf	led_timer_low, F
	goto	IRQ_delay_led_done
IRQ_delay_led_0	
	movf	led_timer_high, F
	btfsc	STATUS, Z
	goto	IRQ_delay_led_done
	decf	led_timer_low, F
	decf	led_timer_high, F
IRQ_delay_led_done	
	
	; if the delay_cnt is not 0 subtract 1
	movf	vibe_timer_low, F
	btfsc	STATUS, Z
	goto	IRQ_delay_vibe
	decf	vibe_timer_low, F
	goto	IRQ_delay_vibe_done
IRQ_delay_vibe	
	movf	vibe_timer_high, F
	btfsc	STATUS, Z
	goto	IRQ_delay_vibe_done
	decf	vibe_timer_low, F
	decf	vibe_timer_high, F
IRQ_delay_vibe_done	

	
	
	
	
	
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------
	; if conversion is still in process wait. 
	btfsc	ADCON0, 1
	goto	IRQ_ADC_step_done
	

	; step 1 charge internal ADC cap
	movf	adc_seq, W
	;xorlw	0x00
	btfss	STATUS, Z
	goto	IRQ_ADC_b4s2
	;------------------
	clrf	BSR		
	;------------------
	bsf		TRISA, 1			; pin input
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------	
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0xF9				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
	goto	IRQ_ADC_step_done
IRQ_ADC_b4s2	
	; step 2 start ADC conversion
	movf	adc_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_ADC_b3s1
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0x07				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
	goto	IRQ_ADC_step_done
IRQ_ADC_b3s1
	

	; step 1 charge internal ADC cap
	movf	adc_seq, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	IRQ_ADC_b3s2
	;------------------
	clrf	BSR		
	;------------------
	bsf		TRISA, 5			; pin input
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------	
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0xF9				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
	goto	IRQ_ADC_step_done
IRQ_ADC_b3s2	
	; step 2 start ADC conversion
	movf	adc_seq, W
	xorlw	0x04
	btfss	STATUS, Z
	goto	IRQ_ADC_b2s1
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0x17				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
	goto	IRQ_ADC_step_done
IRQ_ADC_b2s1

	; step 1 charge internal ADC cap
	movf	adc_seq, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	IRQ_ADC_b2s2
	;------------------
	clrf	BSR		
	;------------------
	bsf		TRISC, 4			; pin input
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------	
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0xF9				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
	goto	IRQ_ADC_step_done
IRQ_ADC_b2s2	
	; step 2 start ADC conversion
	movf	adc_seq, W
	xorlw	0x07
	btfss	STATUS, Z
	goto	IRQ_ADC_b1s1
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0x53				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
	goto	IRQ_ADC_step_done
IRQ_ADC_b1s1
	
	; step 1 charge internal ADC cap
	movf	adc_seq, W
	xorlw	0x09
	btfss	STATUS, Z
	goto	IRQ_ADC_b1s2
	;------------------
	clrf	BSR		
	;------------------
	bsf		TRISB, 0			; pin input
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------	
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0xF9				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
	goto	IRQ_ADC_step_done
IRQ_ADC_b1s2	
	; step 2 start ADC conversion
	movf	adc_seq, W
	xorlw	0x0A
	btfss	STATUS, Z
	goto	IRQ_ADC_step_done
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0x23				; Set selected, ADC on
	movwf	ADCON0		
	incf	adc_seq, F
IRQ_ADC_step_done		
	;------------------
	clrf	BSR		
	;------------------
	
	; if the beacon buzzer timer is not 0 subtract 1
	movf	beacon_b_timer, F
	btfsc	STATUS, Z
	goto	IRQ_beacon_b_done
	decfsz	beacon_b_timer, F
	goto	IRQ_beacon_b_done
	btfsc	ir_status, 7		; M2 bits 7,6 M1 bits 5,4 last update by 0 = pattern gen, 1 = beacon, 2 = direct remote
	goto	IRQ_beacon_b_done
	btfss	ir_status, 6		; M2 bits 7,6 M1 bits 5,4 last update by 0 = pattern gen, 1 = beacon, 2 = direct remote
	goto	IRQ_beacon_b_done
	bsf		TRISB, 5		    ; PWM output off. 		
IRQ_beacon_b_done	

		
	; if the M1 buzzer timer is not 0 subtract 1
	movf	direct_m1_timer, F
	btfsc	STATUS, Z
	goto	IRQ_direct_m1_done
	decfsz	direct_m1_timer, F
	goto	IRQ_direct_m1_done
	btfss	ir_status, 5		; M1 bits 7,6 M1 bits 5,4 last update by 0 = pattern gen, 1 = beacon, 2 = direct remote
	goto	IRQ_direct_m1_done
	btfsc	ir_status, 4		; M1 bits 7,6 M1 bits 5,4 last update by 0 = pattern gen, 1 = beacon, 2 = direct remote
	goto	IRQ_direct_m1_done
	bsf		TRISB, 2		    ; M1 PWM output off. 	works great
IRQ_direct_m1_done	

	; if the M2 buzzer timer is not 0 subtract 1
	movf	direct_m2_timer, F
	btfsc	STATUS, Z
	goto	IRQ_direct_m2_done
	decfsz	direct_m2_timer, F
	goto	IRQ_direct_m2_done
	btfss	ir_status, 7		; M2 bits 7,6 M1 bits 5,4 last update by 0 = pattern gen, 1 = beacon, 2 = direct remote
	goto	IRQ_direct_m2_done
	btfsc	ir_status, 6		; M2 bits 7,6 M1 bits 5,4 last update by 0 = pattern gen, 1 = beacon, 2 = direct remote
	goto	IRQ_direct_m2_done
	bsf		TRISB, 5		    ; M2 PWM output off. 	
IRQ_direct_m2_done	
	
	

	
	; LEDs have 3 time slices based on the 2 bit value turn them on for none, some, or all the slices
	clrf	porta_temp
	clrf	portc_temp
	
	movf	LED1, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	IRQ_LED1r_2
	bsf	portc_temp, 5
	goto	IRQ_LED1r_done	
IRQ_LED1r_2
	btfss	LED1, 1
	goto	IRQ_LED1r_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED1r_done
	bsf		portc_temp, 5
	goto	IRQ_LED1r_done	
IRQ_LED1r_1	
	btfss	LED1, 0
	goto	IRQ_LED1r_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED1r_done
	bsf	portc_temp, 5
IRQ_LED1r_done
	movf	LED1, W
	andlw	0x0C
	xorlw	0x0C
	btfss	STATUS, Z
	goto	IRQ_LED1g_2
	bsf	portc_temp, 6
	goto	IRQ_LED1g_done	
IRQ_LED1g_2
	btfss	LED1, 3
	goto	IRQ_LED1g_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED1g_done
	bsf	portc_temp, 6
	goto	IRQ_LED1g_done	
IRQ_LED1g_1	
	btfss	LED1, 2
	goto	IRQ_LED1g_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED1g_done
	bsf	portc_temp, 6
IRQ_LED1g_done
	movf	LED1, W
	andlw	0x30
	xorlw	0x30
	btfss	STATUS, Z
	goto	IRQ_LED1b_2
	bsf	portc_temp, 7
	goto	IRQ_LED1b_done	
IRQ_LED1b_2
	btfss	LED1, 5
	goto	IRQ_LED1b_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED1b_done
	bsf	portc_temp, 7
	goto	IRQ_LED1b_done	
IRQ_LED1b_1	
	btfss	LED1, 4
	goto	IRQ_LED1b_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED1b_done
	bsf	portc_temp, 7
IRQ_LED1b_done
	
	movf	LED2, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	IRQ_LED2r_2
	bsf	portc_temp, 1
	goto	IRQ_LED2r_done	
IRQ_LED2r_2
	btfss	LED2, 1
	goto	IRQ_LED2r_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED2r_done
	bsf	portc_temp, 1
	goto	IRQ_LED2r_done	
IRQ_LED2r_1	
	btfss	LED2, 0
	goto	IRQ_LED2r_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED2r_done
	bsf	portc_temp, 1
IRQ_LED2r_done
	movf	LED2, W
	andlw	0x0C
	xorlw	0x0C
	btfss	STATUS, Z
	goto	IRQ_LED2g_2
	bsf	portc_temp, 2
	goto	IRQ_LED2g_done	
IRQ_LED2g_2
	btfss	LED2, 3
	goto	IRQ_LED2g_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED2g_done
	bsf	portc_temp, 2
	goto	IRQ_LED2g_done	
IRQ_LED2g_1	
	btfss	LED2, 2
	goto	IRQ_LED2g_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED2g_done
	bsf	portc_temp, 2
IRQ_LED2g_done
	movf	LED2, W
	andlw	0x30
	xorlw	0x30
	btfss	STATUS, Z
	goto	IRQ_LED2b_2
	bsf	portc_temp, 3
	goto	IRQ_LED2b_done	
IRQ_LED2b_2
	btfss	LED2, 5
	goto	IRQ_LED2b_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED2b_done
	bsf	portc_temp, 3
	goto	IRQ_LED2b_done	
IRQ_LED2b_1	
	btfss	LED2, 4
	goto	IRQ_LED2b_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED2b_done
	bsf	portc_temp, 3
IRQ_LED2b_done		
	
	movf	LED3, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	IRQ_LED3r_2
	bsf	porta_temp, 7
	goto	IRQ_LED3r_done	
IRQ_LED3r_2
	btfss	LED3, 1
	goto	IRQ_LED3r_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED3r_done
	bsf	porta_temp, 7
	goto	IRQ_LED3r_done	
IRQ_LED3r_1	
	btfss	LED3, 0
	goto	IRQ_LED3r_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED3r_done
	bsf	porta_temp, 7
IRQ_LED3r_done
	movf	LED3, W
	andlw	0x0C
	xorlw	0x0C
	btfss	STATUS, Z
	goto	IRQ_LED3g_2
	bsf	porta_temp, 6
	goto	IRQ_LED3g_done	
IRQ_LED3g_2
	btfss	LED3, 3
	goto	IRQ_LED3g_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED3g_done
	bsf	porta_temp, 6
	goto	IRQ_LED3g_done	
IRQ_LED3g_1	
	btfss	LED3, 2
	goto	IRQ_LED3g_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED3g_done
	bsf	porta_temp, 6
IRQ_LED3g_done
	movf	LED3, W
	andlw	0x30	
	xorlw	0x30
	btfss	STATUS, Z
	goto	IRQ_LED3b_2
	bsf	portc_temp, 0
	goto	IRQ_LED3b_done	
IRQ_LED3b_2
	btfss	LED3, 5
	goto	IRQ_LED3b_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED3b_done
	bsf	portc_temp, 0
	goto	IRQ_LED3b_done	
IRQ_LED3b_1	
	btfss	LED3, 4
	goto	IRQ_LED3b_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED3b_done
	bsf	portc_temp, 0
IRQ_LED3b_done
	
	movf	LED4, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	IRQ_LED4r_2
	bsf	porta_temp, 2
	goto	IRQ_LED4r_done	
IRQ_LED4r_2
	btfss	LED4, 1
	goto	IRQ_LED4r_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED4r_done
	bsf	porta_temp, 2
	goto	IRQ_LED4r_done	
IRQ_LED4r_1	
	btfss	LED4, 0
	goto	IRQ_LED4r_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED4r_done
	bsf	porta_temp, 2
IRQ_LED4r_done
	movf	LED4, W
	andlw	0x0C
	xorlw	0x0C
	btfss	STATUS, Z
	goto	IRQ_LED4g_2
	bsf	porta_temp, 3
	goto	IRQ_LED4g_done	
IRQ_LED4g_2
	btfss	LED4, 3
	goto	IRQ_LED4g_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED4g_done
	bsf	porta_temp, 3
	goto	IRQ_LED4g_done	
IRQ_LED4g_1	
	btfss	LED4, 2
	goto	IRQ_LED4g_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED4g_done
	bsf	porta_temp, 3
IRQ_LED4g_done
	movf	LED4, W
	andlw	0x30
	xorlw	0x30
	btfss	STATUS, Z
	goto	IRQ_LED4b_2
	bsf	porta_temp, 4
	goto	IRQ_LED4b_done	
IRQ_LED4b_2
	btfss	LED4, 5
	goto	IRQ_LED4b_1
	movf	led_seq, W
	xorlw	0x03
	btfsc	STATUS, Z
	goto	IRQ_LED4b_done
	bsf	porta_temp, 4
	goto	IRQ_LED4b_done	
IRQ_LED4b_1	
	btfss	LED4, 4
	goto	IRQ_LED4b_done
	movf	led_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_LED4b_done
	bsf	porta_temp, 4
IRQ_LED4b_done
	
	
	; check the blink status
	incf	blink_seq, F
	
	movf	LED1, W
	andlw	0xC0
	btfsc	STATUS, Z
	goto	IRQ_blink1_done
	btfss	LED1, 6
	goto	IRQ_blink1_2
	btfsc	LED1, 7
	goto	IRQ_blink1_3
	btfsc	blink_seq, 4
	goto	IRQ_blink1_done
	movlw	0x1F				; turn off all the LED1 bits 
	andwf	portc_temp, F
	goto	IRQ_blink1_done
IRQ_blink1_2
	btfsc	blink_seq, 5
	goto	IRQ_blink1_done
	movlw	0x1F				; turn off all the LED1 bits 
	andwf	portc_temp, F
	goto	IRQ_blink1_done
IRQ_blink1_3
	btfsc	blink_seq, 6
	goto	IRQ_blink1_done
	movlw	0x1F				; turn off all the LED1 bits 
	andwf	portc_temp, F
IRQ_blink1_done	

	movf	LED2, W
	andlw	0xC0
	btfsc	STATUS, Z
	goto	IRQ_blink2_done
	btfss	LED2, 6
	goto	IRQ_blink2_2
	btfsc	LED2, 7
	goto	IRQ_blink2_3
	btfsc	blink_seq, 4
	goto	IRQ_blink2_done
	movlw	0xF1				; turn off all the LED1 bits 
	andwf	portc_temp, F
	goto	IRQ_blink2_done
IRQ_blink2_2
	btfsc	blink_seq, 5
	goto	IRQ_blink2_done
	movlw	0xF1				; turn off all the LED1 bits 
	andwf	portc_temp, F
	goto	IRQ_blink2_done
IRQ_blink2_3
	btfsc	blink_seq, 6
	goto	IRQ_blink2_done
	movlw	0xF1				; turn off all the LED1 bits 
	andwf	portc_temp, F
IRQ_blink2_done	
	
	movf	LED3, W
	andlw	0xC0
	btfsc	STATUS, Z
	goto	IRQ_blink3_done
	btfss	LED3, 6
	goto	IRQ_blink3_2
	btfsc	LED3, 7
	goto	IRQ_blink3_3
	btfsc	blink_seq, 4
	goto	IRQ_blink3_done
	bcf	portc_temp, 0
	movlw	0x3F				; turn off all the LED1 bits 
	andwf	porta_temp, F
	goto	IRQ_blink3_done
IRQ_blink3_2
	btfsc	blink_seq, 5
	goto	IRQ_blink3_done
	bcf	portc_temp, 0
	movlw	0x3F				; turn off all the LED1 bits 
	andwf	porta_temp, F
	goto	IRQ_blink3_done
IRQ_blink3_3
	btfsc	blink_seq, 6
	goto	IRQ_blink3_done
	bcf	portc_temp, 0
	movlw	0x3F				; turn off all the LED1 bits 
	andwf	porta_temp, F
IRQ_blink3_done		

	movf	LED4, W
	andlw	0xC0
	btfsc	STATUS, Z
	goto	IRQ_blink4_done
	btfss	LED4, 6
	goto	IRQ_blink4_2
	btfsc	LED4, 7
	goto	IRQ_blink4_3
	btfsc	blink_seq, 4
	goto	IRQ_blink4_done
	movlw	0xE3				; turn off all the LED1 bits 
	andwf	porta_temp, F
	goto	IRQ_blink4_done
IRQ_blink4_2
	btfsc	blink_seq, 5
	goto	IRQ_blink4_done
	movlw	0xE3				; turn off all the LED1 bits 
	andwf	porta_temp, F
	goto	IRQ_blink4_done
IRQ_blink4_3
	btfsc	blink_seq, 6
	goto	IRQ_blink4_done
	movlw	0xE3				; turn off all the LED1 bits 
	andwf	porta_temp, F
IRQ_blink4_done	
	
	
	; Update the LED outputs 
	movlw	0xDC				; set all LED bits high (led off)
	iorwf   LATA, F
	; bits 0,1 not LEDs
	btfsc	porta_temp, 2
	bcf		LATA, 2
	btfsc	porta_temp, 3
	bcf		LATA, 3
	btfsc	porta_temp, 4
	bcf		LATA, 4
	; bit 5 is not a LED
	btfsc	porta_temp, 6
	bcf		LATA, 6
	btfsc	porta_temp, 7
	bcf		LATA, 7

	movlw	0xEF				; set all LED bits high (led off)
	iorwf   LATC, F
	btfsc	portc_temp, 0
	bcf		LATC, 0
	btfsc	portc_temp, 1
	bcf		LATC, 1
	btfsc	portc_temp, 2
	bcf		LATC, 2
	btfsc	portc_temp, 3
	bcf		LATC, 3
	; bit 4 is not a LED
	btfsc	portc_temp, 5
	bcf		LATC, 5
	btfsc	portc_temp, 6
	bcf		LATC, 6
	btfsc	portc_temp, 7
	bcf		LATC, 7
	
	
	; update the led seq and set back to 3 if = to 0
	decfsz	led_seq, F
	goto	IRQ_led_done
	movlw	0x03
	movwf	led_seq
IRQ_led_done
	
	; update the becon timer 
	decfsz	beacon_timer_l, F
	goto	IRQ_beacon_done
	movf	beacon_timer_h, W
	btfsc	STATUS, Z
	goto	IRQ_beacon_send
	decf	beacon_timer_h, F
	goto	IRQ_beacon_done
IRQ_beacon_send	
	btfsc	ir_status, 2		; check if beacon is disabled
	goto	IRQ_beacon_reset
	btfsc	ir_status, 0		; busy bit
	goto	IRQ_beacon_reset		; IR was busy so back off and try again next time
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data. 
	clrf	ir_cmd				; beacon cmd
	clrf	ir_data				; command data (not used for beacon)
	bsf		ir_status, 1		; set the calc bit	
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	bsf		PIE3, TX2IE			; enable Uart2 transmit IRQ	
	;------------------
	clrf	BSR		
	;------------------
IRQ_beacon_reset	
	movlw	BEACON_TIME_L
	movwf	beacon_timer_l
	movlw	BEACON_TIME_H
	movwf	beacon_timer_h
	
IRQ_beacon_done	
	
IRQ_not_TMR0
	
	
	
	
	;******************************************************************
	; check if TX2 IRQ
	;******************************************************************
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	btfss	PIE3, TX2IE			; if the IRQ is not enabled ignore this check
	goto	IRQ_not_TX2
	btfss	PIR3, TX2IF			; check if IRQ is currently set
	goto	IRQ_not_TX2
	bcf	PIR3, TX2IF	
	;------------------
	clrf	BSR		
	;------------------		
	btfss	ir_status, 1		; calc bit set init all the regs
	goto	IRQ_TX2_no_calc
	; calculate the checksum byte
	movlw	0xA0				; M and S chars
	movwf	ir_chksum
	movf	ir_cmd, W
	addwf	ir_chksum, F
	movf	badge_id, W
	addwf	ir_chksum, F
	movf	ir_data, W
	addwf	ir_chksum, F
	comf	ir_chksum, F
	incf	ir_chksum, F
	movlw	0x07
	movwf	ir_tx_seq	
	bcf		ir_status, 1		; calc done clear bit
IRQ_TX2_no_calc	
	
	; check if more bytes to send
	decfsz	ir_tx_seq, F
	goto	IRQ_TX2_send
IRQ_TX2_stop	
	; all bytes sent stop TX
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	bcf	PIE3, TX2IE			; disable Uart2 transmit IRQ	
	bcf	PIR3, TX2IF	
	;------------------
	clrf	BSR		
	;------------------		
	bcf		ir_status, 0		; clear busy bit
	goto	IRQ_not_TX2	
	
IRQ_TX2_send	
	movf	ir_tx_seq, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	IRQ_TX2_send_S
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	movlw	0x4D				; M
	movwf	TX2REG
	;------------------
	clrf	BSR		
	;------------------
	goto	IRQ_not_TX2		
IRQ_TX2_send_S
	movf	ir_tx_seq, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	IRQ_TX2_send_cmd
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	movlw	0x53				; S
	movwf	TX2REG
	;------------------
	clrf	BSR		
	;------------------
	goto	IRQ_not_TX2		
IRQ_TX2_send_cmd	
	movf	ir_tx_seq, W
	xorlw	0x04
	btfss	STATUS, Z
	goto	IRQ_TX2_send_id
	clrf	FSR1H
	movlw	ir_cmd
	movwf	FSR1L
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	movf	INDF1, W
	movwf	TX2REG
	;------------------
	clrf	BSR		
	;------------------
	goto	IRQ_not_TX2	
IRQ_TX2_send_id	
	movf	ir_tx_seq, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	IRQ_TX2_send_data
	clrf	FSR1H
	movlw	badge_id
	movwf	FSR1L
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	movf	INDF1, W
	movwf	TX2REG
	;------------------
	clrf	BSR		
	;------------------
	goto	IRQ_not_TX2	
IRQ_TX2_send_data	
	movf	ir_tx_seq, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	IRQ_TX2_send_chksum
	clrf	FSR1H
	movlw	ir_data
	movwf	FSR1L
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	movf	INDF1, W
	movwf	TX2REG
	;------------------
	clrf	BSR		
	;------------------
	goto	IRQ_not_TX2
IRQ_TX2_send_chksum
	movf	ir_tx_seq, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	IRQ_TX2_stop		; if the value is not 1,2,3,4,5,6 then something really bad happened and it should stop now
	clrf	FSR1H
	movlw	ir_chksum
	movwf	FSR1L
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	movf	INDF1, W
	movwf	TX2REG
	;------------------
	clrf	BSR		
	;------------------
IRQ_not_TX2

		
	;******************************************************************
	; check if RX2 IRQ
	;******************************************************************
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	btfss	PIR3, RC2IF			; check if IRQ is currently set
	goto	IRQ_not_RX2
	bcf	PIR3, RC2IF	
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	btfss	RC2STA, FERR
	goto	IRQ_RX2_no_FERR
	movf	RC2REG, W			; read the reg to pop the bad byte off the stack
	goto	IRQ_RX2_packet_bad
IRQ_RX2_no_FERR
	btfss	RC2STA, OERR
	goto	IRQ_RX2_no_OERR
	bcf	RC2STA, CREN		; disable and enable CREN to clear OERR 
	bsf	RC2STA, CREN		
	goto	IRQ_RX2_packet_bad
IRQ_RX2_no_OERR		
	;------------------
	clrf	BSR		
	;------------------
	; point the FSR to the RC reg
	movlw	HIGH RC2REG
	movwf	FSR1H
	movlw	LOW RC2REG
	movwf	FSR1L
	movf	ir_rx_seq, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	IRQ_RX2_4
	movf	INDF1, W			; read the RC2REG
	xorlw	0x4D				; M
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_bad
	decf	ir_rx_seq, F
	goto	IRQ_not_RX2
IRQ_RX2_4	
	movf	ir_rx_seq, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	IRQ_RX2_3
	movf	INDF1, W			; read the RC2REG
	xorlw	0x53				; S
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_bad
	decf	ir_rx_seq, F
	goto	IRQ_not_RX2
IRQ_RX2_3	
	clrf	FSR0H
	movlw	ir_rx_seq			; select the reg based of the seq number
	movwf	FSR0L
	movf	ir_rx_seq, W
	addwf	FSR0L, F
	movf	INDF1, W			; read the RC2REG
	movwf	INDF0				; save the value to the selected reg	
	decfsz	ir_rx_seq, F
	goto	IRQ_not_RX2
	; calculate the checksum byte
	movlw	0xA0				; M and S chars
	movwf	temp
	movf	ir_rx_cmd, W
	addwf	temp, F
	movf	ir_rx_id, W
	addwf	temp, F
	movf	ir_rx_data, W
	addwf	temp, F
	movf	ir_rx_chksum, W
	addwf	temp, F
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_bad
	; check the packet type and data since it is good
	movf	ir_rx_id, W
	xorwf	badge_id, W			; check for a reflection from this badge
	btfsc	STATUS, Z
	goto	IRQ_RX2_packet_bad
	movf	ir_rx_cmd, W
	;xorlw	0x00				; beacon
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_direct_remote
	;movf	ir_rx_data, W
	;xorwf	0x00, W				; check data
	;btfsc	STATUS, Z
	;goto	IRQ_RX2_packet_bad
	btfsc	ir_status, 3		; check if beacon is disabled
	goto	IRQ_RX2_packet_bad
	
	;------------------
	movlw	d'6'
	movwf	BSR		
	;------------------	
	; set up PWM engine
	movlw	IR_B_ON_PWM
	movwf	PWM4DCH	
	;------------------
	clrf	BSR
	;------------------
	bcf		ir_status, 7
	bsf		ir_status, 6		; set souce of PWM enable as beacon
	movlw	IR_B_ON_TIME
	movwf	beacon_b_timer		; set up timer to turn off beacon buz
	bcf		TRISB, 5		    ; PWM output on. 
	
	goto	IRQ_RX2_packet_bad
	
IRQ_RX2_packet_direct_remote
	movf	ir_rx_cmd, W
	xorlw	0x01				; direct remote
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_display
	
	
	btfss	ir_rx_data, 0
	goto	IRQ_RX2_packet_direct_m2
	;------------------
	movlw	d'6'
	movwf	BSR		
	;------------------	
	; set up PWM engine
	movlw	IR_DIRECT_RMT_ON_PWM
	movwf	PWM3DCH	
	;------------------
	clrf	BSR
	;------------------
	bsf		ir_status, 5
	bcf		ir_status, 4		; set souce of PWM enable as direct remote
	movlw	IR_DIRECT_RMT_ON_TIME
	movwf	direct_m1_timer		; set up timer to turn off buz if no new signal
	bcf		TRISB, 2		    ; M1 PWM output on. 
	
IRQ_RX2_packet_direct_m2	
	btfss	ir_rx_data, 1
	goto	IRQ_RX2_packet_direct_done
	;------------------
	movlw	d'6'
	movwf	BSR		
	;------------------	
	; set up PWM engine
	movlw	IR_DIRECT_RMT_ON_PWM
	movwf	PWM4DCH	
	;------------------
	clrf	BSR
	;------------------
	bsf		ir_status, 7
	bcf		ir_status, 6		; set souce of PWM enable as direct remote
	movlw	IR_DIRECT_RMT_ON_TIME
	movwf	direct_m2_timer		; set up timer to turn off buz if no new signal
	bcf		TRISB, 5		    ; M2 PWM output on. 
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_display
	movf	ir_rx_cmd, W
	xorlw	0x02				; set led mode
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_led_speed_l	
	movf	ir_rx_data, W
	movwf	led_mode_reg
	goto	IRQ_RX2_packet_direct_done
	
IRQ_RX2_packet_set_led_speed_l
	movf	ir_rx_cmd, W
	xorlw	0x03				; set speed low
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_led_speed_h	
	movf	ir_rx_data, W
	movwf	speed_low
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_led_speed_h
	movf	ir_rx_cmd, W
	xorlw	0x04				; set speed high
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_led1	
	movf	ir_rx_data, W
	andlw	0x0F
	movwf	speed_high
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_led1
	movf	ir_rx_cmd, W
	xorlw	0x05				; set cust LED 1
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_led2	
	movf	ir_rx_data, W
	movwf	cust_led1
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_led2
	movf	ir_rx_cmd, W
	xorlw	0x06				; set cust LED 2
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_led3	
	movf	ir_rx_data, W
	movwf	cust_led2
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_led3
	movf	ir_rx_cmd, W
	xorlw	0x07				; set cust LED 3
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_led4	
	movf	ir_rx_data, W
	movwf	cust_led3
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_led4
	movf	ir_rx_cmd, W
	xorlw	0x08				; set cust LED 4
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_vibe	
	movf	ir_rx_data, W
	movwf	cust_led4
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_vibe
	movf	ir_rx_cmd, W
	xorlw	0x09				; set and start vibe
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_vibe_l	
	movf	ir_rx_data, W
	movwf	vibe_mode
	movlw	0x01
	movwf	vibe_cycle
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_vibe_l
	movf	ir_rx_cmd, W
	xorlw	0x0A				; set vibe speed low
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_set_vibe_h	
	movf	ir_rx_data, W
	movwf	vibe_speed_l
	goto	IRQ_RX2_packet_direct_done

IRQ_RX2_packet_set_vibe_h
	movf	ir_rx_cmd, W
	xorlw	0x0B				; set vibe high
	btfss	STATUS, Z
	goto	IRQ_RX2_packet_direct_done	
	movf	ir_rx_data, W
	andlw	0x0F
	movwf	vibe_speed_h
	goto	IRQ_RX2_packet_direct_done
	
	
IRQ_RX2_packet_direct_done

	;goto	IRQ_RX2_packet_bad
	
IRQ_RX2_packet_bad
	; flush the packet here as it is bad
	clrf	ir_rx_id
	clrf	ir_rx_data
	clrf	ir_rx_cmd
	clrf	ir_rx_chksum
	incf	ir_rx_chksum, F
	movlw	0x06
	movwf	ir_rx_seq
	
IRQ_not_RX2
	
	retfie
;###########################################################################################################################
; end of IRQ code
;###########################################################################################################################	
	
START
	; init crap
	;------------------
	clrf    BSR			    ; bank 0
	;------------------
	clrf	INTCON			    ; disable interupts
	movlw	0xDC				
	movwf	LATA			    ; disable the LEDs and IR sender
	clrf	LATB			    ; disable the LEDs and motors
	movlw	0xEF				
	movwf	LATC			    ; disable the LEDs

	movlw	0x22
	movwf	TRISA			    ; 0 = output
	movlw	0xBF
	movwf	TRISB			    ; 0 = output (PWM outputs off set to inputs to save power) 
	movlw	0x10
	movwf	TRISC			    ; 0 = output
	movlw	0xFF
	movwf	TRISE			    ; 0 = output
	
	clrf	delay_cntH
	clrf	delay_cntL
	clrf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	movlw	0x03
	movwf	led_seq
	movlw	BEACON_TIME_L
	movwf	beacon_timer_l
	movlw	BEACON_TIME_H
	movwf	beacon_timer_h
	clrf	ir_status
	movlw	0x05
	movwf	ir_rx_seq
	clrf	mode_ctl
	clrf	mode_reg
	clrf	no_press_cnt
	clrf	vibe_cycle
	clrf	sequence 
	clrf	vibe_sequence

	
	; load setting register from flash
	clrf	FSR0H				; address of first ram reg
	movlw	START_OF_REGS
	movwf	FSR0L	
	movlw	0x9f				; address of start of SAF (note flash address + 0x8000)
	movwf	FSR1H
	movlw	0x80
	movwf	FSR1L
load_loop	
	comf	INDF1, W
	btfss	STATUS, Z			; if the value is anything but FF go load all the regs
	goto	load_regs		
	incf	FSR0L, F
	incf	FSR1L, F
	movf	FSR0L, W
	xorlw	0x70				; 1 past the end of the ram space
	btfss	STATUS, Z
	goto	load_loop	
	; all locations were FF so flash is blank so load defaults
	clrf	vibe_mode
	movlw	0x01
	movwf	vibe_rpt
	clrf	led_mode_reg
	movlw	0x20
	movwf	speed_low
	movwf	vibe_speed_l
	clrf	speed_high
	clrf	vibe_speed_h
	movlw	0x43
	movwf	cust_led1
	movlw	0x8C
	movwf	cust_led2
	movlw	0x01
	movwf	cust_led3
	movlw	0x03
	movwf	cust_led4
	goto	load_done
load_regs			
	
	clrf	FSR0H				; address of first ram reg
	movlw	START_OF_REGS
	movwf	FSR0L	
	movlw	0x9f				; address of start of SAF (note flash address + 0x8000)
	movwf	FSR1H
	movlw	0x80
	movwf	FSR1L
load_loop2
	movf	INDF1, W
	movwf	INDF0
	incf	FSR0L, F
	incf	FSR1L, F
	movf	FSR0L, W
	xorlw	0x70				; 1 past the end of the ram space
	btfss	STATUS, Z
	goto	load_loop2	
load_done		
	; move timer for first loop
	movf	speed_low, W
	movwf	led_timer_low
	movf	speed_high, W
	movwf	led_timer_high
	movf	vibe_speed_l, W
	movwf	vibe_timer_low
	movf	vibe_speed_h, W
	movwf	vibe_timer_high
	
	
	
	
	; TODO for debug remove this
	;movlw	0x07
	;movwf	led_mode_reg
	; end TODO
	
	;------------------
	movlw	d'18'
	movwf	BSR		
	;------------------		
	movlw	0x82
	movwf	FVRCON				; FVR on, temp indicator off, temp low range, cmp buffer off, ADC buffer on 2x
FVR_startup_loop
	btfss	FVRCON, 6
	goto	FVR_startup_loop
	
	;------------------
	movlw	d'1'
	movwf	BSR		
	;------------------
	movlw	0x33
	movwf	ADCON1				; Left justified, ADCRC, FVR + ref
	clrf	ADACT				; no auto conversion
	clrf	adc_seq	
	; 0x05	RA1, A 
	; 0x15	RA5, Set
	; 0x21	RB0, B
	; 0x51	RC4, Sel
	; 0xED	AVss
	; 0xF9	FVR1 buffer
	movlw	0xF9				; AVss selected, ADC on
	movwf	ADCON0
	
	;------------------
	movlw	d'2'
	movwf	BSR		
	;------------------
	; init LFSR
	movlw	0xFF
	movwf	LFSR_0
	movwf	LFSR_1
	movwf	LFSR_2
	movwf	LFSR_3

	;------------------
	movlw	d'5'
	movwf	BSR		
	;------------------
	; set up timer 2 to roll over on a 38kHz period (37.9 something)
	clrf	TMR2
	movlw	0xD3			    ; period reg 
	movwf	PR2
	movlw	0x01			    ; select Fosc/4 as the input clock
	movwf	T2CLKCON
	clrf	T2HLT			    ; mode 0 (free run standard) 
	clrf	T2RST			    ; not used
	movlw	0x80			    ; timer 2 on, 1:1 pre, 1:1 post
	movwf	T2CON

	;------------------
	movlw	d'6'
	movwf	BSR		
	;------------------	
	; set up PWM engine
	movlw	0xFF			    
	movwf	PWM3DCH
	movlw	0xC0
	movwf	PWM3DCL
	movlw	0x80			    ; engine on, active high
	movwf	PWM3CON

	movlw	0xFF
	movwf	PWM4DCH
	movlw	0xC0
	movwf	PWM4DCL
	movlw	0x80			    ; engine on, active high
	movwf	PWM4CON

	movlw	IR_PULSE_WIDTH
	movwf	PWM5DCH
	movlw	0xC0
	movwf	PWM5DCL
	movlw	0x80			    ; engine on, active high
	movwf	PWM5CON
	
	
	;------------------
	movlw	d'11'
	movwf	BSR		
	;------------------	
	; Set up TMR0 (1/180th of a sec for 3 slices every 1/60th of a sec) 
	movlw	0xAC
	movwf	TMR0H
	clrf	TMR0L	
	movlw	0x90					; LFINTOSC 31kHz, no sync, 1:1 prescaler
	movwf	T0CON1
	movlw	0x80					; timer on, 8 bit, 1:1 postscaler
	movwf	T0CON0

	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	; set up interupts
	movlw	0x20					; TMR0
	movwf	PIE0
	clrf	PIR0
	movlw	0x01					; ADC
	movwf	PIE1
	clrf	PIR1
	movlw	0x80					; RC2
	movwf	PIE3
	clrf	PIR3

	;------------------
	movlw	d'16'
	movwf	BSR		
	;------------------	
	; get the user ID data (badge ID) 
	movlw	0x80
	movwf	NVMADRH
	clrf	NVMADRL
	movlw	0x41
	movwf	NVMCON1					; read the config space selected
	movf	NVMDATL, W
	;------------------
	clrf	BSR		
	;------------------	
	movwf	badge_id
	
	;------------------
	movlw	d'20'
	movwf	BSR		
	;------------------
	; set up uart 2
	movlw	0x20
	movwf	TX2STA					; tx on, 8 bit tx, low baud 
	clrf	BAUD2CON				; Pol normal, 8 bit baud, 
	movlw	0xA6
	movwf	SP2BRGL					; baud rate for 3000 baud -0.2% off
	clrf	SP2BRGH
	movlw	0x90
	movwf	RC2STA					; UART on, 8 bit rx, CREN on
	
	;------------------
	movlw	d'60'
	movwf	BSR		
	;------------------
	; configure CLC for IRDA output
	
	movlw	0x13
	movwf	CLC1SEL0				; data 1 PWM5
	movlw	0x21
	movwf	CLC1SEL1				; data 2 TX2
	movlw	0x13
	movwf	CLC1SEL2				; data 3 PWM5
	movlw	0x13
	movwf	CLC1SEL3				; data 4 PWM5	
	movlw	0x02
	movwf	CLC1GLS0				; data 1 connected to input 1 normal
	movlw	0x08
	movwf	CLC1GLS1				; data 2 connected to input 2 normal
	movlw	0x00
	movwf	CLC1GLS2				; nothing connected to input 3
	movlw	0x00
	movwf	CLC1GLS3				; nothing connected to input 4
	movlw	0x0E
	movwf	CLC1POL					; inputs 1, 2 normal 3, 4 inverted, and output NOT inverted
	movlw	0x82					; CLC enabled, no IRQs, 4 input 
	movwf	CLC1CON
	
	;------------------
	movlw	d'61'
	movwf	BSR		
	;------------------
	; unlock bits
	movlw	0x55
	movwf	PPSLOCK
	movlw	0xAA
	movwf	PPSLOCK
	bcf	PPSLOCK, PPSLOCKED
	
	; input PPS signals
	movlw	0x09					; RB1
	movwf	RX2DTPPS	
	movlw	0x0B					; RB3
	movwf	SSP1CLKPPS
	movlw	0x0C					; RB4
	movwf	SSP1DATPPS
	movlw	0x0F					; RB7
	movwf	RX1DTPPS
	
	;------------------
	movlw	d'62'
	movwf	BSR		
	;------------------	
	movlw	0x22
	movwf	ANSELA				; 0 = digital, 1 = analog 
	movlw	0x01
	movwf	ANSELB				; 0 = digital, 1 = analog 
	movlw	0x10
	movwf	ANSELC				; 0 = digital, 1 = analog 

	; output PPS signals
	movlw	0x01				; CLC1OUT
;	movwf	RC6PPS				; temp for debug
	movwf	RA0PPS				
	movlw	0x0B				; PWM3OUT
	movwf	RB2PPS				
	movlw	0x15				; SCL
	movwf	RB3PPS
	movlw	0x16				; SDA
	movwf	RB4PPS
	movlw	0x0C				; PWM4OUT
	movwf	RB5PPS
	movlw	0x0F				; TX
	movwf	RB6PPS
		
	;------------------
	movlw	d'61'
	movwf	BSR		
	;------------------	
	; lock bits
	movlw	0x55
	movwf	PPSLOCK
	movlw	0xAA
	movwf	PPSLOCK
	bsf	PPSLOCK, PPSLOCKED	
	
 	;------------------
	clrf    BSR					; bank 0
	;------------------
	movlw	0xC0
	movwf	INTCON			    ; enable interrupts
	
	
	; firmware version display here	
	movlw	ver_a
	movwf	LED1
	movlw	ver_b
	movwf	LED2
	movlw	ver_c
	movwf	LED3
	movlw	ver_d
	movwf	LED4	
	clrf	delay_cntH
	movlw	0x5A
	movwf	delay_cntL
	call	_Delay	
	; M1 selftest
	movlw	0x18
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page	
	movlw	0x07
	call	_Set_M1
	clrf	PCLATH
	clrf	delay_cntH
	movlw	0x12
	movwf	delay_cntL
	call	_Delay	
	movlw	0x18
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page
	movlw	0x00
	call	_Set_M1
	clrf	PCLATH

#ifdef __LED_TEST_MODE__	
debug_stop
	goto	debug_stop
#endif
	
	clrf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	;LED1 selftest
	movlw	0x03
	movwf	LED1
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x0C
	movwf	LED1
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x30
	movwf	LED1
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	clrf	LED1
	;LED2 selftest
	movlw	0x03
	movwf	LED2
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x0C
	movwf	LED2
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x30
	movwf	LED2
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	clrf	LED2
	;LED3 selftest
	movlw	0x03
	movwf	LED3
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x0C
	movwf	LED3
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x30
	movwf	LED3
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	clrf	LED3	
	;LED4 selftest
	movlw	0x03
	movwf	LED4
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x0C
	movwf	LED4
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	movlw	0x30
	movwf	LED4
	movlw	0x2d
	movwf	delay_cntL
	call	_Delay	
	clrf	LED4	
	; M2 test selftest
	movlw	0x18
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page
	movlw	0x07
	call	_Set_M2
	clrf	PCLATH
	clrf	delay_cntH
	movlw	0x12
	movwf	delay_cntL
	call	_Delay	
	movlw	0x18
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page
	movlw	0x00
	call	_Set_M2
	
	movlw	0x08
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page	
	goto	MAINLOOP

;#########################################################	
; delay value in W * 1/60s (max 4.24s) 
;#########################################################	
_Delay
	movf	delay_cntH, F		; high byte assumed cleared based on above	
	btfss	STATUS, Z
	goto	_Delay
	movf	delay_cntL, F		; high byte assumed cleared based on above	
	btfss	STATUS, Z
	goto	_Delay
	
	return
	

	
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; start of page 1
	org		0800h
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
MAINLOOP
	
	btfsc	buttons, 4			; make sure values have all been updated before evaluating this
	; buttons,0 = B
	; buttons,1 = Select
	; buttons,2 = Set
	; buttons,3 = A
	; buttons,4 = Values updated and ready to read	
	goto	debounce_check_start
	
	movlw	0x10
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page
	goto	MAINLOOP_LEDS
	
debounce_check_start
	; debounce the inputs by not counting presses for x cycles
	movf	no_press_cnt, W
	btfsc	STATUS, Z
	goto	debounce_check_done
	decf	no_press_cnt, F	
	; if cont mode is set and set button is not pressed skip debounce check (support holding the button(s) down)
	btfsc	buttons, 2
	goto	button_ctl_done
	btfss	mode_ctl, 7
	goto	button_ctl_done
debounce_check_done
	

	; if in reg select and mode 13 clear out ir_data_temp and pre-pop with data	
	movf	mode_ctl, W
	andlw	0xFC				
	btfss	STATUS, Z
	goto	reg_set_no_prepop_13
	movf	mode_reg, W
	xorlw	0x13				; beacon vibe disable (use IR data temp as a temp var) 
	btfss	STATUS, Z
	goto	reg_set_no_prepop_13
	clrf	ir_data_temp
	btfsc	ir_status, 3
	bsf		ir_data_temp, 0
reg_set_no_prepop_13
	
	; check which register banks to use
	clrf	FSR1H
	movf	mode_ctl, W
	andlw	0xFC
	btfss	STATUS, Z
	goto	reg_set_mode_0
	; if mode 0 to 3 use the mode reg for the led display
	movlw	mode_reg
	movwf	FSR1L
	goto	reg_set_done
reg_set_mode_0	
	movf	mode_reg, W
	xorlw	0x01				; speed reg
	btfss	STATUS, Z
	goto	reg_set_mode_2
	; speed reg
	movlw	speed_low	
	movwf	FSR1L
	goto	reg_set_done
reg_set_mode_2	
	movf	mode_reg, W
	xorlw	0x02				; custom led reg
	btfss	STATUS, Z
	goto	reg_set_mode_3
	goto	reg_set_mode_3_do
reg_set_mode_3	
	movf	mode_reg, W
	xorlw	0x03				; custom led reg (blink)
	btfss	STATUS, Z
	goto	reg_set_mode_4
reg_set_mode_3_do	
	movlw	cust_led4
	movwf	FSR1L
	goto	reg_set_done
reg_set_mode_4
	movf	mode_reg, W
	xorlw	0x04				; vibe mode reg
	btfss	STATUS, Z
	goto	reg_set_mode_5
	; vibe mode reg
	movlw	vibe_mode	
	movwf	FSR1L
	goto	reg_set_done
reg_set_mode_5
	movf	mode_reg, W
	xorlw	0x05				; vibe repeat count
	btfss	STATUS, Z
	goto	reg_set_mode_6
	; vibe repeat count
	movlw	vibe_rpt	
	movwf	FSR1L
	goto	reg_set_done
reg_set_mode_6
	movf	mode_reg, W
	xorlw	0x06				; vibe speed regs
	btfss	STATUS, Z
	goto	reg_set_mode_7
	; vibe speed regs
	movlw	vibe_speed_l	
	movwf	FSR1L
	goto	reg_set_done
reg_set_mode_7
	; 7 not used
	; 8 not used
	movf	mode_reg, W
	xorlw	0x09				; rmt display mode
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x0A				; rmt speed l
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x0B				; rmt speed h
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x0C				; rmt LED1
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x0D				; rmt LED2
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x0E				; rmt LED3
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x0F				; rmt LED4
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x10				; rmt vibe
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x11				; rmt vibe speed l
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	movf	mode_reg, W
	xorlw	0x12				; rmt vibe speed h
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do	
	movf	mode_reg, W
	xorlw	0x13				; beacon vibe disable (use IR data temp as a temp var) 
	btfsc	STATUS, Z
	goto	reg_set_mode_9_do
	goto	reg_set_mode_A
reg_set_mode_9_do	
	; temporaray IR data reg var
	movlw	ir_data_temp	
	movwf	FSR1L
	goto	reg_set_done
reg_set_mode_A
	
		
	; for mode 4 to 7 use led mode reg (default)
	movlw	led_mode_reg
	movwf	FSR1L
	;goto	reg_set_done
reg_set_done	
	
button_ctl_chk_start	
	; check if currently in run mode see if set button was pressed
	movf	mode_ctl, W
	btfss	STATUS, Z
	goto	button_ctl_start
	movf	buttons, W
	xorlw	0x14				; only set button pressed
	btfss	STATUS, Z
	goto	button_ctl_done	
	incf	mode_ctl, F	
	goto	button_update_leds_8bit	
button_ctl_start	
	
	; check what mode of input is selected and branch there
	movf	mode_ctl, W
	andlw	0xFC				; mode reg is always 8 bit 
	btfsc	STATUS, Z
	goto	button_ctl_8bit
	movf	mode_reg, W
	xorlw	0x01				; speed reg
	btfsc	STATUS, Z
	goto	button_ctl_12bit
	movf	mode_reg, W
	xorlw	0x02				; custom color reg
	btfsc	STATUS, Z
	goto	button_ctl_24bit
	movf	mode_reg, W
	xorlw	0x03				; custom color reg (blink)
	btfsc	STATUS, Z
	goto	button_ctl_2x4bit
	movf	mode_reg, W
	xorlw	0x06				; vibe speed reg
	btfsc	STATUS, Z
	goto	button_ctl_12bit
	movf	mode_reg, W
	xorlw	0x07				; save vars
	btfsc	STATUS, Z
	goto	button_ctl_save_vars
	movf	mode_reg, W
	xorlw	0x08				; direct remote
	btfsc	STATUS, Z
	goto	button_ctl_direct_remote
	; all other values are assumed to be 8 bit (led mode reg is the default for unused address and is 8 bit) 
	
	; check if in register select and apply value as needed for A and B, advance for Select, or go to reg set if set
button_ctl_8bit
	movf	buttons, W
	xorlw	0x14				; only set button pressed
	btfss	STATUS, Z
	goto	button_ctl_8bit_sel
	movf	mode_ctl, W
	andlw	0xFC
	btfss	STATUS, Z
	goto	button_ctl_8bit_all_done	
	movf	mode_reg, W
	xorlw	0x01				; speed reg
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_1
	movlw	0x04	
	movwf	mode_ctl
	goto	button_update_leds_8bit		
button_ctl_8bit_not_mode_1
	movf	mode_reg, W
	xorlw	0x02				; custom color
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_2
	movlw	0x04	
	movwf	mode_ctl
	goto	button_update_leds_8bit		
button_ctl_8bit_not_mode_2
	movf	mode_reg, W
	xorlw	0x03				; custom color (blink)
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_3
	movlw	0x04	
	movwf	mode_ctl
	goto	button_update_leds_2x4bit		
button_ctl_8bit_not_mode_3	
	movf	mode_reg, W
	xorlw	0x06				; vibe speed reg
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_6
	movlw	0x04	
	movwf	mode_ctl
	goto	button_update_leds_8bit		
button_ctl_8bit_not_mode_6
	movlw	0x05	
	movwf	mode_ctl
	goto	button_update_leds_8bit		
	
button_ctl_8bit_all_done	
	movf	mode_reg, W
	xorlw	0x04				; vibe pattern
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_4	
	movf	vibe_rpt, W
	movwf	vibe_cycle	
	btfsc	STATUS, Z
	incf	vibe_cycle, F
	clrf	mode_ctl
	goto	button_ctl_done	
button_ctl_8bit_not_mode_4		
	movf	mode_reg, W
	xorlw	0x09				; rmt display mode
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_9
button_ctl_8bit_wait_mode_9
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_9		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x02		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_9		
	movf	mode_reg, W
	xorlw	0x0A				; rmt speed l
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_A
button_ctl_8bit_wait_mode_A
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_A		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x03		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_A	
	movf	mode_reg, W
	xorlw	0x0B				; rmt speed h
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_B
button_ctl_8bit_wait_mode_B
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_B		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x04		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_B	
	movf	mode_reg, W
	xorlw	0x0C				; rmt led 1
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_C
button_ctl_8bit_wait_mode_C
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_C		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x05		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_C
	movf	mode_reg, W
	xorlw	0x0D				; rmt led 2
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_D
button_ctl_8bit_wait_mode_D
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_D		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x06		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_D
	movf	mode_reg, W
	xorlw	0x0E				; rmt led 3
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_E
button_ctl_8bit_wait_mode_E
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_E		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x07		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_E
	movf	mode_reg, W
	xorlw	0x0F				; rmt led 4
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_F
button_ctl_8bit_wait_mode_F
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_F		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x08		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_F	
	movf	mode_reg, W
	xorlw	0x10				; rmt vibe
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_10
button_ctl_8bit_wait_mode_10
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_10		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x09		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_10
	movf	mode_reg, W
	xorlw	0x11				; rmt vibe speed l
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_11
button_ctl_8bit_wait_mode_11
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_11		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x0A		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_11
	movf	mode_reg, W
	xorlw	0x12				; rmt vibe speed h
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_12
button_ctl_8bit_wait_mode_12
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_8bit_wait_mode_12		; IR was busy so wait till done
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x0B		
	movwf	ir_cmd				; set rmt cmd
	goto	button_ctl_send_rmt_IR_cmd	
button_ctl_8bit_not_mode_12
	movf	mode_reg, W
	xorlw	0x13				; beacon vibe disable bit
	btfss	STATUS, Z
	goto	button_ctl_8bit_not_mode_13
	btfss	ir_data_temp, 0
	bcf		ir_status, 3		; enable local beacon RX functions	
	btfsc	ir_data_temp, 0
	bsf		ir_status, 3		; disable local beacon RX functions	
	clrf	mode_ctl
	goto	button_ctl_done	
button_ctl_8bit_not_mode_13

	
	
	clrf	mode_ctl
	goto	button_ctl_done
	
	
button_ctl_send_rmt_IR_cmd	
	movf	ir_data_temp, W
	movwf	ir_data				; command data (not used for beacon)
	bsf		ir_status, 1		; set the calc bit		
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	bsf		PIE3, TX2IE			; enable Uart2 transmit IRQ	
	;------------------
	clrf	BSR		
	;------------------
	clrf	mode_ctl
	goto	button_ctl_done
	
	
	
button_ctl_8bit_sel	
	movf	buttons, W
	xorlw	0x12				; only sel button pressed
	btfss	STATUS, Z
	goto	button_ctl_8bit_A
	incf	mode_ctl, F
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_8bit
	decf	mode_ctl, W
	andlw	0xFC
	addlw	0x01
	movwf	mode_ctl
	goto	button_update_leds_8bit	
button_ctl_8bit_A	
	movf	buttons, W
	xorlw	0x18				; only A button pressed
	btfss	STATUS, Z
	goto	button_ctl_8bit_B
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_8bit_A_2
	movf	INDF1, W
	andlw	0x07
	xorlw	0x07
	btfss	STATUS, Z
	goto	button_ctl_8bit_A_1_inc
	movlw	0xF8
	andwf	INDF1, F
	goto	button_update_leds_8bit
button_ctl_8bit_A_1_inc
	incf	INDF1, F
	goto	button_update_leds_8bit	
button_ctl_8bit_A_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_8bit_A_3
	movf	INDF1, W
	andlw	0x38
	xorlw	0x38
	btfss	STATUS, Z
	goto	button_ctl_8bit_A_2_inc
	movlw	0xC7
	andwf	INDF1, F
	goto	button_update_leds_8bit
button_ctl_8bit_A_2_inc
	movlw	0x08
	addwf	INDF1, F
	goto	button_update_leds_8bit	
button_ctl_8bit_A_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_8bit
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_8bit_A_3_inc
	movlw	0x3F
	andwf	INDF1, F
	goto	button_update_leds_8bit
button_ctl_8bit_A_3_inc
	movlw	0x40
	addwf	INDF1, F
	goto	button_update_leds_8bit		
button_ctl_8bit_B
	movf	buttons, W
	xorlw	0x11				; only B button pressed
	btfss	STATUS, Z
	goto	button_update_leds_8bit
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_8bit_B_2
	movf	INDF1, W
	andlw	0x07
	btfss	STATUS, Z
	goto	button_ctl_8bit_B_1_dec
	movlw	0x07
	iorwf	INDF1, F
	goto	button_update_leds_8bit
button_ctl_8bit_B_1_dec
	decf	INDF1, F
	goto	button_update_leds_8bit	
button_ctl_8bit_B_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_8bit_B_3
	movf	INDF1, W
	andlw	0x38
	btfss	STATUS, Z
	goto	button_ctl_8bit_B_2_dec
	movlw	0x38
	iorwf	INDF1, F
	goto	button_update_leds_8bit
button_ctl_8bit_B_2_dec
	movlw	0x08
	subwf	INDF1, F
	goto	button_update_leds_8bit	
button_ctl_8bit_B_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_8bit
	movf	INDF1, W
	andlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_8bit_B_3_dec
	movlw	0xC0
	iorwf	INDF1, F
	goto	button_update_leds_8bit
button_ctl_8bit_B_3_dec
	movlw	0x40
	subwf	INDF1, F
	goto	button_update_leds_8bit	
	
button_update_leds_8bit
	; for states 1,2,3 display the mode reg
	clrf	LED4
	btfss	INDF1, 0
	goto	button_update_leds_8bit_1
	bsf		LED4, 0
	bsf		LED4, 1
button_update_leds_8bit_1	
	btfss	INDF1, 1
	goto	button_update_leds_8bit_2
	bsf		LED4, 2
	bsf		LED4, 3
button_update_leds_8bit_2	
	btfss	INDF1, 2
	goto	button_update_leds_8bit_3
	bsf		LED4, 4
	bsf		LED4, 5
button_update_leds_8bit_3	
	clrf	LED3
	btfss	INDF1, 3
	goto	button_update_leds_8bit_4
	bsf		LED3, 0
	bsf		LED3, 1
button_update_leds_8bit_4	
	btfss	INDF1, 4
	goto	button_update_leds_8bit_5
	bsf		LED3, 2
	bsf		LED3, 3
button_update_leds_8bit_5	
	btfss	INDF1, 5
	goto	button_update_leds_8bit_6
	bsf		LED3, 4
	bsf		LED3, 5
button_update_leds_8bit_6	
	clrf	LED2
	btfss	INDF1, 6
	goto	button_update_leds_8bit_7
	bsf		LED2, 0
	bsf		LED2, 1
button_update_leds_8bit_7	
	btfss	INDF1, 7
	goto	button_update_leds_8bit_8
	bsf		LED2, 2
	bsf		LED2, 3
button_update_leds_8bit_8
	clrf	LED1
	; set the led selected to blink
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfsc	STATUS, Z
	bsf		LED4, 7		
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfsc	STATUS, Z
	bsf		LED3, 7		
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfsc	STATUS, Z
	bsf		LED2, 7		
	goto	button_ctl_done


	; check if in register select and apply value as needed for A and B, advance for Select, or go to reg set if set
button_ctl_12bit
	movf	buttons, W
	xorlw	0x14				; only set button pressed
	btfss	STATUS, Z
	goto	button_ctl_12bit_sel
	clrf	mode_ctl
	goto	button_ctl_done
button_ctl_12bit_sel	
	movf	buttons, W
	xorlw	0x12				; only sel button pressed
	btfss	STATUS, Z
	goto	button_ctl_12bit_A
	incf	mode_ctl, F
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_12bit
	decf	mode_ctl, W
	andlw	0xFC
	movwf	mode_ctl
	goto	button_update_leds_12bit	
button_ctl_12bit_A	
	movf	buttons, W
	xorlw	0x18				; only A button pressed
	btfss	STATUS, Z
	goto	button_ctl_12bit_B
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_ctl_12bit_A_2
	movf	INDF1, W
	andlw	0x07
	xorlw	0x07
	btfss	STATUS, Z
	goto	button_ctl_12bit_A_1_inc
	movlw	0xF8
	andwf	INDF1, F
	goto	button_update_leds_12bit
button_ctl_12bit_A_1_inc
	incf	INDF1, F
	goto	button_update_leds_12bit	
button_ctl_12bit_A_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_12bit_A_3
	movf	INDF1, W
	andlw	0x38
	xorlw	0x38
	btfss	STATUS, Z
	goto	button_ctl_12bit_A_2_inc
	movlw	0xC7
	andwf	INDF1, F
	goto	button_update_leds_12bit
button_ctl_12bit_A_2_inc
	movlw	0x08
	addwf	INDF1, F
	goto	button_update_leds_12bit
	
button_ctl_12bit_A_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_12bit_A_4
	movf	INDF1, W
	movwf	temp3
	bcf		STATUS, C
	rrf		temp3, F
	incf	FSR1L, F			; pick the high register
	btfsc	INDF1, 0
	bsf		temp3, 7
	movf	temp3, W
	andlw	0xE0
	xorlw	0xE0
	btfss	STATUS, Z
	goto	button_ctl_12bit_A_3_inc
	bcf		INDF1, 0
	decf	FSR1L, F			; pick low register
	bcf		INDF1, 6
	bcf		INDF1, 7
	goto	button_update_leds_12bit
button_ctl_12bit_A_3_inc
	movlw	0x20
	addwf	temp3, F
	bcf		INDF1, 0
	btfsc	temp3, 7
	bsf		INDF1, 0
	decf	FSR1L, F			; pick low register
	movlw	0x3F
	andwf	INDF1, F
	rlf		temp3, W
	andlw	0xC0
	iorwf	INDF1, F
	goto	button_update_leds_12bit		
	
button_ctl_12bit_A_4	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_12bit
	incf	FSR1L, F			; pick the high register
	movf	INDF1, W
	andlw	0x0E
	xorlw	0x0E
	btfss	STATUS, Z
	goto	button_ctl_12bit_A_4_inc
	movlw	0xF1
	andwf	INDF1, F
	decf	FSR1L, F			; pick low register
	goto	button_update_leds_12bit
button_ctl_12bit_A_4_inc
	movlw	0x02
	addwf	INDF1, F
	decf	FSR1L, F			; pick low register
	goto	button_update_leds_12bit				
button_ctl_12bit_B
	movf	buttons, W
	xorlw	0x11				; only B button pressed
	btfss	STATUS, Z
	goto	button_update_leds_12bit
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_ctl_12bit_B_2
	movf	INDF1, W
	andlw	0x07
	btfss	STATUS, Z
	goto	button_ctl_12bit_B_1_dec
	movlw	0x07
	iorwf	INDF1, F
	goto	button_update_leds_12bit
button_ctl_12bit_B_1_dec
	decf	INDF1, F
	goto	button_update_leds_12bit	
button_ctl_12bit_B_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_12bit_B_3
	movf	INDF1, W
	andlw	0x38
	btfss	STATUS, Z
	goto	button_ctl_12bit_B_2_dec
	movlw	0x38
	iorwf	INDF1, F
	goto	button_update_leds_12bit
button_ctl_12bit_B_2_dec
	movlw	0x08
	subwf	INDF1, F
	goto	button_update_leds_12bit		
button_ctl_12bit_B_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_12bit_B_4
	movf	INDF1, W
	movwf	temp3
	bcf		STATUS, C
	rrf		temp3, F
	incf	FSR1L, F			; pick the high register
	btfsc	INDF1, 0
	bsf		temp3, 7
	movf	temp3, W
	andlw	0xE0
	btfss	STATUS, Z
	goto	button_ctl_12bit_B_3_dec
	bsf		INDF1, 0
	decf	FSR1L, F			; pick low register
	bsf		INDF1, 6
	bsf		INDF1, 7
	goto	button_update_leds_12bit
button_ctl_12bit_B_3_dec
	movlw	0x20
	subwf	temp3, F
	bcf		INDF1, 0
	btfsc	temp3, 7
	bsf		INDF1, 0
	decf	FSR1L, F			; pick low register
	movlw	0x3F
	andwf	INDF1, F
	rlf		temp3, W
	andlw	0xC0
	iorwf	INDF1, F
	goto	button_update_leds_12bit		
button_ctl_12bit_B_4	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_12bit
	incf	FSR1L, F			; pick the high register	
	movf	INDF1, W
	andlw	0x0E
	btfss	STATUS, Z
	goto	button_ctl_12bit_B_4_dec
	movlw	0x0E
	iorwf	INDF1, F
	decf	FSR1L, F			; pick low register	
	goto	button_update_leds_12bit
button_ctl_12bit_B_4_dec
	movlw	0x02
	subwf	INDF1, F
	decf	FSR1L, F			; pick low register	
	goto	button_update_leds_12bit	
	
button_update_leds_12bit
	; for states 1,2,3,4 display the mode reg
	clrf	LED4
	btfss	INDF1, 0
	goto	button_update_leds_12bit_1
	bsf		LED4, 0
	bsf		LED4, 1
button_update_leds_12bit_1	
	btfss	INDF1, 1
	goto	button_update_leds_12bit_2
	bsf		LED4, 2
	bsf		LED4, 3
button_update_leds_12bit_2	
	btfss	INDF1, 2
	goto	button_update_leds_12bit_3
	bsf		LED4, 4
	bsf		LED4, 5
button_update_leds_12bit_3	
	clrf	LED3
	btfss	INDF1, 3
	goto	button_update_leds_12bit_4
	bsf		LED3, 0
	bsf		LED3, 1
button_update_leds_12bit_4	
	btfss	INDF1, 4
	goto	button_update_leds_12bit_5
	bsf		LED3, 2
	bsf		LED3, 3
button_update_leds_12bit_5	
	btfss	INDF1, 5
	goto	button_update_leds_12bit_6
	bsf		LED3, 4
	bsf		LED3, 5
button_update_leds_12bit_6	
	clrf	LED2
	btfss	INDF1, 6
	goto	button_update_leds_12bit_7
	bsf		LED2, 0
	bsf		LED2, 1
button_update_leds_12bit_7	
	btfss	INDF1, 7
	goto	button_update_leds_12bit_8
	bsf		LED2, 2
	bsf		LED2, 3
button_update_leds_12bit_8
	incf	FSR1L, F
	btfss	INDF1, 0
	goto	button_update_leds_12bit_9
	bsf		LED2, 4
	bsf		LED2, 5
button_update_leds_12bit_9	
	clrf	LED1
	btfss	INDF1, 1
	goto	button_update_leds_12bit_10
	bsf		LED1, 0
	bsf		LED1, 1
button_update_leds_12bit_10
	btfss	INDF1, 2
	goto	button_update_leds_12bit_11
	bsf		LED1, 2
	bsf		LED1, 3
button_update_leds_12bit_11
	btfss	INDF1, 3
	goto	button_update_leds_12bit_12
	bsf		LED1, 4
	bsf		LED1, 5
button_update_leds_12bit_12

button_4_led_blink_select	
	; set the led selected to blink
	movf	mode_ctl, W
	andlw	0x03
	btfsc	STATUS, Z
	bsf		LED4, 7		
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfsc	STATUS, Z
	bsf		LED3, 7		
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfsc	STATUS, Z
	bsf		LED2, 7		
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfsc	STATUS, Z
	bsf		LED1, 7		
	goto	button_ctl_done	
	
	; check if in register select and apply value as needed for A and B, advance for Select, or go to reg set if set
button_ctl_24bit
	movf	buttons, W
	xorlw	0x14				; only set button pressed
	btfss	STATUS, Z
	goto	button_ctl_24bit_sel
	clrf	mode_ctl
	goto	button_ctl_done
button_ctl_24bit_sel	
	movf	buttons, W
	xorlw	0x12				; only sel button pressed
	btfss	STATUS, Z
	goto	button_ctl_24bit_A
	incf	mode_ctl, F
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_24bit
	decf	mode_ctl, W
	andlw	0xFC
	movwf	mode_ctl
	goto	button_update_leds_24bit	
button_ctl_24bit_A	
	movf	buttons, W
	xorlw	0x18				; only A button pressed
	btfss	STATUS, Z
	goto	button_ctl_24bit_B
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_ctl_24bit_A_2
	movf	INDF1, W
	andlw	0x3F
	xorlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_A_1_inc
	movlw	0xC0
	andwf	INDF1, F
	goto	button_update_leds_24bit
button_ctl_24bit_A_1_inc
	incf	INDF1, F
	goto	button_update_leds_24bit	
button_ctl_24bit_A_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_24bit_A_3
	incf	FSR1L, F			; select next led reg
	movf	INDF1, W
	andlw	0x3F
	xorlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_A_2_inc
	movlw	0xC0
	andwf	INDF1, F
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit
button_ctl_24bit_A_2_inc
	incf	INDF1, F
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit
button_ctl_24bit_A_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_24bit_A_4
	incf	FSR1L, F			; select next led reg
	incf	FSR1L, F			; select next led reg
	movf	INDF1, W
	andlw	0x3F
	xorlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_A_3_inc
	movlw	0xC0
	andwf	INDF1, F
	decf	FSR1L,F				; select previous reg
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit
button_ctl_24bit_A_3_inc
	incf	INDF1, F
	decf	FSR1L,F				; select previous reg
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit
button_ctl_24bit_A_4	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_24bit
	movlw	0x03
	addwf	FSR1L, F			; select next led reg
	movf	INDF1, W
	andlw	0x3F
	xorlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_A_4_inc
	movlw	0xC0
	andwf	INDF1, F
	movlw	0x03
	subwf	FSR1L,F				; select previous reg (F-W)
	goto	button_update_leds_24bit
button_ctl_24bit_A_4_inc
	incf	INDF1, F
	movlw	0x03
	subwf	FSR1L,F				; select previous reg (F-W)
	goto	button_update_leds_24bit

	
	
button_ctl_24bit_B
	movf	buttons, W
	xorlw	0x11				; only B button pressed
	btfss	STATUS, Z
	goto	button_update_leds_24bit
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_ctl_24bit_B_2
	movf	INDF1, W
	andlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_B_1_dec
	movlw	0x3F
	iorwf	INDF1, F
	goto	button_update_leds_24bit
button_ctl_24bit_B_1_dec
	decf	INDF1, F
	goto	button_update_leds_24bit	
button_ctl_24bit_B_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_24bit_B_3
	incf	FSR1L, F			; select next led reg
	movf	INDF1, W
	andlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_B_2_dec
	movlw	0x3F
	iorwf	INDF1, F
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit
button_ctl_24bit_B_2_dec
	decf	INDF1, F
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit	
button_ctl_24bit_B_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_24bit_B_4
	incf	FSR1L, F			; select next led reg
	incf	FSR1L, F			; select next led reg
	movf	INDF1, W
	andlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_B_3_dec
	movlw	0x3F
	iorwf	INDF1, F
	decf	FSR1L,F				; select previous reg
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit
button_ctl_24bit_B_3_dec
	decf	INDF1, F
	decf	FSR1L,F				; select previous reg
	decf	FSR1L,F				; select previous reg
	goto	button_update_leds_24bit	
button_ctl_24bit_B_4	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_24bit
	movlw	0x03
	addwf	FSR1L, F			; select next led reg
	movf	INDF1, W
	andlw	0x3F
	btfss	STATUS, Z
	goto	button_ctl_24bit_B_4_dec
	movlw	0x3F
	iorwf	INDF1, F
	movlw	0x03
	subwf	FSR1L,F				; select previous reg (F-W)
	goto	button_update_leds_24bit
button_ctl_24bit_B_4_dec
	decf	INDF1, F
	movlw	0x03
	subwf	FSR1L,F				; select previous reg (F-W)
	goto	button_update_leds_24bit		
	
button_update_leds_24bit
	; for led color selection display the current custom led reg value minus the blink bits (set below)
	movf	INDF1, W
	andlw	0x3F
	movwf	LED4
	incf	FSR1L, F
	movf	INDF1, W
	andlw	0x3F
	movwf	LED3
	incf	FSR1L, F
	movf	INDF1, W
	andlw	0x3F
	movwf	LED2
	incf	FSR1L, F
	movf	INDF1, W
	andlw	0x3F
	movwf	LED1
	goto	button_4_led_blink_select

	
	; check if in register select and apply value as needed for A and B, advance for Select, or go to reg set if set
button_ctl_2x4bit
	movf	buttons, W
	xorlw	0x14				; only set button pressed
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_sel
	clrf	mode_ctl
	goto	button_ctl_done
button_ctl_2x4bit_sel	
	movf	buttons, W
	xorlw	0x12				; only sel button pressed
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A
	incf	mode_ctl, F
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_2x4bit
	decf	mode_ctl, W
	andlw	0xFC
	movwf	mode_ctl
	goto	button_update_leds_2x4bit	
button_ctl_2x4bit_A		
	movf	buttons, W
	xorlw	0x18				; only A button pressed
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A_2
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A_1_inc
	movlw	0x3F
	andwf	INDF1, F
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_A_1_inc
	movlw	0x40
	addwf	INDF1, F
	goto	button_update_leds_2x4bit	
button_ctl_2x4bit_A_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A_3
	incf	FSR1L, F			; pick next var
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A_2_inc
	movlw	0x3F
	andwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_A_2_inc
	movlw	0x40
	addwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_A_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A_4
	incf	FSR1L, F			; pick next var
	incf	FSR1L, F			; pick next var
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A_3_inc
	movlw	0x3F
	andwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_A_3_inc
	movlw	0x40
	addwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit			
button_ctl_2x4bit_A_4	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_2x4bit
	movlw	0x03
	addwf	FSR1L, F			; pick the high register
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_A_4_inc
	movlw	0x3F
	andwf	INDF1, F
	movlw	0x03
	subwf	FSR1L, F			; pick low register	 = F - W
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_A_4_inc
	movlw	0x40
	addwf	INDF1, F
	movlw	0x03
	subwf	FSR1L, F			; pick low register	 = F - W
	goto	button_update_leds_2x4bit		
button_ctl_2x4bit_B
	movf	buttons, W
	xorlw	0x11				; only B button pressed
	btfss	STATUS, Z
	goto	button_update_leds_2x4bit
	movf	mode_ctl, W
	andlw	0x03
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B_2
	movf	INDF1, W
	andlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B_1_dec
	movlw	0xC0
	iorwf	INDF1, F
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_B_1_dec
	movlw	0x40
	subwf	INDF1, F
	goto	button_update_leds_2x4bit	
button_ctl_2x4bit_B_2	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x01
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B_3
	incf	FSR1L, F			; pick next var
	movf	INDF1, W
	andlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B_2_dec
	movlw	0xC0
	iorwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_B_2_dec
	movlw	0x40
	subwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit		
button_ctl_2x4bit_B_3	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x02
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B_4
	incf	FSR1L, F			; pick next var
	incf	FSR1L, F			; pick next var
	movf	INDF1, W
	andlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B_3_dec
	movlw	0xC0
	iorwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_B_3_dec
	movlw	0x40
	subwf	INDF1, F
	decf	FSR1L, F			; move back to first var
	decf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit		
button_ctl_2x4bit_B_4	
	movf	mode_ctl, W
	andlw	0x03
	xorlw	0x03
	btfss	STATUS, Z
	goto	button_update_leds_2x4bit
	movlw	0x03
	addwf	FSR1L, F			; pick next var	
	movf	INDF1, W
	andlw	0xC0
	btfss	STATUS, Z
	goto	button_ctl_2x4bit_B_4_dec
	movlw	0xC0
	iorwf	INDF1, F
	movlw	0x03
	subwf	FSR1L, F			; move back to first var	= F - W
	goto	button_update_leds_2x4bit
button_ctl_2x4bit_B_4_dec
	movlw	0x40
	subwf	INDF1, F
	movlw	0x03
	subwf	FSR1L, F			; move back to first var
	goto	button_update_leds_2x4bit	
	
button_update_leds_2x4bit	
	; for states 1,2,3,4 display the mode reg
	clrf	LED4
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x40
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_1
	bsf		LED4, 0
	bsf		LED4, 1
button_update_leds_2x4bit_1	
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x80
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_2
	bsf		LED4, 2
	bsf		LED4, 3
button_update_leds_2x4bit_2	
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_3
	bsf		LED4, 4
	bsf		LED4, 5
button_update_leds_2x4bit_3	
	clrf	LED3
	incf	FSR1L, F
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x40
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_4
	bsf		LED3, 0
	bsf		LED3, 1
button_update_leds_2x4bit_4	
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x80
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_5
	bsf		LED3, 2
	bsf		LED3, 3
button_update_leds_2x4bit_5	
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_6
	bsf		LED3, 4
	bsf		LED3, 5
button_update_leds_2x4bit_6	
	clrf	LED2
	incf	FSR1L, F
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x40
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_7
	bsf		LED2, 0
	bsf		LED2, 1
button_update_leds_2x4bit_7	
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x80
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_8
	bsf		LED2, 2
	bsf		LED2, 3
button_update_leds_2x4bit_8
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_9
	bsf		LED2, 4
	bsf		LED2, 5
button_update_leds_2x4bit_9	
	clrf	LED1
	incf	FSR1L, F
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x40
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_10
	bsf		LED1, 0
	bsf		LED1, 1
button_update_leds_2x4bit_10
	movf	INDF1, W
	andlw	0xC0
	xorlw	0x80
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_11
	bsf		LED1, 2
	bsf		LED1, 3
button_update_leds_2x4bit_11
	movf	INDF1, W
	andlw	0xC0
	xorlw	0xC0
	btfss	STATUS,Z
	goto	button_update_leds_2x4bit_12
	bsf		LED1, 4
	bsf		LED1, 5
button_update_leds_2x4bit_12
	goto	button_4_led_blink_select
	

button_ctl_save_vars
	call	_SAVE_VARS
	clrf	mode_ctl
	goto	button_ctl_done	

	
button_ctl_direct_remote
	clrf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	bsf		ir_status, 2		; disable local beacon TX functions
	bsf		ir_status, 3		; disable local beacon RX functions
	bsf		mode_ctl, 7			; enable cont button presses 
	movf	buttons, W
	xorlw	0x14				; only set button pressed
	btfss	STATUS, Z
	goto	button_ctl_direct_remote_A
	clrf	mode_ctl
	bcf		ir_status, 2		; enable local beacon TX functions	
	bcf		ir_status, 3		; enable local beacon RX functions	
	goto	button_ctl_done
button_ctl_direct_remote_A
	movf	buttons, W
	andlw	0xFE				; ignore the B button
	xorlw	0x18				; only A or A + B button pressed
	btfss	STATUS, Z
	goto	button_ctl_direct_remote_B	
	goto	button_ctl_direct_remote_send
button_ctl_direct_remote_B	
	movf	buttons, W
	xorlw	0x11				; only B button pressed
	btfss	STATUS, Z
	goto	button_ctl_done
button_ctl_direct_remote_send	
	btfsc	ir_status, 0		; busy bit
	goto	button_ctl_done		; IR was busy so back off and try again next time
	bsf		ir_status, 0		; set the busy bit so other modules do not overwrite the data.
	movlw	0x01		
	movwf	ir_cmd				; direct remote cmd
	clrf	ir_data				; command data (not used for beacon)
	btfsc	buttons, 0			; button B
	bsf		ir_data, 0			; MT1
	btfsc	buttons, 3			; button A
	bsf		ir_data, 1			; MT2
	bsf		ir_status, 1		; set the calc bit		
	;------------------
	movlw	d'14'
	movwf	BSR		
	;------------------	
	bsf		PIE3, TX2IE			; enable Uart2 transmit IRQ	
	;------------------
	clrf	BSR		
	;------------------
	goto	button_ctl_done

	
button_ctl_done	
	; if the button was pressed reset the no_press_cnt timer
	movf	buttons, W
	andlw	0x0F
	btfsc	STATUS, Z
	goto	button_ctl_no_press
	movlw	BUTTON_DEBOUNCE
	movwf	no_press_cnt
button_ctl_no_press	
	clrf	buttons

	movlw	0x10
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page	
	goto	MAINLOOP_LEDS

	

	
; http://ww1.microchip.com/downloads/en/DeviceDoc/PIC16(L)F15354_55%20Data%20Sheet%2040001853C.pdf	
; RB3(24)	SCL
; RB4(25)	SDA
; RB6(27)	[ISPCLK] BBtx
; RB7(28)	[ICSPDAT] BBrx
	

;#########################################################	
; save vars to flash
;#########################################################	
_SAVE_VARS
	;------------------
	movlw	d'16'
	movwf	BSR		
	;------------------	
	; erase	row of flash (32 words) 
	movlw	0x1F
	movwf	NVMADRH
	movlw	0x80
	movwf	NVMADRL
	movlw	0x14				; access program flash, flash erase, write enable 
	movwf	NVMCON1
	call	_UNLOCK_NVM			; unlock NVM
	bcf		NVMCON1, WREN		; disable write latch

	; write row of flash (32 words)
	clrf	FSR0H				; address of first ram reg
	movlw	START_OF_REGS
	movwf	FSR0L	
	movlw	0x1F
	movwf	NVMADRH
	movlw	0x80
	movwf	NVMADRL
	movlw	0x24				; access program flash, flash write latch only, write enable 
	movwf	NVMCON1

_SAVE_VARS_load_loop	
	moviw	FSR0++				; movw INDF0 to W and increment to next address
	movwf	NVMDATL
	movlw	0x3F				; upper bits unused leave in cleared state
	movwf	NVMDATH
	call	_UNLOCK_NVM			; unlock NVM
	incf	NVMADRL, F
	movf	FSR0L, W
	xorlw	0x70				; 1 past the end of the ram space
	btfss	STATUS, Z
	goto	_SAVE_VARS_load_loop
_SAVE_VARS_pad_loop	
	movlw	0xff
	movwf	NVMDATL
	movlw	0x3f
	movwf	NVMDATH
	incf	NVMADRL, F
	movf	NVMADRL, W
	andlw	0x1F				; check if on a 32 word boundary (end of row)
	xorlw	0x1F
	btfsc	STATUS, Z
	goto	_SAVE_VARS_load_done	
	call	_UNLOCK_NVM			; unlock NVM
	goto	_SAVE_VARS_pad_loop	
_SAVE_VARS_load_done	
	bcf		NVMCON1, LWLO		; next write programs row vs latches
	call	_UNLOCK_NVM			; unlock NVM
	bcf		NVMCON1, WREN		; clear write enable bit
	
	;------------------
	clrf	BSR		
	;------------------	
	
	return
	
;#########################################################	
; unlock the NVM for write / erase
;#########################################################	
_UNLOCK_NVM
	; unlock seq
	bcf		INTCON, GIE			; disable IRQs for unlock
	movlw	0x55
	movwf	NVMCON2
	movlw	0xAA
	movwf	NVMCON2
	bsf		NVMCON1, WR			; kick off write or erase
	bsf		INTCON, GIE			; enable IRQs again
	
	return
	
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; start of page 1
	org		1000h
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	; ************************************************************
MAINLOOP_LEDS	
	; verfiy not in control mode
	movf	mode_ctl, W
	btfsc	STATUS, Z
	goto	LEDS_start
	
	movlw	0x18
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page	
	goto	MAINLOOP_VIBE		; jump down to the vibe checks
	
LEDS_start	
	; check if the led timers have expired yet
	movf	led_timer_high
	btfss	STATUS, Z
	goto	skip_leds
	movf	led_timer_low
	btfss	STATUS, Z
	goto	skip_leds
	
	
	movf	led_mode_reg, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	led_mode_2
	; rainbow right
	movf	sequence, W
	call	_RGB_rotate
	movwf	LED4
	movf	sequence, W
	addlw	0x01
	call	_RGB_rotate
	movwf	LED3
	movf	sequence, W
	addlw	0x02
	call	_RGB_rotate
	movwf	LED2
	movf	sequence, W
	addlw	0x03
	call	_RGB_rotate
	movwf	LED1
	incf	sequence, F
	movf	sequence, W
	sublw	0x11		    ; W <= k C = 1
	btfss	STATUS, C
	clrf	sequence	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	goto	skip_leds
	
led_mode_2	
	movf	led_mode_reg, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	led_mode_3		
	; static custom LED display
	movf	cust_led1, W
	movwf	LED1
	movf	cust_led2, W
	movwf	LED2
	movf	cust_led3, W
	movwf	LED3
	movf	cust_led4, W
	movwf	LED4
	; even though this is static still refresh it every so often incase overwritten by menu leds. (also needed for the cycle option..) 
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	goto	skip_leds
	    
led_mode_3	
	movf	led_mode_reg, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_4
	; LFSR display (random)
	call	_CYCLE_LFSR
	movwf	LED1
	call	_CYCLE_LFSR
	movwf	LED2
	call	_CYCLE_LFSR
	movwf	LED3
	call	_CYCLE_LFSR
	movwf	LED4
	; set up next led timer
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	goto	skip_leds
	
led_mode_4
	movf	led_mode_reg, W
	xorlw	0x04
	btfss	STATUS, Z
	goto	led_mode_5
	; Larson custom single color (use custom led 4 and led 3 (trail) 
	movf	sequence, W
	btfss	STATUS, Z
	goto	led_mode_4_1
	movf	cust_led4, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_4_done			
led_mode_4_1	
	movf	sequence, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	led_mode_4_2
	movf	cust_led3, W
	movwf	LED1
	movf	cust_led4, W
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_4_done			
led_mode_4_2
	movf	sequence, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	led_mode_4_3
	clrf	LED1
	movf	cust_led3, W
	movwf	LED2
	movf	cust_led4, W
	movwf	LED3
	clrf	LED4
	goto	led_mode_4_done			
led_mode_4_3
	movf	sequence, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_4_4
	clrf	LED1
	clrf	LED2
	movf	cust_led3, W
	movwf	LED3
	movf	cust_led4, W
	movwf	LED4
	goto	led_mode_4_done			
led_mode_4_4
	movf	sequence, W
	xorlw	0x04
	btfss	STATUS, Z
	goto	led_mode_4_5
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	cust_led4, W
	movwf	LED4
	goto	led_mode_4_done			
led_mode_4_5
	movf	sequence, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	led_mode_4_6
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	cust_led4, W
	movwf	LED4
	goto	led_mode_4_done			
led_mode_4_6
	movf	sequence, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	led_mode_4_7
	clrf	LED1
	clrf	LED2
	movf	cust_led4, W
	movwf	LED3
	movf	cust_led3, W
	movwf	LED4
	goto	led_mode_4_done			
led_mode_4_7
	movf	sequence, W
	xorlw	0x07
	btfss	STATUS, Z
	goto	led_mode_4_8
	clrf	LED1
	movf	cust_led4, W
	movwf	LED2
	movf	cust_led3, W
	movwf	LED3
	clrf	LED4
	goto	led_mode_4_done			
led_mode_4_8
	movf	sequence, W
	xorlw	0x08
	btfss	STATUS, Z
	goto	led_mode_4_9
	movf	cust_led4, W
	movwf	LED1
	movf	cust_led3, W
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_4_done			
led_mode_4_9
	movf	sequence, W
	xorlw	0x09
	btfss	STATUS, Z
	goto	led_mode_4_A
	movf	cust_led4, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	movlw	0xFF
	movwf	sequence			; end of loop
	goto	led_mode_4_done			
led_mode_4_A
	clrf	sequence			; past the end of the loop clear seq
led_mode_4_done		
	incf	sequence, F
	; set up next led timer
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low
	goto	skip_leds
	
	
led_mode_5
	movf	led_mode_reg, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	led_mode_6
	
;	movlw	0x0C
;	movwf	led_display_seq
	
	; Larson custom RGB swap on every swipe 
	movf	sequence, W
	btfss	STATUS, Z
	goto	led_mode_5_1
	movf	led_display_seq, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_5_done			
led_mode_5_1	
	movf	sequence, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	led_mode_5_2
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED1
	movf	led_display_seq, W
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_5_done			
led_mode_5_2
	movf	sequence, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	led_mode_5_3
	clrf	LED1
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED2
	movf	led_display_seq, W
	movwf	LED3
	clrf	LED4
	goto	led_mode_5_done			
led_mode_5_3
	movf	sequence, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_5_4
	clrf	LED1
	clrf	LED2
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED3
	movf	led_display_seq, W
	movwf	LED4
	goto	led_mode_5_done			
led_mode_5_4
	movf	sequence, W
	xorlw	0x04
	btfss	STATUS, Z
	goto	led_mode_5_5
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	led_display_seq, W
	movwf	LED4
	
	; update led_seq
	movf	led_display_seq, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_5_update1_0C
	movlw	0x0C
	movwf	led_display_seq
	goto	led_mode_5_update1_done
led_mode_5_update1_0C
	movf	led_display_seq, W
	xorlw	0x0C
	btfss	STATUS, Z
	goto	led_mode_5_update1_30
	movlw	0x30
	movwf	led_display_seq
	goto	led_mode_5_update1_done
led_mode_5_update1_30
	movlw	0x03
	movwf	led_display_seq
led_mode_5_update1_done	
	
	goto	led_mode_5_done			
led_mode_5_5
	
	movf	sequence, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	led_mode_5_6	
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	led_display_seq, W
	movwf	LED4
	goto	led_mode_5_done			
led_mode_5_6
	movf	sequence, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	led_mode_5_7
	clrf	LED1
	clrf	LED2
	movf	led_display_seq, W
	movwf	LED3
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED4
	goto	led_mode_5_done			
led_mode_5_7
	movf	sequence, W
	xorlw	0x07
	btfss	STATUS, Z
	goto	led_mode_5_8
	clrf	LED1
	movf	led_display_seq, W
	movwf	LED2
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED3
	clrf	LED4
	goto	led_mode_5_done			
led_mode_5_8
	movf	sequence, W
	xorlw	0x08
	btfss	STATUS, Z
	goto	led_mode_5_9
	movf	led_display_seq, W
	movwf	LED1
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_5_done			
led_mode_5_9
	movf	sequence, W
	xorlw	0x09
	btfss	STATUS, Z
	goto	led_mode_5_A
	movf	led_display_seq, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	movlw	0xFF
	movwf	sequence			; end of loop

	; update led_seq
	movf	led_display_seq, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_5_update2_0C
	movlw	0x0C
	movwf	led_display_seq
	goto	led_mode_5_update2_done
led_mode_5_update2_0C
	movf	led_display_seq, W
	xorlw	0x0C
	btfss	STATUS, Z
	goto	led_mode_5_update2_30
	movlw	0x30
	movwf	led_display_seq
	goto	led_mode_5_update2_done
led_mode_5_update2_30
	movlw	0x03
	movwf	led_display_seq
led_mode_5_update2_done
	
	goto	led_mode_5_done			
led_mode_5_A
	clrf	sequence			; past the end of the loop clear seq	
led_mode_5_done		
	incf	sequence, F
	; set up next led timer
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low
	goto	skip_leds
	
	
led_mode_6	
	movf	led_mode_reg, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	led_mode_7
	
;	movlw	0x0C
;	movwf	led_display_seq
	
	; Larson custom RGB swap on every other swipe 
	movf	sequence, W
	btfss	STATUS, Z
	goto	led_mode_6_1
	movf	led_display_seq, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_6_done			
led_mode_6_1	
	movf	sequence, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	led_mode_6_2
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED1
	movf	led_display_seq, W
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_6_done			
led_mode_6_2
	movf	sequence, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	led_mode_6_3
	clrf	LED1
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED2
	movf	led_display_seq, W
	movwf	LED3
	clrf	LED4
	goto	led_mode_6_done			
led_mode_6_3
	movf	sequence, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_6_4
	clrf	LED1
	clrf	LED2
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED3
	movf	led_display_seq, W
	movwf	LED4
	goto	led_mode_6_done			
led_mode_6_4
	movf	sequence, W
	xorlw	0x04
	btfss	STATUS, Z
	goto	led_mode_6_5
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	led_display_seq, W
	movwf	LED4
	goto	led_mode_6_done			
led_mode_6_5
	
	movf	sequence, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	led_mode_6_6	
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	led_display_seq, W
	movwf	LED4
	goto	led_mode_6_done			
led_mode_6_6
	movf	sequence, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	led_mode_6_7
	clrf	LED1
	clrf	LED2
	movf	led_display_seq, W
	movwf	LED3
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED4
	goto	led_mode_6_done			
led_mode_6_7
	movf	sequence, W
	xorlw	0x07
	btfss	STATUS, Z
	goto	led_mode_6_8
	clrf	LED1
	movf	led_display_seq, W
	movwf	LED2
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED3
	clrf	LED4
	goto	led_mode_6_done			
led_mode_6_8
	movf	sequence, W
	xorlw	0x08
	btfss	STATUS, Z
	goto	led_mode_6_9
	movf	led_display_seq, W
	movwf	LED1
	movf	led_display_seq, W
	andlw	0x15
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_6_done			
led_mode_6_9
	movf	sequence, W
	xorlw	0x09
	btfss	STATUS, Z
	goto	led_mode_6_A
	movf	led_display_seq, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	movlw	0xFF
	movwf	sequence			; end of loop

	; update led_seq
	movf	led_display_seq, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_6_update2_0C
	movlw	0x0C
	movwf	led_display_seq
	goto	led_mode_6_update2_done
led_mode_6_update2_0C
	movf	led_display_seq, W
	xorlw	0x0C
	btfss	STATUS, Z
	goto	led_mode_6_update2_30
	movlw	0x30
	movwf	led_display_seq
	goto	led_mode_6_update2_done
led_mode_6_update2_30
	movlw	0x03
	movwf	led_display_seq
led_mode_6_update2_done
	
	goto	led_mode_6_done			
led_mode_6_A
	clrf	sequence			; past the end of the loop clear seq	
led_mode_6_done		
	incf	sequence, F
	; set up next led timer
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low
	goto	skip_leds
	
	
led_mode_7	
	movf	led_mode_reg, W
	xorlw	0x07
	btfss	STATUS, Z
	goto	led_mode_8

	
	; update led_seq
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	andlw	0x15
	movwf	temp2
	incf	led_display_seq, F
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp3	
	
	; Larson custom RGB swap on every led
	movf	sequence, W
	btfss	STATUS, Z
	goto	led_mode_7_1
	movf	temp3, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_7_done			
led_mode_7_1	
	movf	sequence, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	led_mode_7_2
	movf	temp2, W
	movwf	LED1
	movf	temp3, W
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_7_done			
led_mode_7_2
	movf	sequence, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	led_mode_7_3
	clrf	LED1
	movf	temp2, W
	movwf	LED2
	movf	temp3, W
	movwf	LED3
	clrf	LED4
	goto	led_mode_7_done			
led_mode_7_3
	movf	sequence, W
	xorlw	0x03
	btfss	STATUS, Z
	goto	led_mode_7_4
	clrf	LED1
	clrf	LED2
	movf	temp2, W
	movwf	LED3
	movf	temp3, W
	movwf	LED4
	goto	led_mode_7_done			
led_mode_7_4
	movf	sequence, W
	xorlw	0x04
	btfss	STATUS, Z
	goto	led_mode_7_5
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	temp3, W
	movwf	LED4
	goto	led_mode_7_done			
led_mode_7_5
	
	movf	sequence, W
	xorlw	0x05
	btfss	STATUS, Z
	goto	led_mode_7_6	
	clrf	LED1
	clrf	LED2
	clrf	LED3
	movf	temp3, W
	movwf	LED4
	goto	led_mode_7_done			
led_mode_7_6
	movf	sequence, W
	xorlw	0x06
	btfss	STATUS, Z
	goto	led_mode_7_7
	clrf	LED1
	clrf	LED2
	movf	temp3, W
	movwf	LED3
	movf	temp2, W
	movwf	LED4
	goto	led_mode_7_done			
led_mode_7_7
	movf	sequence, W
	xorlw	0x07
	btfss	STATUS, Z
	goto	led_mode_7_8
	clrf	LED1
	movf	temp3, W
	movwf	LED2
	movf	temp2, W
	movwf	LED3
	clrf	LED4
	goto	led_mode_7_done			
led_mode_7_8
	movf	sequence, W
	xorlw	0x08
	btfss	STATUS, Z
	goto	led_mode_7_9
	movf	temp3, W
	movwf	LED1
	movf	temp2, W
	movwf	LED2
	clrf	LED3
	clrf	LED4
	goto	led_mode_7_done			
led_mode_7_9
	movf	sequence, W
	xorlw	0x09
	btfss	STATUS, Z
	goto	led_mode_7_A
	movf	temp3, W
	movwf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4
	movlw	0xFF
	movwf	sequence			; end of loop	
	goto	led_mode_7_done			
led_mode_7_A
	clrf	sequence			; past the end of the loop clear seq	
led_mode_7_done		
	incf	sequence, F
	; set up next led timer
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low
	goto	skip_leds
	
led_mode_8
	movf	led_mode_reg, W
	xorlw	0x08
	btfss	STATUS, Z
	goto	led_mode_9
	; custom color ride me
	movf	sequence, W
	call	_RIDE_ME
	movwf	temp3
	btfss	temp3, 1
	goto	led_move_8_dot
	movf	cust_led3, W
	movwf	LED1
	movwf	LED2
	movwf	LED3
	movwf	LED4
	goto	led_move_8_done
led_move_8_dot
	btfss	temp3, 0
	goto	led_move_8_gap
	movf	cust_led4, W
	movwf	LED1
	movwf	LED2
	movwf	LED3
	movwf	LED4
	goto	led_move_8_done
led_move_8_gap
	clrf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4	
led_move_8_done	
	incf	sequence, F
	movf	sequence, W
	sublw	0x33		    ; W <= k C = 1
	btfss	STATUS, C
	clrf	sequence	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	goto	skip_leds	

led_mode_9
	movf	led_mode_reg, W
	xorlw	0x09
	btfss	STATUS, Z
	goto	led_mode_a
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	; rainbow ride me
	movf	sequence, W
	call	_RIDE_ME
	movwf	temp3
	btfss	temp3, 1
	goto	led_mode_9_dot
	movf	temp2, W
	movwf	LED1
	movwf	LED2
	movwf	LED3
	movwf	LED4
	goto	led_mode_9_done
led_mode_9_dot
	btfss	temp3, 0
	goto	led_mode_9_gap
	movf	temp2, W
	movwf	LED1
	movwf	LED2
	movwf	LED3
	movwf	LED4
	goto	led_mode_9_done
led_mode_9_gap
	clrf	LED1
	clrf	LED2
	clrf	LED3
	clrf	LED4	
led_mode_9_done	
	incf	sequence, F
	movf	sequence, W
	sublw	0x33		    ; W <= k C = 1
	btfss	STATUS, C
	clrf	sequence	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	goto	skip_leds	

led_mode_a	
	movf	led_mode_reg, W
	xorlw	0x0a
	btfss	STATUS, Z
	goto	led_mode_b
	; custom leds binary count
	incf	sequence, F
	clrf	LED1
	btfss	sequence, 0 
	goto	led_mode_a_1
	movf	cust_led1, W
	movwf	LED1
led_mode_a_1	
	clrf	LED2
	btfss	sequence, 1 
	goto	led_mode_a_2
	movf	cust_led2, W
	movwf	LED2
led_mode_a_2	
	clrf	LED3
	btfss	sequence, 2 
	goto	led_mode_a_3
	movf	cust_led3, W
	movwf	LED3
led_mode_a_3	
	clrf	LED4
	btfss	sequence, 3 
	goto	led_mode_a_4
	movf	cust_led4, W
	movwf	LED4
led_mode_a_4
	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	
	goto	skip_leds
	
led_mode_b
	movf	led_mode_reg, W
	xorlw	0x0b
	btfss	STATUS, Z
	goto	led_mode_c
	; custom leds same color rainbow
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	incf	sequence, F
	clrf	LED1
	btfss	sequence, 0 
	goto	led_mode_b_1
	movf	temp2, W
	movwf	LED1
led_mode_b_1	
	clrf	LED2
	btfss	sequence, 1 
	goto	led_mode_b_2
	movf	temp2, W
	movwf	LED2
led_mode_b_2	
	clrf	LED3
	btfss	sequence, 2 
	goto	led_mode_b_3
	movf	temp2, W
	movwf	LED3
led_mode_b_3	
	clrf	LED4
	btfss	sequence, 3 
	goto	led_mode_b_4
	movf	temp2, W
	movwf	LED4
led_mode_b_4
	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	
	goto	skip_leds
	
led_mode_c	
	movf	led_mode_reg, W
	xorlw	0x0c
	btfss	STATUS, Z
	goto	led_mode_d
	; custom leds different color rainbow
	incf	sequence, F
	clrf	LED1
	btfss	sequence, 0 
	goto	led_mode_c_1
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	movf	temp2, W
	movwf	LED1
led_mode_c_1	
	clrf	LED2
	btfss	sequence, 1 
	goto	led_mode_c_2
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F	
	movf	temp2, W
	movwf	LED2
led_mode_c_2	
	clrf	LED3
	btfss	sequence, 2 
	goto	led_mode_c_3
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	movf	temp2, W
	movwf	LED3
led_mode_c_3	
	clrf	LED4
	btfss	sequence, 3 
	goto	led_mode_c_4
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	movf	temp2, W
	movwf	LED4
led_mode_c_4
	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	
	goto	skip_leds
	
led_mode_d
	movf	led_mode_reg, W
	xorlw	0x0d
	btfss	STATUS, Z
	goto	led_mode_e
	; custom leds binary count
	incf	sequence, F
	clrf	LED1
	btfss	sequence, 3 
	goto	led_mode_d_1
	movf	cust_led1, W
	movwf	LED1
led_mode_d_1	
	clrf	LED2
	btfss	sequence, 2 
	goto	led_mode_d_2
	movf	cust_led2, W
	movwf	LED2
led_mode_d_2	
	clrf	LED3
	btfss	sequence, 1 
	goto	led_mode_d_3
	movf	cust_led3, W
	movwf	LED3
led_mode_d_3	
	clrf	LED4
	btfss	sequence, 0 
	goto	led_mode_d_4
	movf	cust_led4, W
	movwf	LED4
led_mode_d_4
	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	
	goto	skip_leds
	
led_mode_e
	movf	led_mode_reg, W
	xorlw	0x0e
	btfss	STATUS, Z
	goto	led_mode_f
	; custom leds same color rainbow
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	incf	sequence, F
	clrf	LED1
	btfss	sequence, 3 
	goto	led_mode_e_1
	movf	temp2, W
	movwf	LED1
led_mode_e_1	
	clrf	LED2
	btfss	sequence, 2 
	goto	led_mode_e_2
	movf	temp2, W
	movwf	LED2
led_mode_e_2	
	clrf	LED3
	btfss	sequence, 1 
	goto	led_mode_e_3
	movf	temp2, W
	movwf	LED3
led_mode_e_3	
	clrf	LED4
	btfss	sequence, 0 
	goto	led_mode_e_4
	movf	temp2, W
	movwf	LED4
led_mode_e_4
	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	
	goto	skip_leds
	
led_mode_f	
	movf	led_mode_reg, W
	xorlw	0x0f
	btfss	STATUS, Z
	goto	led_mode_10
	; custom leds different color rainbow
	incf	sequence, F
	clrf	LED1
	btfss	sequence, 3 
	goto	led_mode_f_1
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	movf	temp2, W
	movwf	LED1
led_mode_f_1	
	clrf	LED2
	btfss	sequence, 2 
	goto	led_mode_f_2
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F	
	movf	temp2, W
	movwf	LED2
led_mode_f_2	
	clrf	LED3
	btfss	sequence, 1 
	goto	led_mode_f_3
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	movf	temp2, W
	movwf	LED3
led_mode_f_3	
	clrf	LED4
	btfss	sequence, 0 
	goto	led_mode_f_4
	movf	led_display_seq, W
	; make sure W does not skip past the end of the list
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	led_display_seq
	movf	led_display_seq, W	
	call	_RGB_rotate
	movwf	temp2
	incf	led_display_seq, F
	movf	temp2, W
	movwf	LED4
led_mode_f_4
	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low	
	
	goto	skip_leds
	
led_mode_10	
	
	
	; TODO check led mode here
	
		
	; default mode if no other matches (rainbow left)
	movf	sequence, W
	call	_RGB_rotate
	movwf	LED1
	movf	sequence, W
	addlw	0x01
	call	_RGB_rotate
	movwf	LED2
	movf	sequence, W
	addlw	0x02
	call	_RGB_rotate
	movwf	LED3
	movf	sequence, W
	addlw	0x03
	call	_RGB_rotate
	movwf	LED4
	incf	sequence, F
	movf	sequence, W
	sublw	0x11		    ; W <= k C = 1
	btfss	STATUS, C
	clrf	sequence	
	movf	speed_high, W
	movwf	led_timer_high
	movf	speed_low, W
	movwf	led_timer_low
	
skip_leds
	
	; TODO add motor control here

	movlw	0x18
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page	
	goto	MAINLOOP_VIBE		; jump down to the vibe checks
	


    
ENDLOOP
	goto	ENDLOOP

	

;#########################################################	
; RGB_rotate Picks the correct value for the led based on the seq number in W
;#########################################################	
_RIDE_ME
	; make sure W does not skip past the end of the list
	movwf	call_temp
	sublw	0x33		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	call_temp
	movf	call_temp, W
	brw
	retlw	0x01		    ; Dot
	retlw	0x00		    ; gap
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x00		    ; gap
	retlw	0x01		    ; Dot
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x01		    ; Dot
	retlw	0x00		    ; gap
	retlw	0x01		    ; Dot
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x00		    ; gap
	retlw	0x01		    ; Dot
	retlw	0x00		    ; gap
	retlw	0x01		    ; Dot
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x01		    ; Dot
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x00		    ; gap
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x03		    ; Dash
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x00		    ; char end
	retlw	0x01		    ; Dot
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	retlw	0x00		    ; space
	
;#########################################################	
; RGB_rotate Picks the correct value for the led based on the seq number in W
;#########################################################	
_RGB_rotate
	; make sure W does not skip past the end of the list
	movwf	call_temp
	sublw	0x14		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	call_temp
	movf	call_temp, W
	brw
	retlw	0x03
	retlw	0x07
	retlw	0x0B
	retlw	0x0F
	retlw	0x0E
	retlw	0x0D
	retlw	0x0C
	retlw	0x1C
	retlw	0x2C
	retlw	0x3C
	retlw	0x38
	retlw	0x34
	retlw	0x30
	retlw	0x31
	retlw	0x32
	retlw	0x33
	retlw	0x23
	retlw	0x13
	retlw	0x03
	retlw	0x07
	retlw	0x0B
	
;#########################################################
; cycle the LFSR generator 8 bits and return the new result in W
; assumes user is in bank 0 before calling!!
;#########################################################
_CYCLE_LFSR
	;------------------
	movlw	d'2'
	movwf	BSR		
	;------------------
	; seed register with inial value
	bcf		call_temp, 0
	btfsc	LFSR_0, 0
	bsf		call_temp, 0
	; test bit invert result if set
	btfsc	LFSR_0, 2
	comf	call_temp, f
	; test bit invert result if set
	btfsc	LFSR_0, 6
	comf	call_temp, f
	; test bit invert result if set
	btfsc	LFSR_0, 7
	comf	call_temp, f
	
	; set carry bit
	bcf		STATUS, C
	btfsc	call_temp, 0
	bsf		STATUS, C
	
	; rotat the bits 
	rrf		LFSR_3, F
	rrf		LFSR_2, F
	rrf		LFSR_1, F
	rrf		LFSR_0, F
	movf	LFSR_0, W
	;------------------
	clrf	BSR		
	;------------------
	return

	
	
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; start of page 1
	org		1800h
;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	; ************************************************************
MAINLOOP_VIBE	
	; verfiy not in control mode
	movf	mode_ctl, W
	btfss	STATUS, Z	
	goto	VIBE_done
	
	; check if vibe cycle is running
	movf	vibe_cycle, W
	btfsc	STATUS, Z
	goto	VIBE_done

	; check if the led timers have expired yet
	movf	vibe_timer_high
	btfss	STATUS, Z
	goto	VIBE_done
	movf	vibe_timer_low
	btfss	STATUS, Z
	goto	VIBE_done
	
	; check subloop counter if 0 
	movf	vibe_subloop
	btfss	STATUS, Z
	goto	VIBE_subloop	
	
	; check if vibe_sequence is > vibe_stop	if so stop and reset seq
	movf	vibe_sequence, W
	subwf	vibe_stop, W				; F - W, W > F C = 0, W <= F C = 1
	btfsc	STATUS, C
	goto	VIBE_next
	clrf	vibe_sequence
	decf	vibe_cycle, F
	; if vibe cycle is 0 done with loops disable motors
	movf	vibe_cycle, W
	btfss	STATUS, Z
	goto	VIBE_done	
	movlw	0x00
	call	_Set_M1
	movlw	0x00
	call	_Set_M2
	goto	VIBE_done
	
	; sub delay expired set up next pattern in seq	
VIBE_next
	
	; check which pattern to use here vibe_mode 		
	movf	vibe_mode, W
	xorlw	0x01
	btfss	STATUS, Z
	goto	VIBE_option_2
	movf	vibe_sequence, W
	call	_VIBE_up_down_stop
	goto	VIBE_option_done
VIBE_option_2
	movf	vibe_mode, W
	xorlw	0x02
	btfss	STATUS, Z
	goto	VIBE_option_3
	movf	vibe_sequence, W
	call	_VIBE_up_down_dual	
	goto	VIBE_option_done
VIBE_option_3

	

	; default option
	movf	vibe_sequence, W
	call	_VIBE_up_down		
VIBE_option_done	
	
	

	; load pattern into M1, M2, and subloop counter
	movwf	vibe_temp
	call	_Set_M1
	bcf		STATUS, C
	rrf		vibe_temp, F
	bcf		STATUS, C
	rrf		vibe_temp, F
	bcf		STATUS, C
	rrf		vibe_temp, F
	movf	vibe_temp, W
	call	_Set_M2
	bcf		STATUS, C
	rrf		vibe_temp, F
	bcf		STATUS, C
	rrf		vibe_temp, F
	bcf		STATUS, C
	rrf		vibe_temp, F
	incf	vibe_temp, W
	movwf	vibe_subloop
	incf	vibe_sequence, F
	
VIBE_subloop
	decf	vibe_subloop
	movf	vibe_speed_h, W
	movwf	vibe_timer_high
	movf	vibe_speed_l, W
	movwf	vibe_timer_low		
	
VIBE_done
	movlw	0x08
	movwf	PCLATH				; set upper bits of the address so next goto jumps to the next page	
	goto	MAINLOOP			; TOOD make this jump down to vibe checks

	

;#########################################################	
; simple vibe up down on one motor
;#########################################################	
_VIBE_up_down_dual
	movwf	call_temp
	; move stop count to vibe_stop
	movlw	0x1B
	movwf	vibe_stop
	; make sure W does not skip past the end of the list
	movf	call_temp, W
	sublw	0x1B		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	call_temp
	movf	call_temp, W
	brw
	retlw	0x00
	retlw	0x01
	retlw	0x02	
	retlw	0x03	
	retlw	0x04	
	retlw	0x05	
	retlw	0x06	
	retlw	0x07	
	retlw	0x0F	
	retlw	0x17	
	retlw	0x1F	
	retlw	0x27	
	retlw	0x2F	
	retlw	0x37
	retlw	0x3F
	retlw	0x3E
	retlw	0x3D
	retlw	0x3C	
	retlw	0x3B
	retlw	0x3A
	retlw	0x39
	retlw	0x38
	retlw	0x30
	retlw	0x28
	retlw	0x20
	retlw	0x18
	retlw	0x10
	retlw	0x08
	
	
	
;#########################################################	
; simple vibe up down on one motor
;#########################################################	
_VIBE_up_down_stop
	movwf	call_temp
	; move stop count to vibe_stop
	movlw	0x0D
	movwf	vibe_stop
	; make sure W does not skip past the end of the list
	movf	call_temp, W
	sublw	0x0D		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	call_temp
	movf	call_temp, W
	brw
	retlw	0x00
	retlw	0x01
	retlw	0x02	
	retlw	0x03	
	retlw	0x04	
	retlw	0x05	
	retlw	0x06	
	retlw	0x07	
	retlw	0x06	
	retlw	0x05	
	retlw	0x04	
	retlw	0x03	
	retlw	0x02	
	retlw	0x01

;#########################################################	
; simple vibe up down on one motor
;#########################################################	
_VIBE_up_down
	movwf	call_temp
	; move stop count to vibe_stop
	movlw	0x0B
	movwf	vibe_stop
	; make sure W does not skip past the end of the list
	movf	call_temp, W
	sublw	0x0B		    ; W <= k, C = 1
	btfss	STATUS, C
	clrf	call_temp
	movf	call_temp, W
	brw
	retlw	0x01
	retlw	0x02	
	retlw	0x03	
	retlw	0x04	
	retlw	0x05	
	retlw	0x06	
	retlw	0x07	
	retlw	0x06	
	retlw	0x05	
	retlw	0x04	
	retlw	0x03	
	retlw	0x02	
	
	
;#########################################################	
; set PWM engine controlling motor off + 7 PWM levels
;#########################################################	
_Set_M1	
	; mask off then save W
	andlw	0x07
	movwf	gtemp
	
	; save the BSR
	movf	BSR, W
	movwf	bsr_save
	
	; check if set value is 0 (turn off motor)
	movf	gtemp, F
	btfss	STATUS, Z
	goto	Set_M1_on
	;------------------
	clrf	BSR
	;------------------
	bsf		TRISB, 2		    ; PWM output off (tristate). 
	goto	Set_M1_done
	
Set_M1_on	
	;------------------
	movlw	d'6'
	movwf	BSR		
	;------------------	
	; set up PWM engine
	bcf		STATUS, C
	rlf		gtemp, F
	rlf		gtemp, F
	rlf		gtemp, W			
	addlw	0x63				; min speed seems to be around 0x70 @ 3V in. Max speed is 0xD3 at any input voltage (PR2 of the timer) 
	movwf	PWM3DCH	
	;------------------
	clrf	BSR
	;------------------
	bcf		TRISB, 2		    ; PWM output on. 
	
Set_M1_done	
	; restore BSR
	movf	bsr_save, W
	movwf	BSR
	
	return

;#########################################################	
; set PWM engine controlling motor off + 7 PWM levels
;#########################################################	
_Set_M2	
	; mask off then save W
	andlw	0x07
	movwf	gtemp
	
	; save the BSR
	movf	BSR, W
	movwf	bsr_save
	
	; check if set value is 0 (turn off motor)
	movf	gtemp, F
	btfss	STATUS, Z
	goto	Set_M2_on
	;------------------
	clrf	BSR
	;------------------
	bsf		TRISB, 5		    ; PWM output off (tristate). 
	goto	Set_M2_done
	
Set_M2_on	
	;------------------
	movlw	d'6'
	movwf	BSR		
	;------------------	
	; set up PWM engine
	rlf		gtemp, F
	rlf		gtemp, F
	rlf		gtemp, W			
	addlw	0x63				; min speed seems to be around 0x70 @ 3V in. Max speed is 0xD3 at any input voltage (PR2 of the timer) 
	movwf	PWM4DCH	
	;------------------
	clrf	BSR
	;------------------
	bcf		TRISB, 5		    ; PWM output on. 
	
Set_M2_done	
	; restore BSR
	movf	bsr_save, W
	movwf	BSR
	
	return
	
	
	
	
	;### end of program ###
	end	