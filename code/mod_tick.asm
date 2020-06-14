; ********************************************************************************************
; TickMod - process and actually play the current mod file.
; ********************************************************************************************
ModTick:
		ld		a,(ModDelayCurrent)
		dec		a
		ld		(ModDelayCurrent),a
		and		a
		jp		nz,DoSamples

		; delay has run out, so setup next note
		ld		a,(ModDelayMax)
		ld		(ModDelayCurrent),a
		
		; check for end of song here.....



		; Now get and setup the next note in the sequence
		ld		hl,(ModPatternAddress)
		ld		a,(ModPatternBank)
		NextReg	MOD_BANK,a
		inc		a
		NextReg	MOD_BANK+1,a


;note_sample		rb	1		; the sample being played
;note_period		rw	1		; 12 bit sample period (or effect paramater)
;note_effect		rw	1		; 12 bit effect value
;note_sample_off		rw	1		; base address of sample
;note_sample_bank	rw	1		; base bank of sample
;note_sample_rep		rw	1		; base address of repeat for sample
;note_sample_bank	rw	1		; base bank of sample


		ld		ix,ModChanData
		ld		a,(ModNumChan)
		ld		b,a

ReadAllChannelNotes:
		;
		; read the 4 byte note
		;
		; 7654-3210 7654-3210 7654-3210 7654-3210
		; wwww xxxxxxxxxxxxxx yyyy zzzzzzzzzzzzzz
		;
		;     wwwwyyyy (8 bits) is the sample for this channel/division
		; xxxxxxxxxxxx (12 bits) is the sample's period (or effect parameter)
		; zzzzzzzzzzzz (12 bits) is the effect for this channel/division
		;

		; if note is 0, then leave current note in place
		ld		a,(hl)						; get note high + sample
		ld		c,a							; keep original
		and		$f
		ld		e,a							; note high

		inc		hl
		or		(hl)						; note low
		jr		nz,@NewNote
		ld		a,3
		add		hl,a
		jp		NextNote
		

@NewNote:
		; HL points to period high
		ld		a,c							; get sample/note back
		and		$f0							; mask off sample high nibble
		ld		e,a							; remember in "E" for later merging
		ld		a,c
		and		$0f
		ld		(ix+(note_period+1)),a		; period high

		ld		a,(hl)
		ld		(ix+note_period),a			; period lo
	
		inc		hl
		ld		a,(hl)						; get sample low and effect high
		ld		c,a
		swapnib
		and		$f
		or		e							; merge with sample high
		ld		(ix+note_sample),a
		ld		a,c
		and		$f
		ld		(ix+(note_effect+1)),a		; effect high
		
		inc		hl
		ld		a,(hl)
		ld		(ix+note_effect),a			; effect high
		inc		hl							; next note
		
		;
		; Now we've read the note, find the base address and bank of the sample
		;
		ld		e,(ix+note_sample)
		ld		d,sample_info_len
		mul
		add		de,ModSamples
		push	de
		pop		iy

		; copy sample base offset
		ld		e,(iy+sample_offset)
		ld		d,(iy+(sample_offset+1))
		ld		(ix+note_sample_off),e
		ld		(ix+note_sample_cur),e
		ld		(ix+(note_sample_off+1)),d
		ld		(ix+(note_sample_cur+1)),d
		ld		a,(iy+sample_bank)
		ld		(ix+sample_bank),a
		ld		(ix+note_sample_curb),a

NextNote:
		ld		de,note_size
		add		ix,de
		djnz	ReadAllChannelNotes
		
		; Next note in the sequence....
		ld		a,(ModSequenceIndex)
		inc		a
		ld		(ModSequenceIndex),a
		cp		64
		jr		nz,DoSamples

		; end of sequence.... move to next pattern
		ld		a,(ModPatternIndex)
		inc		a
		ld		(ModPatternIndex),a
		ld		de,ModPattern
		add		de,a
		ld		a,(de)
		call	SetUpSequence

DoSamples:
		; which buffer do we sample into?
		ld		a,(ModFrame)
		xor		1
		ld		(ModFrame),a
		jr		nz,@SetupBuffer2
		ld		h,a					; a=0
		ld		l,a
		jr		@Skip
@SetupBuffer2:
		ld		hl,SamplesPerFrame
@Skip:
		; HL = buffer address


		ret



