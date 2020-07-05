;
; Sample Mixer for sound effect playback
; By Mike Dailly, (c) Copyright 2020 all rights reserved.
;

; ************************************************************************
;
; 	Utils file - keep all utils variables in this file
;
; ************************************************************************

;bit 7 to lock io port 0x303B sprite number and nextreg sprite number together
SPRITE_SELECT_REGISTER			equ $34
SPRITE_X_VALUE_REGISTER			equ $35
SPRITE_Y_VALUE_REGISTER			equ $36
SPRITE_X_MSB_AND_FLIP_REGISTER		equ $37
SPRITE_PATTERN_ENABLE_REGISTER		equ $38
SPRITE_ATTRIBUTES_REGISTER		equ $39
SPRITE_X_VALUE_REGISTER_INC		equ $75
SPRITE_Y_VALUE_REGISTER_INC		equ $76
SPRITE_X_MSB_AND_FLIP_REGISTER_INC	equ $77
SPRITE_PATTERN_ENABLE_REGISTER_INC	equ $78
SPRITE_ATTRIBUTES_REGISTER_INC		equ $79

Z80_DMA_DATAGEAR_PORT			equ $6b

; ************************************************************************
;
;	Default RAM banks
;
;			128 Memory map uses 16K banks.
;		  0xffff + -------- + -------- + -------- + -------- + -------- + -------- + -------- + -------- + -------- + -------- +
;			 |  Bank 0  |  Bank 1  |  Bank 2  |  Bank 3  |  Bank 4  |  Bank 5  |  Bank 6  |  Bank 7  |          |
;			 |          |          | (also at |          | (        | (also at |          |          |  NEXT RAM------->
;			 |          |          |  0x8000) |          |          |  0x4000) |          |          |          |
;			 |          |          |          |          |          |  screen  |          |  screen  |          |
;		  0xc000 + -------- + -------- + -------- + -------- + -------- + -------- + -------- + -------- + -------- + -------- +
;			 |  Bank 2  |            Any one of these pages may be switched in.
;			 |          |
;			 |          |
;			 |          |
;		  0x8000 + -------- +
;			 |  Bank 5  |
;			 |          |
;			 |          |
;			 |  screen  |
;		  0x4000 + -------- + -------- +
;		         |  ROM 0   |  ROM 1   | Either ROM may be switched in.
;		         |          |          |
;		         |          |          |
;		         |          |          |
;		  0x0000 + -------- + -------- +
;
;
;
; ************************************************************************

; ************************************************************************
;
;	Function:	Clear the 256 colour screen to a set colour
;	In:		A = colour to clear to ($E3 makes it transparent)
;
; ************************************************************************
Cls256:
		push	bc
		push	de
		push	hl

		ld	d,a			; byte to clear to
                ld	e,3			; number of blocks
                ld	a,1			; first bank... (bank 0 with write enable bit set)

                ld      bc, $123b
@LoadAll:	out	(c),a			; bank in first bank
                push	af


                ; Fill lower 16K with the desired byte
                ld	hl,$3f00
@ClearLoop:	ld	(hl),d
                inc	l
                jp	nz,@ClearLoop
                dec	h
                jp	nz,@ClearLoop

                pop	af			; get block back
                add	a,$40
                dec	e			; loops 3 times
                jr	nz,@LoadAll

                ld      bc, $123b		; switch off background (should probably do an IN to get the original value)
                ld	a,0
                out	(c),a

                pop	hl
                pop	de
                pop	bc
                ret


; ************************************************************************
;
;	Function:	Clear the spectrum attribute screen
;	In:		A = attribute
;
; ************************************************************************
ClsATTR:
		push	hl
		push	bc
		push	de

	        ;ld      a,7
                ld      hl,$5800
                ld      de,$5801
                ld      bc,1000
                ld      (hl),a
                ldir

                pop	de
                pop	bc
                pop	hl
                ret


; ************************************************************************
;
;	Function:	clear the normal spectrum screen
;
; ************************************************************************
Cls:
		push	hl
		push	bc
		push	de

		xor	a
                ld      hl,$4000
                ld      de,$4001
                ld      bc,6143
                ld      (hl),a
                ldir

                pop	de
                pop	bc
                pop	hl
                ret



; ************************************************************************
;
;	Function:	Enable the 256 colour Layer 2 bitmap
;
; ************************************************************************
BitmapOn:
                ld      bc, $123b
                ld	a,2
                out	(c),a
                ret


; ************************************************************************
;
;	Function:	Disable the 256 colour Layer 2 bitmap
;
; ************************************************************************
BitmapOff:
                ld      bc, $123b
                ld	a,0
                out	(c),a
                ret





; ******************************************************************************
;
;	A  = hex value tp print
;	DE= address to print to (normal specturm screen)
;
; ******************************************************************************
PrintHex:
		push	bc
		push	hl
		push	af
		ld	bc,HexCharset

		srl	a
		srl	a
		srl	a
		srl	a
		call	DrawHexCharacter

		pop	af
		and	$f
		call	DrawHexCharacter
		pop	hl
		pop	bc
		ret


;
; A= hex value to print
;
DrawHexCharacter:
		ld	h,0
		ld	l,a
		add	hl,hl	;*8
		add	hl,hl
		add	hl,hl
		add	hl,bc	; add on base of character wet

		push	de
		push	bc
		ld	b,8
@lp1:		ld	a,(hl)
		ld	(de),a
		inc	hl		; cab't be sure it's on a 256 byte boundary
		inc	d		; next line down
		djnz	@lp1
		pop	bc
		pop	de
		inc	e
		ret


HexCharset:
		db %00000000	;char30  '0'
		db %00111100
		db %01000110
		db %01001010
		db %01010010
		db %01100010
		db %00111100
		db %00000000
		db %00000000	;char31	'1'
		db %00011000
		db %00101000
		db %00001000
		db %00001000
		db %00001000
		db %00111110
		db %00000000
		db %00000000	;char32	'2'
		db %00111100
		db %01000010
		db %00000010
		db %00111100
		db %01000000
		db %01111110
		db %00000000
		db %00000000	;char33	'3'
		db %00111100
		db %01000010
		db %00001100
		db %00000010
		db %01000010
		db %00111100
		db %00000000
		db %00000000	;char34	'4'
		db %00001000
		db %00011000
		db %00101000
		db %01001000
		db %01111110
		db %00001000
		db %00000000
		db %00000000	;char35	'5'
		db %01111110
		db %01000000
		db %01111100
		db %00000010
		db %01000010
		db %00111100
		db %00000000
		db %00000000	;char36	'6'
		db %00111100
		db %01000000
		db %01111100
		db %01000010
		db %01000010
		db %00111100
		db %00000000
		db %00000000	;char37	'7'
		db %01111110
		db %00000010
		db %00000100
		db %00001000
		db %00010000
		db %00010000
		db %00000000
		db %00000000	;char38	'8'
		db %00111100
		db %01000010
		db %00111100
		db %01000010
		db %01000010
		db %00111100
		db %00000000
		db %00000000	;char39	'9'
		db %00111100
		db %01000010
		db %01000010
		db %00111110
		db %00000010
		db %00111100
		db %00000000
		db %00000000	;char41	'A'
		db %00111100
		db %01000010
		db %01000010
		db %01111110
		db %01000010
		db %01000010
		db %00000000
		db %00000000	;char42	'B'
		db %01111100
		db %01000010
		db %01111100
		db %01000010
		db %01000010
		db %01111100
		db %00000000
		db %00000000	;char43	'C'
		db %00111100
		db %01000010
		db %01000000
		db %01000000
		db %01000010
		db %00111100
		db %00000000
		db %00000000	;char44	'D'
		db %01111000
		db %01000100
		db %01000010
		db %01000010
		db %01000100
		db %01111000
		db %00000000
		db %00000000	;char45	'E'
		db %01111110
		db %01000000
		db %01111100
		db %01000000
		db %01000000
		db %01111110
		db %00000000
		db %00000000	;char46	'F'
		db %01111110
		db %01000000
		db %01111100
		db %01000000
		db %01000000
		db %01000000
		db %00000000






; ******************************************************************************
;
; Function:	ReadMouse  ***** Not verified on real machine yet *****
;		This is probably wrong, but I'll need it on a real machine
;		to test - along with a PS2 mouse....err...
;
;		uses bc,a
; ******************************************************************************
ReadMouse:
		ld	bc,Kempston_Mouse_Buttons
		in	a,(c)
		ld	(MouseButtons),a

		ld	bc,Kempston_Mouse_X
		in	a,(c)
		ld	(MouseX),a

		ld	bc,Kempston_Mouse_Y
		in	a,(c)
		ld	(MouseY),a

		ret

MouseButtons	db	0
MouseX		db	0
MouseY		db	0



; ******************************************************************************
;
; Function:	Upload a set of sprites
; In:		E = sprite shape to start at
;		D = number of sprites
;		HL = shape data
;
; ******************************************************************************
UploadSprites
		; Upload sprite graphics
                ld      a,e		; get start shape
                ld	e,0		; each pattern is 256 bytes
@AllSprites:
                ; select pattern 2
                ld      bc, $303B
                out     (c),a

                ; upload ALL sprite sprite image data
                ld      bc, SpriteShape
@UpLoadSprite:
                outinb			; port=(hl), hl++
                dec	e
                jp	nz, @UpLoadSprite
                dec	d
                jp	nz, @UpLoadSprite
                ret



;===========================================================================
; hl = source
; bc = length
; set port to write to with NEXTREG_REGISTER_SELECT_PORT
; prior to call
;
; Function:	Upload a set of sprites
; In:		E = sprite shape to start at
;		D = number of sprites
;		HL = shape data
;===========================================================================
DMASprites
		; Upload sprite graphics
                ld      a,e		; get start shape
                ld	e,0		; each pattern is 256 bytes
@AllSprites:
                ; select pattern "e"
                ld      bc, $303B
                out     (c),a

		ld (DMASource),hl
		ld (DMALength),de

		; Now set the transfer going...
		ld hl,DMACode
		ld b,DMACodeLen
		ld c,Z80_DMA_DATAGEAR_PORT
		otir
		ret

;===========================================================================
;
;===========================================================================
DMACode		db $83					; DMA Disable
		db %01111101				; R0-Transfer mode, A -> B, write adress + block length
DMASource	dw 0					; R0-Port A, Start address				(source address)
DMALength	dw 0					; R0-Block length					(length in bytes)
		db %01010100				; R1-read A time byte, increment, to memory, bitmask
		db %00000010				; R1-Cycle length port A
		db %01101000				; R2-write B time byte, increment, to memory, bitmask
		db %00000010				; R2-Cycle length port B
		db %10101101 				; R4-Continuous mode  (use this for block tansfer), write dest adress
		dw SpriteShape				; R4-Dest address					(destination address)
		db %10000010				; R5-Restart on end of block, RDY active LOW
		db $cf					; R6-Load
		db $87					; R6-Enable DMA
dmaCodeLen	equ *-dmaCode

; ******************************************************************************
; Function:	Scan the whole keyboard
; ******************************************************************************
ReadKeyboard:
		ld		b,39
		ld		hl,Keys
		xor		a
@lp1:	ld		(hl),a
		inc		hl
		djnz	@lp1

		ld		ix,Keys
		ld		bc,$fefe	;Caps,Z,X,C,V
		ld		hl,RawKeys
@ReadAllKeys:	in	a,(c)
		ld		(hl),a
		inc		hl

		ld		d,5
		ld		e,$ff
@DoAll	srl		a
		jr		c,@notset
		ld		(ix+0),e
@notset	inc		ix
		dec		d
		jr		nz,@DoAll

		ld		a,b
		sla		a
		jr		nc,ExitKeyRead
		or		1
		ld		b,a
		jp		@ReadAllKeys
ExitKeyRead:
		ret


; half row 1
VK_CAPS		equ	0
VK_Z		equ	1
VK_X		equ	2
VK_C		equ	3
VK_V		equ	4
; half row 2
VK_A		equ	5
VK_S		equ	6
VK_D		equ	7
VK_F		equ	8
VK_G		equ	9
; half row 3
VK_Q		equ	10
VK_W		equ	11
VK_E		equ	12
VK_R		equ	13
VK_T		equ	14
; half row 4
VK_1		equ	15
VK_2		equ	16
VK_3		equ	17
VK_4		equ	18
VK_5		equ	19

; half row 5
VK_0		equ	20
VK_9		equ	21
VK_8		equ	22
VK_7		equ	23
VK_6		equ	24
; half row 6
VK_P		equ	25
VK_O		equ	26
VK_I		equ	27
VK_U		equ	28
VK_Y		equ	29

; half row 7
VK_ENTER	equ	30
VK_L		equ	31
VK_K		equ	32
VK_J		equ	33
VK_H		equ	34
; half row 8
VK_SPACE	equ	35
VK_SYM		equ	36
VK_M		equ	37
VK_N		equ	38
VK_B		equ	39

Keys:		ds	40
RawKeys		ds	8



; ******************************************************************************
;
; Function:	Upload copper
; In:		hl = address
;		de = size
;
; ******************************************************************************
UploadCopper:
		ld	a,0
		NextReg	$61,a
		ld	a,0
		NextReg	$62,a


@lp1:		ld	a,(hl)
		NextReg	$60,a

		inc	hl
		dec	de
		ld	a,d
		or	e
		cp	0
		jr	nz,@lp1
		ret





; ******************************************************************************
;
; Function:	Read the current Raster into HL
; Out:		hl = address
;
; ******************************************************************************
ReadRaster:
		; read MSB of raster first
		ld	a,$1e
		ld	bc,$243b	; select NEXT register
		out	(c),a
		inc	b		; $253b to access (read or write) value
		in	a,(c)
		and	1
		ld	h,a

		; now read LSB of raster
		ld	a,$1f
		dec	b
		out	(c),a
		inc	b
		in	a,(c)
		ld	l,a
		ret


; ******************************************************************************
;
; Function:	Copy memory
; Out:		hl = source
;		de = dest
;		bc = size
;
; ******************************************************************************
DMACopy:
		ld	(DMASrc),hl		; 16
		ld	(DMADest),de		; 20
		ld	(DMALen),bc
		ld	hl,DMACopy_Prog 		; 10
		ld	bc,DMASIZE*256 + Z80DMAPORT	; 10
		otir
		ret

DMACopy_Prog
	db $C3			;R6-RESET DMA
	db $C7			;R6-RESET PORT A Timing
        db $CB			;R6-SET PORT B Timing same as PORT A

        db $7D 			;R0-Transfer mode, A -> B
DMASrc  dw $1234		;R0-Port A, Start address				(source address)
DMALen	dw 240			;R0-Block length					(length in bytes)

        db $54 			;R1-Port A address incrementing, variable timing
        db $02			;R1-Cycle length port A

        db $50			;R2-Port B address fixed, variable timing
        db $02 			;R2-Cycle length port B

        ;db $C0			;R3-DMA Enabled, Interrupt disabled

	db $AD 			;R4-Continuous mode  (use this for block tansfer)
DMADest
	dw $4000		;R4-Dest address					(destination address)

	db $82			;R5-Restart on end of block, RDY active LOW

	db $CF			;R6-Load
	db $B3			;R6-Force Ready
	db $87			;R6-Enable DMA
ENDDMA

DMASIZE      equ ENDDMA-DMACopy_Prog

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

;--------------------------------------------------------
;In:	hl = hex number
;	de = layer 2 address
;Out:	de = next character in layer 2
;--------------------------------------------------------
DrawHex16
	ld	a,h
	call	DrawHex8
	ld	a,l
;--------------------------------------------------------
;In:	a  = hex number
;	de = layer 2 address
;Out:	de = next character in layer 2
;--------------------------------------------------------
DrawHex8
	push	af
	swapnib
	call	DrawHex4
	pop	af
DrawHex4
	and	15

;--------------------------------------------------------
;In:	a  = number
;	de = layer 2 address
;Out:	de = next character in layer 2
;--------------------------------------------------------
DrawNumber:
	push	de
	ld	e,a
	ld	d,35
	mul
	ld	hl,Numbers
	add	hl,de
	pop	de

	ld	a,%00001011		; bank in bank 0, writes
	ld      bc, $123b
	out	(c),a			; bank in first bank

	ld	a,$e3
	ld	bc,$7ff
@lp1:	ldix
	ldix
	ldix
	ldix
	ldix
	add	de,251
	djnz	@lp1

	add	de,-((7*256))+6		; move back up to the start of the character and along to the next
	ret


	ld	a,%00000011		; bank in bank 0, writes
	ld      bc, $123b
	out	(c),a			; bank in first bank

Numbers:
	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$e3,$00,$00,$00,$e3
	db	$e3,$00,$ff,$00,$e3
	db	$e3,$00,$ff,$00,$e3
	db	$e3,$00,$ff,$00,$e3
	db	$e3,$00,$ff,$00,$e3
	db	$e3,$00,$ff,$00,$e3
	db	$e3,$00,$00,$00,$e3

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$ff,$00
	db	$e3,$00,$ff,$ff,$00
	db	$00,$00,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$e3
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$ff,$00
	db	$e3,$e3,$00,$ff,$00
	db	$e3,$e3,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$e3,$e3
	db	$00,$ff,$00,$e3,$e3
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$ff,$00
	db	$e3,$e3,$00,$ff,$00
	db	$e3,$e3,$00,$ff,$00
	db	$e3,$e3,$00,$ff,$00
	db	$e3,$e3,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$ff,$00
	db	$e3,$e3,$00,$ff,$00
	db	$00,$e3,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$e3
	db	$00,$ff,$ff,$00,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$00,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$00,$e3,$e3
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$e3
	db	$00,$ff,$ff,$00,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$00,$ff,$00
	db	$00,$ff,$ff,$00,$00
	db	$00,$00,$00,$00,$e3

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$00,$00,$00,$00

	db	$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$ff,$ff,$00
	db	$00,$ff,$00,$00,$00
	db	$00,$ff,$00,$e3,$e3
	db	$00,$00,$00,$e3,$e3




;-----------------------------------------------------
; de = sprite x, l = sprite y, c = image, b = flip, h = attributes.
;-----------------------------------------------------
SetSprite_4Bit
	ld	a,e
	nextreg	SPRITE_X_VALUE_REGISTER,a

	ld	a,l
	sub	16
	nextreg	SPRITE_Y_VALUE_REGISTER,a

	ld	a,d
	and	1
	or	b
	nextreg	SPRITE_X_MSB_AND_FLIP_REGISTER,a

	push	hl
	ld	a,c
	and	$80
	or	$40
	ld	l,a
	ld	a,c
	rra
	and	$3f
	or	l
	pop	hl
	nextreg SPRITE_PATTERN_ENABLE_REGISTER,a

	ld	a,c
	and	1
	rrca
	rrca
	or	h
	nextreg SPRITE_ATTRIBUTES_REGISTER_INC,a

	ret




