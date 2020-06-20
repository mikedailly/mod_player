; ****************************************************************************************
; multiplication of two 16-bit numbers into a 32-bit product
;
; enter : de = 16-bit multiplicand = y
;         hl = 16-bit multiplicand = x
;
; exit  : hlde = 32-bit product
;         carry reset
;
; uses  : af, bc, de, hl
; ****************************************************************************************
Mul_16x16:
	ld	b,l                      ; x0
	ld	c,e                      ; y0
	ld	e,l                      ; x0
	ld	l,d
	push	hl                     	; x1 y1
	ld	l,c                      ; y0

	; bc = x0 y0
	; de = y1 x0
	; hl = x1 y0
	; stack = x1 y1

	mul	                      ; y1*x0
	ex	de,hl
	mul                       	; x1*y0

	xor	a                       ; zero A
	add	hl,de                   ; sum cross products p2 p1
	adc	a,a                     ; capture carry p3

	ld	e,c                      ; x0
	ld	d,b                      ; y0
	mul                       	; y0*x0

	ld	b,a                      ; carry from cross products
	ld	c,h                      ; LSB of MSW from cross products

	ld	a,d
	add	a,l
	ld	h,a
	ld	l,e                      ; LSW in HL p1 p0

	pop	de
	mul                       	; x1*y1

	ex	de,hl
	adc	hl,bc
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
		ld c,Z80_DMA_DATAGEAR_PORT
		otir
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
ModSampleRate:
		db (DMABaseFreq) / (((SamplesPerFrame+5)*TVRate))		; set PreScaler 875000kHz/freq = ???

		db $cd			; R4-Dest destination port
		;db $fe,$00		; $FFDF = SpecDrum
		db $df,$ff		; $FFDF = SpecDrum

		db $82			; R5-Restart on end of block, RDY active LOW
		db $bb			; R6
		db $08			; R6 Read mask enable (Port A address low)
		
		db $cf			; Load starting address for both potrs, clear byte counter
		db $b3			; Force internal ready condition 
		db $87			; enable DMA




