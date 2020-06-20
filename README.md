# mod_player
ZX Spectrum Next (z80N) Mod player
Copyright Mike Dailly 2020 All rights reserved.

The source to this player may be used freely for both commercial and non-commercial reasons, without charge but copyright is maintained and credit must be given to anyone who has contributed (see below) in any project where it is used. No warranty is given to this project and you use it at your own risk.

If you extend it, imrpove it, add new or missing features, please consider pushing back all changes for others to benefit from.


Contributors
------------
Mike Dailly


Please be aware, if you are looking for a "Pure" Z80 Mod player, this version makes use of ZX Spectrum Next features, such as banking and extended Z80 instructions.





Usage:

	ld    a,BANK		; the core bank where the mod file lives
	ld    b,1			; 1 to initialise the samples (do this once only)
	call  ModInit		; load and init the mod
	call	ModPlay		; start the mod file playing


	; inside an IRQ or mainloop if running 50hz
	call	ModTick


; These determain the playback speed. 
; Please note, if changing these, you will need to rebuild the note conversion table (c# code)
TVRate			equ	50						; framerate
SamplesPerFrame	equ	128						; 104 samples per frame

; The bank register and base address we're using (uses this one, and the next one)
MOD_BANK		equ	$52				; which MMU bank to use (this one and the next)
MOD_ADD			equ	$4000			; base address of this bank


