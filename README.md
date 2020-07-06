# mod_player
ZX Spectrum Next (z80N) Mod player
Copyright 2020 Mike Dailly, All rights reserved.

The source to this player may be used freely for both commercial and non-commercial reasons, without charge but copyright is maintained and credit must be given to anyone who has contributed (see below) in any project where it is used. No warranty is given to this project and you use it at your own risk.

If you extend it, improve it, add new or missing features, please consider pushing back all changes for others to benefit from. Any accepted changes will be added to the contributors list.


Contributors
------------
Mike Dailly


Please be aware, if you are looking for a "Pure" Z80 Mod player, this version makes use of ZX Spectrum Next features, such as banking and extended Z80 instructions.

Note, the Axel F tune is here for demo purposes only and is not included in the "open source" licnese.
If anyone knows who created this, please get in touch with their details.



Usage:

	ld    a,BANK		; the core bank where the mod file lives
	ld    b,1			; 1 to initialise the samples (do this once only)
	call  ModInit		; load and init the mod
	call  ModPlay		; start the mod file playing


	; inside an IRQ or mainloop if running 50hz
	call	ModTick


	; These determain the playback speed. 
	; Please note, if changing these, you will need to rebuild the note conversion table (c# code)
	TVRate			equ	50						; framerate
	SamplesPerFrame	equ	128						; 104 samples per frame

	; The bank register and base address we're using (uses this one, and the next one)
	MOD_BANK		equ	$52						; which MMU bank to use (this one and the next)
	MOD_ADD			equ	$4000					; base address of this bank








Sound Effect Mixer
------------------
This little project allows you to have 4 independent samples or any size running at the same time, while only taking up a few bytes of main memory.
	
Press "S" to play sound effectcs in the demo.

Samples must be recorded/resampled to the same as the playback speed, and saved as 8bit signed.

To Init:
		call	MixerInit				; initialise the mod player - generate tables etc...


Inside IRQ:

		call	MixerProcess			; call the mixer


To init a sample - call only once:

		ld		a,SampleBank			; bank of sample
		ld		de,0					; bank offset
		ld		hl,SampleLength&$ffff	; sample length (low 2 bytes)
		ld		b,SampleLength>>16		; sample length high byte
		call	InitSample				; initialise the sample (pre-scale etc)



To play a sample:

		ld		a,channel				; 0 to 3
		ld		c,SampleBank			; the bank the 
		ld		hl,0					; sample offset into the bank
		ld		de,SampleLength&$ffff	; sample length (low 2 bytes)
		ld		b,SampleLength>>16		; sample length high byte
		call	MixerPlaySample

