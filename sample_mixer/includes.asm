;
; Sample Mixer for sound effect playback
; By Mike Dailly, (c) Copyright 2020 all rights reserved.
;

; ************************************************************************
;
;	General equates and macros
;
; ************************************************************************
 
; Hardware
Kempston_Mouse_Buttons	equ	$fadf
Kempston_Mouse_X	equ	$fddf
Kempston_Mouse_Y	equ	$ffdf
Mouse_LB		equ	1			; 0 = pressed
Mouse_RB		equ	2
Mouse_MB		equ	4
Mouse_Wheel		equ	$f0

SpriteReg		equ	$57
SpriteShape		equ	$5b


			;rsreset
sp_lineHeight		equ	0
sp_lastblock		equ	sp_lineHeight+2
sp_texX			equ	sp_lastblock+1
sp_side			equ	sp_texX+1
sp_mapx			equ	sp_side+1
sp_mapy			equ	sp_mapx+1
sp_reserved		equ	sp_mapy+1
sp_size			equ	sp_reserved+1




Z80DMAPORT	equ 107




		// copper WAIT  VPOS,HPOS
WAIT		macro
		db	HI($8000+(\0&$1ff)+(( (\1/8) &$3f)<<9))
		db	LO($8000+(\0&$1ff)+(( ((\1/8) >>3) &$3f)<<9))
		endm
		// copper MOVE reg,val
MOVE		macro
		db	HI($0000+((\0&$ff)<<8)+(\1&$ff))
		db	LO($0000+((\0&$ff)<<8)+(\1&$ff))
		endm
CNOP		macro
		db	0,0
		endm

NEG_HL		macro
		xor	a
		sub	l
		ld	l,a
		sbc	a,a
		sub	h
		ld	h,a
		endm
NEG_DE		macro
		xor	a
		sub	e
		ld	e,a
		sbc	a,a
		sub	d
		ld	d,a
		endm
NEG_BC		macro
		xor	a
		sub	c
		ld	c,a
		sbc	a,a
		sub	b
		ld	b,a
		endm
NEG_DEHL	macro
		xor	a	; clear and reset carry
		sub	l
		ld	l,a

		ld	a,0
		sbc	a,h
		ld	h,a

		ld	a,0
		sbc	a,e
		ld	e,a

		ld	a,0
		sbc	a,d
		ld	d,a

		endm

NEG_HLDE	macro
		xor	a	; clear and reset carry
		sub	e
		ld	e,a

		ld	a,0
		sbc	a,d
		ld	d,a

		ld	a,0
		sbc	a,l
		ld	l,a

		ld	a,0
		sbc	a,h
		ld	h,a

		endm		


NEG_HLIX	macro
		xor	a	; clear and reset carry
		sub	ixl
		ld	ixl,a

		ld	a,0
		sbc	a,ixh
		ld	ixh,a

		ld	a,0
		sbc	a,l
		ld	l,a

		ld	a,0
		sbc	a,h
		ld	h,a

		endm	


NEG_HBC		macro
		xor	a	; clear and reset carry
		sub	c
		ld	c,a

		ld	a,0
		sbc	a,b
		ld	b,a

		ld	a,0
		sbc	a,h
		ld	h,a
		endm	


Mul_16x16_macro	macro
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
	endm


; ****************************************************************************************
; multiplication of two 16-bit numbers into a 32-bit product
;
; enter : de = signed 15-bit multiplicand = y
;         hl = signed 15-bit multiplicand = x
;
; exit  : hlde = siged 31-bit product
;
; ****************************************************************************************
SMul_16x16_macro	macro
	ld	a,h
	xor	d
	and	$80
	push	af			; negate on return?
	bit	7,d			; negate de?
	jr	z,@NotNegDE
	NEG_DE
@NotNegDE:
	bit	7,h			; negate hl?
	jr	z,@NotNegHL
	NEG_HL
@NotNegHL:
	;call	Mul_16x16


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


	pop	af			; should we negate dehl?
	jr	z,@skipneg
	
	; negate hl
	NEG_HLDE
@skipneg	
	endm


div_16x16_m	macro
		sll	c
		rla
		adc	hl, hl
		sbc	hl, de
		jr	nc, @SkipAds
		add	hl, de
		dec	c
@SkipAds:	

		endm


; ****************************************************************************************
;   hl >= $ 01 00
;   de >= $ 01 00
;
; de   = answer
; hl   = remainder
;
; ****************************************************************************************
OneOver_16x16_macro	
	macro
	; work out bank
	ld	a,h			; 4
	swapnib				; 8
	and	$f			; 7
	add	OneOver_Seg		; 7
	NextReg	$56,a			; 17

	; workout bank offset
	add	hl,hl			; 11
	ld	a,h			; 4
	and	$1f			; 7
	add	$c0			; 7
	ld	h,a			; 4

	ld	e,(hl)			; 7
	inc	l			; 4
	ld	d,(hl)			; 7 = 94
	endm




; ****************************************************************************************
;   hl >= $ 01 00
;   de >= $ 01 00
;
; de   = answer
; hl   = remainder
;
; ****************************************************************************************
Div_16x16_macro	macro
	ld	a,h			; 4
	ld	c,l			; 4
	ld	hl, 0			; 10

	sll	c			; 8
	rla				; 4
	adc	hl, hl			; 15
	sbc	hl, de			; 15
	jr	nc, @SkipAds1		; 12/7
	add	hl, de			; 15
	dec	c			; 4
@SkipAds1:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds2
	add	hl, de
	dec	c
@SkipAds2:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds3
	add	hl, de
	dec	c
@SkipAds3:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds4
	add	hl, de
	dec	c
@SkipAds4:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds5
	add	hl, de
	dec	c
@SkipAds5:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds6
	add	hl, de
	dec	c
@SkipAds6:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds7
	add	hl, de
	dec	c
@SkipAds7:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds8
	add	hl, de
	dec	c
@SkipAds8:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds9
	add	hl, de
	dec	c
@SkipAds9:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds10
	add	hl, de
	dec	c
@SkipAds10:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds11
	add	hl, de
	dec	c
@SkipAds11:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds12
	add	hl, de
	dec	c
@SkipAds12:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds13
	add	hl, de
	dec	c
@SkipAds13:

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds14
	add	hl, de
	dec	c
@SkipAds14:

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds15
	add	hl, de
	dec	c
@SkipAds15:	

	sll	c
	rla
	adc	hl, hl
	sbc	hl, de
	jr	nc, @SkipAds16
	add	hl, de
	dec	c
@SkipAds16:	

	ld	d,a
	ld	e,c
	endm




BREAK	macro
	db	$dd
	db	$01
	endm

