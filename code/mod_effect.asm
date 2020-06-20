; *********************************************************************************************
; 
;	Handle all "effect" setup - or deal with them directly
;
;	D = effect[e]
;   E = param[x][y] (2 nibbles)
; *********************************************************************************************
DoEffects:
		push	hl
		ld		a,d
		add		a,a
		ld		hl,EffectJump
		add		hl,a
		ld		a,(hl)
		ld		(JumpPrt+1),a
		inc		hl
		ld		a,(hl)
		ld		(JumpPrt+2),a
JumpPrt:
		jp		$0000


NoEffect:
		pop		hl
		ret

EffectJump:
		dw	NoEffect				; 00 Arpeggio
		dw	NoEffect				; 01 Slide up
		dw	NoEffect				; 02 Slide down
		dw	NoEffect				; 03 Slide to note
		dw	NoEffect				; 04 Vibrato
		dw	NoEffect				; 05 Continue Slide to note
		dw	NoEffect				; 06 Contiune Vibrato
		dw	NoEffect				; 07 Tremolo			
		dw	NoEffect				; 08 Set panning position (unused by most trackers - we don't use it either)
		dw	NoEffect				; 09 Set sample offset
		dw	NoEffect				; 10 Volume Slide
		dw	NoEffect				; 11 Position Jump
		dw	NoEffect				; 12 Set volume
		dw	NoEffect				; 13 Pattern break
		dw	NoEffect				; 14 multi-effect
		dw	SetModSpeed				; 15 Set Speed

Effect14Jump:
		dw	0



;------------------------------------------------------------------------------------------
; Set the mod playback speed
;------------------------------------------------------------------------------------------
SetModSpeed:
		ld		a,e
		and		$1f	
		ld		(ModDelayCurrent),a
		ld		(ModDelayMax),a
		jp		NoEffect


