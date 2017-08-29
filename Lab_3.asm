;************************************************************************
; Filename: Lab_3														*
;																		*
; ELEC3450 - Microprocessors											*
; Wentworth Institute of Technology										*
; Professor Bruce Decker												*
;																		*
; Student #1 Name: Takaris Seales										*
; Course Section: 03													*
; Date of Lab: <05-31-2017>												*
; Semester: Summer 2017													*
;																		*
; Function: This program demonstrates the use of interrupts and         *
; interrupt service routines (ISR).  As in the previous two labs, eight *
; LEDS are connected to outputs.  However, instead of multiple switches *
; to select the current pattern, a single switch activates an ISR,      *
; which selects the next sequence to display.                           *	
; Upon energizing, it performs a brief test of all 8 lights             *
; (.48 seconds on and .48 second off.                                   *	
; The watchdog timer is enabled, and the prescaler set to 64.  This     *
; causes a timeout after 2.30 seconds.  There is one CLRWDT at the      *
; begining of the switch test function.                                 *		
;																	
; Wiring: 																*
; Two DIP switches attached to RA3 and RA5 are used to control the      *
; speed of the light arrangements outside of the initial test.   The    *
; DCOUNT variable is set at the beginning of each loop dependent    *
; on the settings of RA3 and RA5.                                       *					*
;************************************************************************												*
; A register may hold an instruction, a storage address, or any kind of data
;(such as a bit sequence or individual characters)
;BYTE-ORIENTED INSTRUCTION:	
;'f'-specifies which register is to be used by the instruction	
;'d'-designation designator: where the result of the operation is to be placed
;BIT-ORIENTED INSTRUCTION:
;'b'-bit field designator: selects # of bit affected by operation
;'f'-represents # of file in which the bit is located
;
;'W'-working register: accumulator of device. Used as an operand in conjunction with
;	 the ALU during two operand instructions															*
;************************************************************************

		#include <p16f877a.inc>

TEMP_W					EQU 0X20			
TEMP_STATUS				EQU 0X21
COUNT1					EQU 0X22
COUNT2					EQU 0X23
COUNT3					EQU 0X24
DCOUNT					EQU 0X25
LIGHTCOUNT				EQU 0X26


		__CONFIG		0X373A 				;Control bits for CONFIG Register w/o WDT enabled			

		
		ORG				0X0000				;Start of memory
		GOTO 		MAIN

		ORG 			0X0004				;INTR Vector Address
PUSH										;Stores Status and W register in temp. registers

		MOVWF 		TEMP_W
		SWAPF		STATUS,W
		MOVWF 		TEMP_STATUS
		BTFSC		INTCON, INTF
		GOTO		INTRB0

POP											;Restores W and Status registers
	
		SWAPF		TEMP_STATUS,W
		MOVWF		STATUS
		SWAPF		TEMP_W,F
		SWAPF		TEMP_W,W
		RETFIE

INTRB0										;ISR FOR RB0
		INCF		LIGHTCOUNT,F
		BCF			INTCON, INTF
		GOTO 		POP		


MAIN
		CLRF 		PORTA					;Clear both GPIOs to be used	
		CLRF 		PORTB					
		BSF			STATUS, RP0				; Bank1 for TRISA & TRISB
		MOVLW		0XE8					;TRISA is 1110 1000 to have RA0-RA2 as outputs & RA3/RA5 as inputs (RA4 pin is a Schmitt Trigger input & open drain output)
		MOVWF 		TRISA
		MOVLW		0X01					;TRISB is 0000 0001 to have RB1-RB7 as outputs, and RB0 as inputs
		MOVWF		TRISB
		MOVLW		0XFF 
		MOVWF 		OPTION_REG
		BCF			STATUS, RP0				;Bank0
		BSF			INTCON, INTE
		CLRF		LIGHTCOUNT				;Set light arrangement to 0
		BSF			INTCON, GIE				;Enable all interrupts
		MOVLW		0X07					;Illuminate lights
		MOVWF		PORTA
		MOVLW		0X3E
		MOVWF		PORTB

		MOVLW 		0X18					;Sets delay for .48 sec
		MOVWF		DCOUNT
		CALL		DELAY					;.48sec delay

		MOVLW		0X00					;Turn off all lights
		MOVWF		PORTA
		MOVWF		PORTB
		CALL		DELAY					;.48sec delay

SWTEST
		CLRWDT								;Clears WDT and postscaler to prevent RESET
		
		MOVLW 		0X0A					;Default value if both switches are off
		BTFSC		PORTA, RA3
		ADDLW		0X0A					;If first switch on,add 10 to DCOUNT

DELAYCOUNT
		BTFSC		PORTA, RA5
		ADDLW		0X19					;If second switch on, add 25 to DCOUNT

		MOVWF 		DCOUNT
		MOVF		LIGHTCOUNT,W			;Check to see if value is 0x03
		ADDLW 		0XFC
		BTFSC		STATUS,C				;C = Current Bank
		CLRF 		LIGHTCOUNT
		
		MOVF		LIGHTCOUNT,W			;Check to see if value is 0x03
		ADDLW		0xFD
		BTFSC		STATUS,C				;Yes = Go to sequence 3
		GOTO		LIGHTSEQ3

		MOVF 		LIGHTCOUNT,W			;Check to see if value is 0x02
		ADDLW		0XFE
		BTFSC		STATUS,C				;Yes = Go to sequence 2	
		GOTO		LIGHTSEQ2				

		MOVF 		LIGHTCOUNT,W			;Check to see if value is 0x01	
		ADDLW		0XFF
		BTFSC		STATUS,C				;Yes = Go to sequence 1
		GOTO		LIGHTSEQ1

		GOTO		NOLIGHTS				;Otherwise, no light routine	

NOLIGHTS
		MOVLW		0X00					;Disable all lights
		MOVWF		PORTA
		MOVWF		PORTB
		CALL 		DELAY					;Delay based on previous DIP switch settings
		
		GOTO 		SWTEST

LIGHTSEQ3
		MOVLW		0X09
		MOVWF 		PORTA
		MOVLW		0X90	
		MOVWF		PORTB
		CALL		DELAY
		MOVLW		0X06
		MOVWF		PORTA
		MOVLW		0X60
		MOVWF		PORTB
		CALL		DELAY

		GOTO		SWTEST						;Return to top of switch test loop

LIGHTSEQ2
		MOVLW		0X04
		MOVWF 		PORTA
		MOVLW		0X40
		MOVWF		PORTB
		CALL		DELAY
		MOVLW		0X0A
		MOVWF		PORTA
		MOVLW		0XA0
		MOVWF		PORTB
		CALL		DELAY

		GOTO		SWTEST

LIGHTSEQ1
		MOVLW		0X03
		MOVWF		PORTA
		MOVLW 		0X30
		MOVWF		PORTB
		CALL		DELAY
		MOVLW		0X08
		MOVWF		PORTA
		MOVLW		0X80
		MOVWF		PORTB
		CALL		DELAY
		
		GOTO 		SWTEST	
DELAY											;Variable delay loop subroutine. Uses DCOUNT for outer loop variable
		MOVF		DCOUNT, W
		MOVWF		COUNT3

LOOPOUT
		MOVLW		0XA9
		MOVWF		COUNT2

LOOPMID
		MOVLW		0XC4
		MOVWF		COUNT1

LOOPIN
		DECFSZ		COUNT1,F					;Decrement f, If 'F' is 0 rsult placed in W and NOP executed. If 'F' is 1 result placed back in COUNT2
		GOTO		LOOPIN
		
		DECFSZ		COUNT2,F
		GOTO		LOOPMID

		DECFSZ		COUNT3,F
		GOTO		LOOPOUT

	

		RETURN

		END