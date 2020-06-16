;
; Mod_player
;

; ********************************************************************************************
;	A  = root bank of MOD file (tune always starts at 0)
; ********************************************************************************************
ModInit:
	ld		(ModBaseBank),a
	NextReg	MOD_BANK,a				; bank in mod file

	; pre-process the 31 samples.
	ld		ix,MOD_ID						; get number of instruments
	call	ModGetInstrumentsChannels		; detect the number of instruments	


	ld		b,a
	ld		ix,MOD_SAMPLES			; base of sample table
	ld		iy,ModSamples			; sample structs
@SetUpAllSamples:
	; swap sample length from amiga format
	ld		a,(ix+file_sample_len)		
	ld		(iy+(sample_len+1)),a
	ld		a,(ix+(file_sample_len+1))
	ld		(iy+sample_len),a
	
	; fine tune
	ld		a,(ix+file_sample_fine)
	ld		(iy+sample_fine),a

	; volume adjust
	ld		a,(ix+file_sample_vol)
	ld		(iy+sample_vol),a

	; swap sample repeat point from amiga format
	ld		a,(ix+file_sample_rep)		
	ld		(iy+(sample_rep+1)),a
	ld		a,(ix+(file_sample_rep+1))
	ld		(iy+sample_rep),a

	; swap sample repeat length  from amiga format
	ld		a,(ix+file_sample_rep_len)		
	ld		(iy+(sample_rep_len+1)),a
	ld		a,(ix+(file_sample_rep_len+1))
	ld		(iy+sample_rep_len),a

	ld		de,file_sample_info_len			; move to next sample
	add		ix,de
	ld		de,sample_info_len			; move to next sample
	add		iy,de
	djnz	@SetUpAllSamples




	; ix points to song info... so put into hl
	push	ix
	pop		hl
	ld		a,(ix+0)				; song length
	ld		(ModSongLength),a		; 1 to 128
	ld		a,(ix+1)				; song restart point
	ld		(ModSongRestart),a		; 1 to 128
	inc		hl
	inc		hl
	;ld		(ModSequanceOrder),hl			; get the base of the sequence order
	;ld		(ModSequanceOrder_current),hl	; and store current position
	
	; detect largest pattern number
	xor		a
	ld		b,128
	ld		ix,ModPattern
@CheckAll:
	ld		d,(hl)
	ld		(ix+0),d				; save in local storage
	cp		d
	jr		nc,@Skip
	ld		a,d
@Skip:
	inc		hl
	inc		ix
	djnz	@CheckAll
	ld		(ModHighestPattern),a	; remember the highest  pattern
	
	; if there is a file ID, skip it....
	ld		b,a						; remember for later
	ld		a,(ModNumInst)
	cp		15
	jr		z,@NoID
	add		hl,4					; skip ID
@NoID:

	; HL now pointing to pattern data
	ld		(ModChannelData),hl
	inc		b						; now loop over all the patterns and work out addresses/banks
	
	; work out size of channel
	ld		a,(ModNumChan)
	ld		e,a
	ld		d,4						; 4*1,2,3,4,5,6,7 or 8 
	mul
	ld		d,64					; then *64 for all the notes in this sequence
	mul
	ld		(ModSequenceSize),de



	; work out start bank+offset of each sequence start address	
	ld		ix,ModSequenceData
	ld		a,(ModBaseBank)
	ld		c,a						; c = bank, hl = offset

	; turn H into an offset, and C holds the bank
@AllChannels:
	ld		a,h
	and		$1f
	ld		h,a
	ld		(ix+0),l
	ld		(ix+1),h
	ld		(ix+2),c

	add		hl,de
	bit		5,h
	jr		z,@SkipBankSwap
	inc		c
@SkipBankSwap:
	inc		ix
	inc		ix
	inc		ix
	djnz	@AllChannels
	
;ModSamAdd:
	; HL now points to SAMPLE data (offset), while C is the bank
	ld		ix,ModSamples
	ld		a,(ModNumInst)
	ld		b,a

@AllChannels2:
	ld		a,h
	and		$1f
	ld		h,a
	ld		(ix+sample_offset),l
	ld		(ix+(sample_offset+1)),h
	ld		a,c
	ld		(ix+sample_bank),c

	ld		e,(ix+sample_len)				; get sample length
	ld		d,(ix+(sample_len+1))
	add		hl,de

	ld		a,h
	swapnib							; swap from $1f to $f1
	and		$e						; now mask to keep $0e
	rrca							; /2 and get number of banks  (lower bit is 0)
	add		a,c
	ld		c,a

	ld		de,sample_info_len			; move to next sample
	add		ix,de
	djnz	@AllChannels2
	
	ret

; ********************************************************************************************
; Detect the number of samples and channels in the file - normally 31 inst, 4 channels
; in:  IX = base of file
; Out: A  = num instruments
; ********************************************************************************************
ModGetInstrumentsChannels:
	push	ix
	call	FindID
	pop	ix
	and		a
	jr		z,@Inst15		; 15 instruments in file
	ld		(ModNumChan),a
	ld		a,31
	ld		(ModNumInst),a
	ret
@Inst15:
	ld		a,4
	ld		(ModNumChan),a
	ld		a,15
	ld		(ModNumInst),a
	ret

; ********************************************************************************************
; Find the IDs that we support (nothing over 8 channels coz... that's nuts)
; ********************************************************************************************
FindID:
	ld		hl,ModIDs

@CheckAll:	
	push	hl
	push	ix
	ld		a,(hl)
	and		a			; end of list?
	jr		z,@ExitNoneFound
	ret		z

	ld		b,4
@CheckLetters:
	ld		a,(hl)
	ld		d,(ix+0)
	cp		d
	jr		nz,@Next
	inc		hl
	inc		ix
	djnz	@CheckLetters
	ld		a,(ix+0)		; get number of channels
@ExitNoneFound:
	pop		ix
	pop		hl
	ret

@Next:
	pop		ix
	pop		hl
	add		hl,5
	jr		@CheckAll
	xor		a
	ret


; ********************************************************************************************
; Play Mod: reset the mod to the start, and start playing
; ********************************************************************************************
ModPlay:
		ld		a,(ModBaseBank)
		NextReg	MOD_BANK,a					; set mod bank

		ld		a,0
		ld		(ModPlaying),a				; mod is playing
		ld		(ModFrame),a
		ld		a,6
		ld		(ModDelayMax),a				; reset the delay
		ld		a,1
		ld		(ModDelayCurrent),a

		; reset sequence to the start
		xor		a
		ld		(ModPatternIndex),a			; reset to start of pattern
		ld		hl,ModPattern
		add		hl,a
		ld		(ModSequanceOrder_Current),hl
	
		; get next sequence
		ld		a,(hl)
		call	SetUpSequence
		ret




; ********************************************************************************************
; Setup the next sequence
; In:  A = sequence to setup
; ********************************************************************************************
SetUpSequence:
		ld		l,a
		ld		h,0
		add		hl,hl
		add		hl,a			; sequence * 3

		ld		de,ModSequenceData
		add		hl,de

		ld		e,(hl)
		inc		hl
		ld		d,(hl)
		inc		hl
		ld		a,(hl)
		add		de,MOD_ADD					; base of "banks"
		ld		(ModPatternAddress),de
		ld		(ModPatternBank),a

		xor		a
		ld		(ModSequenceIndex),a
		ret


		include	"mod_tick.asm"
		include	"mod_data.asm"

