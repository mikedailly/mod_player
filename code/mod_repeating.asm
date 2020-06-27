NonRepeatingSampleCopy:

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
		ld		a,(ModSamplesToFill)
		sub		b	
		ld		(ModSampleCopySize),a
		exx
		ld		b,a									; b = number of bytes to copy
		exx

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
		exx
		ld		b,a
		exx


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
;		exx		


		; -----------------------------------------------------------------------------------------------
		; This loop is used for all other channels, and mixes into the buffer
		; -----------------------------------------------------------------------------------------------
CopyLoop:
		; get byte from sample
		ld		a,(hl)				; read sample byte
		exx							; swap to output buffer
		ld		e,a					; get index into volume table
		ld		a,(de)				; get converted volume
		add		a,(hl)				; mix into buffer
		ld		(hl),a				; store mixed sample value into buffer
		inc		l					; pages are always 256 byte aligned - so will never cross a page
		exx							; swap back to sample 
		
		; Resample sample into correct frequency AND output frequency.
		; DE.C = sample delta.  HL.A = sample address and fraction
		ex		af,	af'				; get delta fraction back
		add		a,c					; sets carry for high op
		adc		hl,de				; add address to upper delta + carry
		ex		af,	af'				; and save fraction

		; check for end of sample or sample loops - once address goes past sample END address 
		ld		a,$78				; 7	End of sample LO (or end of repeat section LO)
		sub		l					; 4 subtract current location
		ld		a,$57				; 7	End of sample HI (or end of repeat section HI)
		sbc		a,h					; 4
		jp		nc,@NoRepeat		; 10 = 32		 normally takes branch, so don't use JR, JP is quicker
		nop
		nop
		nop
		nop

@NoRepeat:
		; now accumulate sample into buffer
		djnz	CopyLoop
		; -----------------------------------------------------------------------------------------------
		; End copy loop
		; -----------------------------------------------------------------------------------------------


;		exx
		ld		a,(ModSampleCopySize)		; is the copy size the same as samples per frame?
		cp		SamplesPerFrame				; if not, we didn't copy a whole frame, so sample has ended
		ret		z
		ld		hl,0						; check for repeating samples here.....
		ret

