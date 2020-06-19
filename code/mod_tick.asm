; ********************************************************************************************
; TickMod - process and actually play the current mod file.
; ********************************************************************************************
ModTick:
		ld		a,(ModFrame)
		add		a,Hi(ModSamplePlayback)
		ld		h,a
		ld		l,Lo(ModSamplePlayback)
		call	PlaySample

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
		
GetNote
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

		; work out how many bytes we skip in the sample each frame
		push	hl
		ld		l,(ix+note_sample_delta)
		ld		h,(ix+(note_sample_delta+1))
		ld		e,SamplesPerFrame
		ld		d,0
		push	bc
		call	Mul_16x16
		pop		bc
		ld		(ix+note_length_delta),d
		ld		(ix+(note_length_delta+1)),l
		pop		hl

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
		; which buffer do we mix into the final samples into?
		ld		a,(ModFrame)
		xor		1
		ld		(ModFrame),a
		add		a,Hi(ModSamplePlayback)
		ld		h,a
		ld		l,Lo(ModSamplePlayback)
		push	hl


		; Clear accumulation buffer
		ld		de,ModAccumulationBuffer
		ld		b,SamplesPerFrame
		xor		a
@Clear:
		ld		(de),a
		inc		de
		djnz	@Clear




		; Now loop over all samples and resample into accumulation buffer		
		ld		a,(ModNumChan)
		ld		(ChannelCounter),a
		ld		ix,ModChanData


CopyAllChannels:
		; get sample address, if 0... no sample playing
		ld		e,(ix+note_sample_cur)
		ld		d,(ix+(note_sample_cur+1))	
		ld		a,e
		or		d
		jp		z,NoSampleToCopy
		push	de

		; bank sample in
		ld		a,(ix+note_sample_curb)
		NextReg	MOD_BANK,a
		inc		a
		NextReg	MOD_BANK+1,a
	


		;------------------------------------------------------------------
		;	NON-Looping copy
		;------------------------------------------------------------------
		exx
WorkOutLength:
		; work out number of bytes to copy
		ld		l,(ix+note_sample_length)
		ld		h,(ix+(note_sample_length+1))
		ld		e,(ix+note_length_delta)
		ld		d,(ix+(note_length_delta+1))
		xor		a
		sbc		hl,de
		jr		nc,@fullcopy

		; work out how many bytes we DO need to process...
		ld		b,0
		ld		e,(ix+(note_sample_delta+1))			; whole bytes only
		ld		d,0
@LoopMore
		inc		b
		xor		a
		add		hl,de
		jr		nc,@LoopMore

		; due to just using the high byte, there might be some inaccuracies... do check after SUB
		ld		a,SamplesPerFrame
		sub		b
		jr		nc,@NotLooped
		ld		a,1									; check for overflow
@Notlooped:		
		ld		(SampleCopySize),a
		ld		b,a									; b = number of bytes to copy

		xor		a			
		ld		(ix+note_sample_length),a
		ld		(ix+(note_sample_length+1)),a
		jp		SampCopy
@fullcopy:
		ld		(ix+note_sample_length),l
		ld		(ix+(note_sample_length+1)),h
		ld		a,SamplesPerFrame
		ld		(SampleCopySize),a
		ld		b,a



SampCopy
		pop		de
		ld		hl,ModAccumulationBuffer
		exx
	
		; B is free
		ld		h,0								; high delta - always 0
		ld		l,(ix+(note_sample_delta+1))
		ex		de,hl
		ld		c,(ix+note_sample_delta)
		xor		a								; clear fraction accum
		ex		af,	af'
		exx		

CopySample1:
		; Resample sample into correct frequency AND output frequency.
		; DE.C = sample delta.  HL.A = sample address and fraction
		exx							; swap in source address and fractional deltas
		ld		a,(hl)				; read sample
		ex		af,	af'				; swap byte for delta fraction
		add		a,c					; sets carry for high op
		adc		hl,de				; add address to upper delta + carry
		ex		af,	af'				; get byte back - and save fraction
		exx							; get dest address
		
		; now accumulate sample into buffer
		add		a,128				; unsign sample
		srl		a
		srl		a
		add		a,(hl)	
		ld		(hl),a
		inc		l
		djnz	CopySample1			; Build up a frames worth


		exx
		ld		a,(SampleCopySize)
		cp		SamplesPerFrame
		jr		z,@NotSampleEnd
		ld		hl,0
@NotSampleEnd:
		ld		a,h
		cp		$80
		jr		c,@CarryOn
		break
@CarryOn
		ld		(ix+note_sample_cur),l
		ld		(ix+(note_sample_cur+1)),h
		exx

NextChannel:
NoSampleToCopy:
		ld		de,note_size
		add		ix,de
		ld		a,(ChannelCounter)
		dec		a
		ld		(ChannelCounter),a
		jp		nz,CopyAllChannels


;------------------------------------------------------------------
;   Scale sample buffer down for "raw" buffer playback
;------------------------------------------------------------------
SkipSampleEnd:
		ld		b,SamplesPerFrame
		pop		de
		push	de
		ld		hl,ModAccumulationBuffer

		;ld		a,(TuneBank)
		;NextReg	MOD_BANK,a
		;inc		a
		;NextReg	MOD_BANK+1,a
		;ld		de,(TuneAddress)
		

ScaleSample:
		ld		a,(hl)
		inc		l
		ld		(de),a
		inc		de

		djnz	ScaleSample
		
		; $1f
		ld		a,d
		sub		Hi(MOD_ADD)
		swapnib
		and		$f
		srl		a
		ld		b,a
		ld		a,(TuneBank)
		add		a,b
		ld		(TuneBank),a
		
		ld		a,d
		and		$1f
		add		a,Hi(MOD_ADD)
		ld		d,a
		ld		(TuneAddress),de
		



		pop		hl

		; which buffer do we mix into the final samples into?
		;ld		a,(ModFrame)
		;xor		1
		;add		a,Hi(ModSamplePlayback)
		;ld		h,a
		;ld		l,Lo(ModSamplePlayback)
		;call	PlaySample
		ret

SampleCopySize	db	0
ChannelCounter	db	0
				ds	40
TuneBank		db	ModSampleBank
TuneAddress		dw	MOD_ADD




