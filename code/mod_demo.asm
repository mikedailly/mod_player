;
; MOD player
; By Mike Dailly, (c) 2020 all rights reserved.
;

                opt     Z80                                     ; Set Z80 mode
                opt     ZXNEXTREG

                include "includes.asm"

ModFileBank		equ		16

                seg     CODE_SEG, 4:$0000,$8000
                seg     MOD_SEG,  ModFileBank:$0000,$0000

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

	    NextReg 128,0                   ; Make sure expansion bus is off.....
	    NextReg $07,3                   ; Set to 28Mhz
	    ;NextReg $05,1			; 50Hz mode  (bit 1 needs to be read from OS)
	    ;NextReg $05,4			; 60Hz mode
	    NextReg	$08,%01001010   ; $50			; disable ram contention, enable specdrum, turbosound

	    NextReg $4a,0           ; transparent fallback
	    NextReg $4c,0           ; tile transparent colour

		ld		a,ModFileBank
		call	ModInit
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
		ld		de,150
		sbc		hl,de
		ld		a,h
		or		l
		jr		nz,@wait

		call    ReadKeyboard
		nextreg $4a,%11111111
    	ld      a,2
    	out     ($fe),a
		call    ReadKeyboard


    	ld      a,1
    	out     ($fe),a
		call	ModTick	
		nextreg $4a,0
    	ld      a,0
    	out     ($fe),a

	
		if 0
		ld	a,(FrameCount)
		ld	(LastFrame),a
		ld	de,4*256+4
		call	DrawNumber

		ld	de,4*256+16
		ld	a,(posX+1)
		and	31
		call	DrawHex8
		ld	a,(posY+1)
		and	31
		call	DrawHex8
		endif
		jp      MainLoop


        	include "mod_player.asm"
        	include "utils.asm"
        	include "maths.asm"
		include	"irq.asm"		; MUST start at $fd00

		seg	MOD_SEG
ModFile:	incbin	"axelf.mod"

; *****************************************************************************************************************************
; save
; *****************************************************************************************************************************
               	savenex "mod_player.nex",StartAddress,StackStart


