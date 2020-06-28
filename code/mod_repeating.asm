RepeatingSampleCopy:

		;------------------------------------------------------------------
		;	NON-Looping copy
		;------------------------------------------------------------------
WorkOutLength2:
		ld		a,SamplesPerFrame
		ld		(ModSampleCopySize),a
		exx
		ld		b,a
		exx


		ld		a,(ix+note_sample_end)
		ld		(EndAddLow+1),a
		ld		a,(ix+(note_sample_end+1))
		add		a,Hi(MOD_ADD)
		ld		(EndAddHi+1),a
		;ld		a,(ix+sample_rep_bank)		
		;ld		(ix+sample_end_bank),h


SampCopy2
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
CopyLoop2:
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
EndAddLow:
		ld		a,$78				; 7	End of sample LO (self-modified code)
		sub		l					; 4 subtract current location
EndAddHi:
		ld		a,$57				; 7	End of sample HI (self-modified code)
		sbc		a,h					; 4
		jp		nc,@NoRepeat		; 10 = 32		 normally takes branch, so don't use JR, JP is quicker
		
		; Now handle the repeat
		push	de
		ld		a,(EndAddLow+1)
		ld		e,a
		ld		a,(EndAddHi+1)
		ld		d,a
		inc		de					; offset by 1 to get proper value
		xor		a
		sbc		hl,de				; subtract the end address from the current sample addredss
		ex		de,hl				; to get number of bytes PAST the end of the sample.

		ld		l,(ix+note_sample_rep)			; get repeat point
		ld		a,(ix+(note_sample_rep+1))
		add		a,Hi(MOD_ADD)
		ld		h,a
		add		hl,de							; HL now = the repeat point
		ld		a,(ix+note_sample_repb)
		ld		(ix+note_sample_curb),a
		NextReg	MOD_BANK,a					; bank over the ROM area
		inc		a
		NextReg	MOD_BANK+1,a


		pop		de
@NoRepeat:
		; now accumulate sample into buffer
		djnz	CopyLoop2
		; -----------------------------------------------------------------------------------------------
		; End copy loop
		; -----------------------------------------------------------------------------------------------


;		exx
		ld		a,(ModSampleCopySize)		; is the copy size the same as samples per frame?
		cp		SamplesPerFrame				; if not, we didn't copy a whole frame, so sample has ended
		ret		z
		ld		hl,0						; check for repeating samples here.....
		ret

