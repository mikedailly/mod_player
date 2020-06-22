; ********************************************************************************************
; TickMod - process and actually play the current mod file.
; ********************************************************************************************
ModTick:
		ld		a,(ModFrame)
		add		a,Hi(ModSamplePlayback)
		ld		h,a
		ld		l,Lo(ModSamplePlayback)
		call	ModPlaySample

		call	SaveMMUs

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


		ld		ix,ModChanData
		ld		a,(ModNumChan)
		ld		b,a

ReadAllChannelNotes:
		push	bc

		; first clear channel effect stuff
		xor		a
		ld		(ix+note_pitch_bend),a		; clear pitch bending
		ld		(ix+(note_pitch_bend+1)),a
		;ld		a,$40
		;ld		(ix+note_volume),a


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

		ld		a,(hl)						; get note high + sample
		ld		c,a							; keep original
		and		$f
		ld		e,a							; note high
		inc		hl

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
		ld		d,a
		
		inc		hl
		ld		a,(hl)
		ld		(ix+note_effect),a			; effect high
		inc		hl							; next note	
		ld		e,a
		or		d
		jr		z,GetNote

		call	DoEffects

GetNote
		; if note is 0, then leave current note in place
		ld		e,(ix+note_period)
		ld		d,(ix+(note_period+1))
		ld		a,e
		or		d
		jp		z,NextNote

		xor		a
		call	SetupNote


NextNote:


DoEffectProcessing
			; first check pitch bending
			ld		e,(ix+note_pitch_bend)		
			ld		d,(ix+(note_pitch_bend+1))	
			ld		a,e
			or		d
			jp		z,NoPitchBending

		
			ld		l,(ix+note_period)		
			ld		h,(ix+(note_period+1))	
			xor		a
			sbc		hl,de
			ld		(ix+note_period),l
			ld		(ix+(note_period+1)),h
			ex		de,hl
			ld		a,1
			call	SetupNote
NoPitchBending:

		ld		de,note_size
		add		ix,de
		pop		bc
		dec		b
		jp		nz,ReadAllChannelNotes
		ld		(ModPatternAddress),hl
		



		; --------------------------------------------------------------------------------------------------------------------
		; Next note in the sequence....  or move to next sequence
		; --------------------------------------------------------------------------------------------------------------------
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
		ld		(ModDestbuffer),hl

		
		; Clear destination buffer, we need to do this because if samples are ending it'll leave data in the buffer
		ld		de,(ModDestbuffer)
		ld		b,SamplesPerFrame
		ld		a,128
@Clear	ld		(de),a
		inc		e
		djnz	@Clear





		; Now loop over all samples and resample into accumulation buffer		
		ld		a,(ModNumChan)
		ld		(ModChannelCounter),a
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
		exx							; DE now hold sample address (in alt set)
	


		;------------------------------------------------------------------
		;	NON-Looping copy
		;------------------------------------------------------------------
WorkOutLength:
		; work out number of bytes to copy
		ld		a,(ix+note_sample_lengthF)				; current sample position (16.8)
		ld		l,(ix+note_sample_length)
		ld		h,(ix+(note_sample_length+1))

		ld		c,(ix+note_length_deltaF)				; frame length delta  (16.8)
		ld		e,(ix+note_length_delta)
		ld		d,(ix+(note_length_delta+1))
		sub		c
		sbc		hl,de
		jr		nc,@fullcopy

		; if we get here we don't have enough bytes to fill a frame.
		; So work out how many bytes we DO need to process... (add delta back onto negative length value until >0)
		ld		b,0
		ld		e,(ix+(note_sample_delta+1))			
		ld		c,(ix+(note_sample_delta))
		ld		d,0
@LoopMore
		inc		b
		add		a,c
		adc		hl,de
		jr		nc,@LoopMore

		; Now we know how many samples we went beyond the end, subtract that off....
		ld		a,SamplesPerFrame
		sub		b	
		ld		(ModSampleCopySize),a
		ld		b,a									; b = number of bytes to copy

		xor		a			
		ld		(ix+note_sample_lengthF),a
		ld		(ix+note_sample_length),a
		ld		(ix+(note_sample_length+1)),a
		jp		SampCopy
@fullcopy:
		ld		(ix+note_sample_lengthF),a
		ld		(ix+note_sample_length),l
		ld		(ix+(note_sample_length+1)),h
		ld		a,SamplesPerFrame
		ld		(ModSampleCopySize),a
		ld		b,a



SampCopy
		ld		a,ModVolumeBank
		NextReg	MOD_VOL_BANK,a					; bank over the ROM area
		inc		a
		NextReg	MOD_VOL_BANK+1,a
		ld		a,(ix+note_volume)
		cp		$3f
		jr		c,@Skip
		ld		a,$3f
@Skip:
		add		a,MOD_VOL_ADD
		ld		d,a								; d = volume table to use		




		;ld		hl,ModAccumulationBuffer
		ld		hl,(ModDestbuffer)
		exx

		; B is free
		ld		h,0								; high delta - always 0
		ld		l,(ix+(note_sample_delta+1))
		ex		de,hl
		ld		c,(ix+note_sample_delta)
		xor		a								; clear fractional accumulator
		ex		af,	af'
		exx		



		; This loop is used for all other channels, and mixes into the buffer
CopyLoop:
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
		ld		e,a					; get index into volume table
		ld		a,(de)				; get converted volume
		add		a,(hl)				; mix into buffer
		ld		(hl),a
		inc		l
		djnz	CopyLoop			; Build up a frames worth




		exx
		ld		a,(ModSampleCopySize)		; is the copy size the same as samples per frame?
		cp		SamplesPerFrame				; if not, we didn't copy a whole frame, so sample has ended
		jr		z,@NotSampleEnd
		ld		hl,0						; check for repeating samples here.....
		jp		@NoBankSwap
@NotSampleEnd:
		; check to see if we've crossed a bank
		ld		a,h
		sub		Hi(MOD_ADD)
		and		$e0
		jr		z,@NoBankSwap

		ld		a,h							; reset bank offset
		and		$1f
		add		a,Hi(MOD_ADD)
		ld		h,a
		ld		a,(ix+note_sample_curb)		; inc bank
		inc		a
		ld		(ix+note_sample_curb),a

@NoBankSwap:
		ld		(ix+note_sample_cur),l
		ld		(ix+(note_sample_cur+1)),h
		exx

NextChannel:
NoSampleToCopy:
		ld		de,note_size
		add		ix,de
		ld		a,(ModChannelCounter)
		dec		a
		ld		(ModChannelCounter),a
		jp		nz,CopyAllChannels


;------------------------------------------------------------------
;   Scale sample buffer down for "raw" buffer playback
;------------------------------------------------------------------
SkipSampleEnd:
		jp		RestoreMMUs



		
		; DEBUG - record sample into memory
		ld		b,SamplesPerFrame
		ld		hl,(ModDestbuffer)
		ld		a,(TuneBank)
		NextReg	MOD_BANK,a			; lets me record the sample to memory for saving out via debugger
		inc		a
		NextReg	MOD_BANK+1,a
		ld		de,(TuneAddress)
		

ScaleSample:
		ld		a,(hl)
		inc		l
		ld		(de),a
		inc		de
		djnz	ScaleSample

		
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

		jp		RestoreMMUs



; ***********************************************************************************************
; Sets up a channel using the current note/period
; In:	DE = note
;		A  = 0 to setup sample, 1 to leave current sample position (pitch bending etc)
;		IX = note struct pointer
; ***********************************************************************************************
SetupNote:
		ex		af,af'					

		; get sample delta - via table  (PAL/(period*2))/(78*50)
		ex		de,hl
		add		hl,hl
		add		hl,NoteLookup
		ld		a,(hl)
		ld		(ix+note_sample_delta),a
		inc		hl
		ld		a,(hl)
		ld		(ix+(note_sample_delta+1)),a
		ex		de,hl

		; Do we want to skip the sample setup? 
		ex		af,af'
		and		a
		jr		nz,@SkipSampleSetup
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

		xor		a
		ld		(ix+note_sample_lengthF),a
		ld		e,(iy+sample_len)
		ld		d,(iy+(sample_len+1))
		ld		(ix+note_sample_length),e
		ld		(ix+(note_sample_length+1)),d
	
		ld		a,(iy+sample_vol)
		ld		(ix+note_volume_sample),a
		call	UpdateChennelVolume

		
@SkipSampleSetup
		; work out how many bytes we skip in the sample each frame
		push	hl
		ld		e,(ix+note_sample_delta)
		ld		d,(ix+(note_sample_delta+1))
		ld		l,SamplesPerFrame
		push	bc
		call	Mul_16x8			;Mul_16x16
		pop		bc
		ld		(ix+note_length_deltaF),l
		ld		(ix+note_length_delta),h
		ld		(ix+(note_length_delta+1)),a
		pop		hl
		ret


; ***********************************************************************************************
; Workout ChannelVolume*SampleVolume*GlobalVolume
; ***********************************************************************************************
UpdateChennelVolume:
		; combine sample volvume with channel volume
		ld		e,(ix+note_volume_sample)
		ld		d,(ix+note_volume_channel)
		mul
		ld		b,6
		BSRA	DE,B						; DE>>6

		; now mul in global volume
		ld		a,(ModGlobalVolume)
		ld		d,a
		mul
		BSRA	DE,B						; DE>>6

		ld		(ix+note_volume),e			; set final volume ($00-$40)
		ret



