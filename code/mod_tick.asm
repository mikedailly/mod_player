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
		dec		a							; -1 (values from 1 to 128)
		ld		(ix+note_sample),a
		ld		a,c
		and		$f
		ld		(ix+(note_effect+1)),a		; effect high
		
		inc		hl
		ld		a,(hl)
		ld		(ix+note_effect),a			; effect high
		inc		hl							; next note
		

		; get sample delta - via table  (PAL/(period*2))/(78*50)
		ld		e,(ix+note_period)
		ld		d,(ix+(note_period+1))
		ex		de,hl
		add		hl,hl
		add		hl,NoteLookup
		ld		a,(hl)
		ld		(ix+note_sample_delta),a
		inc		hl
		ld		a,(hl)
		ld		(ix+(note_sample_delta+1)),a
		ex		de,hl
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
		add		de,MOD_ADD

		ld		(ix+note_sample_off),e
		ld		(ix+note_sample_cur),e
		ld		(ix+(note_sample_off+1)),d
		ld		(ix+(note_sample_cur+1)),d
		ld		a,(iy+sample_bank)
		ld		(ix+sample_bank),a
		ld		(ix+note_sample_curb),a 

		ld		a,(iy+sample_len)
		ld		(ix+note_sample_length),a
		ld		a,(iy+(sample_len+1))
		ld		(ix+(note_sample_length+1)),a

NextNote:
		ld		de,note_size
		add		ix,de
		dec		b
		jp		nz,ReadAllChannelNotes
		ld		(ModPatternAddress),hl
		
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





;------------------------------------------------------------------
; Process all samples
;------------------------------------------------------------------
DoSamples:
		; which buffer do we sample into?
		ld		a,(ModFrame)
		xor		1
		ld		(ModFrame),a
		jr		nz,@SetupBuffer2
		ld		hl,ModSamplePlayback
		jr		@Skip
@SetupBuffer2:
		ld		hl,ModSamplePlayback+256			   ; SamplesPerFrame
@Skip:
		; HL = buffer address
		push	hl

		;
		ld		de,ModAccumulationBuffer
		ld		b,SamplesPerFrame*2
		xor		a
@Clear:
		ld		(de),a
		inc		e
		djnz	@Clear







		
		ld		a,(ModNumChan)
		ld		c,a
		ld		ix,ModChanData

CopyAllChannels:
		; get sample address, if 0... no sample playing
		ld		e,(ix+note_sample_cur)
		ld		d,(ix+(note_sample_cur+1))	
		ld		a,e
		or		d
		jp		z,NoSampleToCopy

		; bank sample in
		ld		a,(ix+note_sample_curb)
		NextReg	MOD_BANK,a
		inc		a
		NextReg	MOD_BANK+1,a
	


		;------------------------------------------------------------------
		;	NON-Looping copy
		;------------------------------------------------------------------
		exx
		ld		b,SamplesPerFrame
		ld		hl,ModAccumulationBuffer
		ld		e,(ix+note_sample_length)
		ld		d,(ix+(note_sample_length+1))
SampCopy
		exx
		ld		h,e
		ld		l,0
		ld		c,(ix+note_sample_delta)
		ld		b,(ix+(note_sample_delta+1))
		push	bc
		NEG_BC
		ld		a,b
		ld		(LengthDelta+2),a
		pop	bc

		exx		
CopySample1:
		exx		
		ld		a,(de)	
		ex		af,	af'
		xor		a					; high part of sample delta
		add		hl,bc
		ld		e,h
		adc		a,d
		ld		d,a
		ex		af,	af'
		exx		
		
		; now accumulate sample into buffer
		add		a,128					; unsign sample
		add		a,(hl)	
		ld		(hl),a
		inc		hl
		ld		a,0
		adc		a,(hl)
		ld		(hl),a
		inc		hl

		; dec sample length... stop copy on 0
		;dec		de
LengthDelta:
		add		de,$ffff
		ld		a,d
		or		e
		jr		z,EndOfSampleCopy		
		djnz	CopySample1					; copy all of a frame


		ld		(ix+note_sample_length),e
		ld		(ix+(note_sample_length+1)),d
		exx
		ld		(ix+note_sample_cur),e
		ld		(ix+(note_sample_cur+1)),d
		exx

NextChannel:
		ld		de,note_size
		add		ix,de
		dec		c
		jp		nz,CopyAllChannels
		jp		SkipSampleEnd
EndOfSampleCopy:	
		xor		a
		ld		(ix+note_sample_cur),a
		ld		(ix+(note_sample_cur+1)),a
		jp		NextChannel





;------------------------------------------------------------------
;   Scale sample buffer down for "raw" buffer playback
;------------------------------------------------------------------
SkipSampleEnd:
NoSampleToCopy:
		ld		b,SamplesPerFrame
		pop		de
		push	de
		ld		hl,ModAccumulationBuffer

ScaleSample:
		ld		a,(hl)
		inc		l
		ld		c,(hl)
		inc		l
		srl		c			; / 4
		rra
		srl		c
		rra
		ld		(de),a
		inc		e
		djnz	ScaleSample
		
		pop		hl
		ld		a,l
		xor		256
		ld		l,a
		call	PlaySample
		ret



