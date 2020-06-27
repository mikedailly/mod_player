;------------------------------------------------------------------
; This loop is used if the sample doesn't repeat, as it's quite a bit quicker than
; doing a looping sample
;------------------------------------------------------------------
NonRepeatingSampleCopy:


WorkOutLength1:
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
		; So work out how many bytes we DO need to process... 
		; (add delta back onto negative length value until >=0 and count)
		ld		b,0
		ld		e,(ix+(note_sample_delta+1))			
		ld		c,(ix+(note_sample_delta))
		ld		d,b
@LoopMore
		inc		b
		add		a,c
		adc		hl,de
		jr		nc,@LoopMore

		; Now we know how many samples we went beyond the end, subtract that off....
		ld		a,(ModSamplesToFill)
		sub		b	
		and		a
		jr		z,EndOfSample
		ld		(ModSampleCopySize),a		
		ld		b,a									; b = number of bytes to copy
		jp		SampCopy
@fullcopy:
		ld		(ix+note_sample_lengthF),a
		ld		(ix+note_sample_length),l
		ld		(ix+(note_sample_length+1)),h
		ld		a,SamplesPerFrame
		ld		(ModSampleCopySize),a
		ld		b,a



SampCopy
		ld		a,(ix+note_volume)
		cp		$3f
		jr		c,@Skip
		ld		a,$3f
@Skip:
		add		a,MOD_VOL_ADD
		ld		d,a								; d = volume table to use		

		ld		hl,(ModDestbuffer)				; get the mix buffer address for this frame
		exx

		; B is free
		xor		a								; clear fractional accumulator
		ld		h,a								; high delta - always 0
		ld		l,(ix+(note_sample_delta+1))
		ex		de,hl
		ld		c,(ix+note_sample_delta)
		ex		af,	af'
		exx		


		; -----------------------------------------------------------------------------------------------
		; This loop is used for all other channels, and mixes into the buffer
		; -----------------------------------------------------------------------------------------------
CopyLoop:
		; Resample sample into correct frequency AND output frequency.
		; DE.C = sample delta.  HL.A = sample address and fraction
		exx							; swap in source address and fractional deltas
		ld		a,(hl)				; read sample
		ex		af,af'				; swap byte for delta fraction
		add		a,c					; sets carry for high op
		adc		hl,de				; add address to upper delta + carry
		ex		af,af'				; get byte back - and save fraction
		exx							; get dest address back		
		; now accumulate sample into buffer
		ld		e,a					; get index into volume table
		ld		a,(de)				; get converted volume
		add		a,(hl)				; mix into buffer
		ld		(hl),a				; store moxed sample back into buffer
		inc		l					; sample "mix" buffer is 256 byte aligned, so will never overflow
		djnz	CopyLoop			; Build up a frames worth
		; -----------------------------------------------------------------------------------------------
		; End copy loop
		; -----------------------------------------------------------------------------------------------


		exx
		ld		a,(ModSampleCopySize)		; is the copy size the same as samples per frame?
		cp		SamplesPerFrame				; if not, we didn't copy a whole frame, so sample has ended
		ret		z							; 
EndOfSample:
		ld		hl,0						; End of sample....
		ret
