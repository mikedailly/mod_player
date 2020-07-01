;
; MOD player demo
; By Mike Dailly, (c) 2020 all rights reserved.
; Please see the readme for license details
;

                opt     Z80                                     ; Set Z80 mode
                opt     ZXNEXTREG

                include "includes.asm"

ModVolumeBank	equ		16
ModFileBank		equ		18
ModSampleBank	equ		50


                seg     CODE_SEG, 4:$0000,$8000
                seg     MOD_SEG,  ModFileBank:$0000,$0000
                seg     MOD_VOLUME,  ModVolumeBank:$0000,$0000		; volume conversion goes here


                seg	CODE_SEG

; *****************************************************************************************************************************
; Start of game code
; *****************************************************************************************************************************
StartAddress:
	    di
	    ld      sp,StackStart&$fffe
	    ld      a,VectorTable>>8
	    ld      i,a
	    im      2
	    ei

	    NextReg 128,0           ; Make sure expansion bus is off.....
	    NextReg $07,3           ; Set to 28Mhz
	    NextReg $05,1			; 50Hz mode  (bit 1 needs to be read from OS)
	    ;NextReg $05,4			; 60Hz mode
	    NextReg	$08,%01001010   ; $50			; disable ram contention, enable specdrum, turbosound

	    NextReg $4a,0           ; transparent fallback
	    NextReg $4c,0           ; tile transparent colour

		call	Cls
		ld		a,7
		call	ClsATTR
		call	ModInit			; initialise the mod player - generate tables etc...

		ld		a,ModFileBank	; where the mod file lives
		ld		b,1				; we need to setup the samples first time in...
		call	ModLoad
		call	ModPlay


; ----------------------------------------------------------------------------------------------------
;               Main loop
; ----------------------------------------------------------------------------------------------------
MainLoop:
		xor	a
		ld	(FrameCount),a
		ld	(VBlank),a

WaitVBlank:
    	ld	a,(VBlank)
    	and	a
		jr	z,WaitVBlank    	

@wait:
		call	ReadRaster
		ld		de,30
		sbc		hl,de
		ld		a,h
		or		l
		jr		nz,@wait

 		call    ReadKeyboard



		NextReg	$52,10
		NextReg	$53,11


		ld		a,(ModPatternIndex)
		push	hl
		push	de
		push	bc
		push	af
		ld		de,$4001
		call	PrintHex
		pop		af
		pop		bc
		pop		de
		pop		hl


;		nextreg $4a,%11111111
    	ld      a,1
    	out     ($fe),a 
		call	ModTick	
		nextreg $4a,0
    	ld      a,0
    	out     ($fe),a


		;NextReg	$52,10
		;NextReg	$53,11

		;call	DMAReadLen
		;push	hl
		;ld		a,h
		;ld		a,(ModDMAValue)
		;ld		de,$4004
		;call	PrintHex
		;pop		hl
		;ld		a,l
		;ld		de,$4006
		;call	PrintHex

		jp      MainLoop




        include "mod_player.asm"
		
		seg	CODE_SEG
        include "utils.asm"
        include "maths.asm"
		include	"irq.asm"		; MUST start at $fd00

		seg	MOD_SEG
ModFile:
;		incbin	"8channel.xm"
;		incbin	"LIES.mod"
;		incbin	"MATKAMIE.mod"
;		incbin	"TEST_MATKAMIE.mod"
;		incbin	"abandon_2_0.mod"
;		incbin	"test2.mod"
;		incbin	"blood_money_title.mod"	
;		incbin	"blood_test.mod"
		incbin	"axelf.mod"

; *****************************************************************************************************************************
; save
; *****************************************************************************************************************************
		savenex "mod_player.nex",StartAddress,StackStart




