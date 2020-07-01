
MOD_Z80_DMA_DATAGEAR_PORT			equ $6b

; ****************************************************************************************
; multiplication of a 8 by 16bit  numbers into a 24-bit product
;
; enter : de = 16-bit multiplicand = y
;         l  = 8-bit multiplicand  = x
;
; exit  : ahl = 32-bit product
;         carry reset
;
; uses  : af, bc, de, hl
; ****************************************************************************************
Mul_16x8:
	ld		c,e
	ld		e,l
	ld		a,l
	mul				; l*d
	ex		de,hl

	ld		e,c		; l*e
	ld		d,a
	mul
	
	;0de = l*e
	;hl0 = d*l*256
	xor		a
	ld		c,h	
	ld		h,l
	ld		l,a

	; chl = d*l*256 = ch0
	; ade
	add		hl,de
	adc		a,c
	ret


;===========================================================================
; hl = source
; bc = length
; set port to write to with NEXTREG_REGISTER_SELECT_PORT
; prior to call
;
; Function:	Upload a set of sprites
; In:		HL = Sample address
; used		A
;===========================================================================
ModPlaySample:	
		ld	(ModSampleAddress),hl

		; Now set the transfer going...
		ld hl,ModSoundDMA
		ld b,$16
		ld c,MOD_Z80_DMA_DATAGEAR_PORT
		otir
		ret


DMAReadLen:
		ld		a,$6
		call	DMAReadRegister
		ld		l,a
		in		a,(MOD_Z80_DMA_DATAGEAR_PORT)
		ld		h,a
		ret

DMAReadRegister:
		push	af
		ld		a,$bb
		out		(MOD_Z80_DMA_DATAGEAR_PORT),a
		pop		af
		out		(MOD_Z80_DMA_DATAGEAR_PORT),a
		in		a,(MOD_Z80_DMA_DATAGEAR_PORT)
		ret
		

;===========================================================================
;
;===========================================================================
ModSoundDMA:
		db $c3			; Reset Interrupt circuitry, Disable interrupt and BUS request logic, unforce internal ready condition, disable "MUXCE" and STOP auto repeat
		db $c7			; Reset Port A Timing TO standard Z80 CPU timing
		
		db $ca			; unknown

		db $7d			; R0-Transfer mode, A -> B, write adress + block length
ModSampleAddress:	
		db $00,$60				; src
ModSampleLength:
		dw SamplesPerFrame		; length
				
		db $54			; R1-read A time byte, increment, to memory, bitmask
		db $02			; R1-Cycle length port A

		db $68			; R2-write B time byte, increment, to memory, bitmask
		db $22			; R2-Cycle length port B + NEXT extension
DMASampleRate:
		db (DMABaseFreq) / (((SamplesPerFrame)*TVRate))		; set PreScaler 875000kHz/freq = ???
		;db	66

		db $cd			; R4-Dest destination port
DMADestPort:
		;db $fe,$00		; $FFDF = SpecDrum
		db $df,$ff		; $FFDF = SpecDrum

		db $82			; R5-Restart on end of block, RDY active LOW
		db $bb			; R6
		db $08			; R6 Read mask enable (Port A address low)
		
		db $cf			; Load starting address for both potrs, clear byte counter
		db $b3			; Force internal ready condition 
		db $87			; enable DMA



; ******************************************************************************
; Function:	Save the MMUs we're going to overwrite
; Out:		a = register to read
; Out:		a = value in register
; ******************************************************************************
SaveMMUs:
		ld		a,$50
		call	ReadNextReg
		ld		(ModMMUStore),a

		ld		a,$51
		call	ReadNextReg
		ld		(ModMMUStore+1),a

		ld		a,$52
		call	ReadNextReg
		ld		(ModMMUStore+2),a

		ld		a,$53
		call	ReadNextReg
		ld		(ModMMUStore+3),a
		ret


; ******************************************************************************
; Function:	restore all MMUs
; ******************************************************************************
RestoreMMUs:
		ld		a,(ModMMUStore)
		NextReg	$50,a
		ld		a,(ModMMUStore+1)
		NextReg	$51,a
		ld		a,(ModMMUStore+2)
		NextReg	$52,a
		ld		a,(ModMMUStore+3)
		NextReg	$53,a
		ret
		
; ******************************************************************************
; Function:	Read a next register
; Out:		a = register to read
; Out:		a = value in register
; ******************************************************************************
ReadNextReg:
		; read MSB of raster first
		ld	bc,$243b	; select NEXT register
		out	(c),a
		inc	b			; $253b to access (read or write) value
		in	a,(c)
		ret



