; *********************************************************************************************
; 
;	Handle all "effect" setup - or deal with them directly
;
;	D = effect[e]
;   E = param[x][y] (2 nibbles)
;
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
		dw	PitchBendUp				; 01 Pitch bend slide note up (actually a subtract)
		dw	PitchBendDOwn			; 02 Pitch bend slide note down (actually an add)
		dw	NoEffect				; 03 Pitch bend slide to specific note
		dw	NoEffect				; 04 Vibrato
		dw	NoEffect				; 05 Continue Slide to note
		dw	NoEffect				; 06 Contiune Vibrato
		dw	NoEffect				; 07 Tremolo			
		dw	NoEffect				; 08 Set panning position (unused by most trackers - we don't use it either)
		dw	NoEffect				; 09 Set sample offset
		dw	NoEffect				; 10 Volume Slide
		dw	NoEffect				; 11 Position Jump
		dw	SetVolume				; 12 Set volume
		dw	NoEffect				; 13 Pattern break
		dw	NoEffect				; 14 multi-effect
		dw	SetModSpeed				; 15 Set Speed

Effect14Jump:
		dw	0


;------------------------------------------------------------------------------------------
; Setup a positive Pitch bend delta (up)
;------------------------------------------------------------------------------------------
PitchBendUp:
		ld		(ix+note_pitch_bend),e
		xor		a
		ld		(ix+(note_pitch_bend+1)),e
		jp		NoEffect

;------------------------------------------------------------------------------------------
; Setup a negative Pitch bend delta  (down)
;------------------------------------------------------------------------------------------
PitchBendDown:
		ld		d,0
		NEG_DE
		ld		(ix+note_pitch_bend),e
		xor		a
		ld		(ix+(note_pitch_bend+1)),e
		jp		NoEffect


;------------------------------------------------------------------------------------------
; Set channel volume - we can only handle 0-63
;------------------------------------------------------------------------------------------
SetVolume:
		ld		a,e
		cp		$40
		jr		c,@InRange
		ld		a,$40
@InRange:
		ld		(ix+note_volume_channel),a
		call	UpdateChennelVolume
		jp		NoEffect


;------------------------------------------------------------------------------------------
; Set the mod playback speed
;------------------------------------------------------------------------------------------
SetModSpeed:
		ld		a,e
		cp		$1f
		jr		c,@Nomral
		jp		NoEffect

@Nomral:
		ld		(ModDelayCurrent),a
		ld		(ModDelayMax),a
		jp		NoEffect


