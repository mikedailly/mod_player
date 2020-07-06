; Mod player
; By Mike Dailly, (c) Copyright 2020 all rights reserved.

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
		dw	PatternBreak			; 13 Pattern break
		dw	NoEffect				; 14 multi-effect
		dw	SetModSpeed				; 15 Set Speed

Effect14Jump:
		dw	0


;------------------------------------------------------------------------------------------
; $01 - Setup a positive Pitch bend delta (up)
;------------------------------------------------------------------------------------------
PitchBendUp:
		ld		(ix+note_pitch_bend),e
		xor		a
		ld		(ix+(note_pitch_bend+1)),a
		jp		NoEffect

;------------------------------------------------------------------------------------------
; $02 - Setup a negative Pitch bend delta  (down)
;------------------------------------------------------------------------------------------
PitchBendDown:
		ld		d,0
		NEG_DE
		ld		(ix+note_pitch_bend),e
		xor		a
		ld		(ix+(note_pitch_bend+1)),e
		jp		NoEffect


;------------------------------------------------------------------------------------------
; $0c - Set channel volume - we can only handle 0-63
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
; $0d - Break to Next Pattern 
;  Where [13][x][y] means "stop the pattern after this division, and
; continue the song at the next pattern at division x*10+y" 
; (the 10 is not a typo). Legal divisions are from 0 to 63.
;------------------------------------------------------------------------------------------
PatternBreak:
		ld 		a,$3f
		ld		(ModSequenceIndex),a

		; setup sequence JUMP....
		ld		a,e
		swapnib
		and		$f
		ld		d,a
		ld		a,e
		and		$f
		ld		e,10
		mul
		add		de,a
		; de hold the sequence number (0-63)
		ld		a,(ModNumChan)				; seqNum*chan (1-8)
		ld		d,a
		mul
		ex		de,hl
		add		hl,hl						; *2
		add		hl,hl						; *4 (4 bytes per note)
		ex		de,hl

		ld		a,e
		ld		(ModSequanceOffset),a		; reset offset
		ld		a,d
		ld		(ModSequanceOffset+1),a		; reset offset

		jp		NoEffect



;------------------------------------------------------------------------------------------
; $0f - Set the mod playback speed
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


