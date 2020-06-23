;
; Mod_player
;
; ********************************************************************************************
;	A  = root bank of MOD file (tune always starts at 0)
;   B  = InitSamples (0 = no)
; ********************************************************************************************
ModInit:
	Call	DetectDMALength


	; restore SpecDrumPort
	ld		hl,$ffdf					; set the SpecDrum Port
	ld		(DMADestPort),hl
	ld		hl,ModSamplesPerFrame		; set number of samples per frame
	ld		(ModSampleLength),hl
	ld		a,(ModDMAValue)				; set DMA value
	ld		(DMASampleRate),a
	ret

; ********************************************************************************************
; Detect how many bytes the DMA can send a frame at the 
;   B  = InitSamples (0 = no)
; ********************************************************************************************
DetectDMALength:
	ld		a,SamplesPerFrame
	ld		hl,$fdfd				; use a non-existant port
	ld		(DMADestPort),hl	
	
	; (DMABaseFreq) / (((SamplesPerFrame)*TVRate))	
	ld		e,SamplesPerFrame
	ld		d,TVRate
	mul
	ld		c,e
	ld		b,d
	ld		hl,$000D
	ld		ix,$59F8
	call	Div_32x16
	ld		a,ixl
	ld		(ModDMAValue),a
	
	ld		hl,ModSamplesPerFrame
	ld		(ModSampleLength),hl


	; ------------------------------------------------------------------------------------------------
	; Loop around multiple DMA transfers and detect when we've managed to transfer everything
	; ------------------------------------------------------------------------------------------------
TryDMAAgain:
	call	WaitForRasterPos

	ld		a,(ModDMAValue)
	ld		(DMASampleRate),a			; store DMA prescaler value into DMA program
	ld		hl,0
	call	ModPlaySample

	; make sure we're past the scan line...
	ld		b,0
@lppp2:
	nop
	nop
	djnz	@lppp2

	; wait a frame
	call	WaitForRasterPos

	; now read how far we got...
	call	DMAReadLen		

	; now check to see if we transferred all the data
	ld		a,Hi(SamplesPerFrame)
	cp		h
	jr		nz,SizeNotFound
	ld		a,Lo(SamplesPerFrame)
	cp		l
	jr		nz,SizeNotFound

	; DMA size found
	ret

SizeNotFound
	ld		b,0
@lppp23:
	nop
	nop
	djnz	@lppp23

	; wait another frame
	call	WaitForRasterPos

	ld		b,0
@lppp4:
	nop
	nop
	djnz	@lppp4


	ld		a,(ModDMAValue)
	dec		a
	ld		(ModDMAValue),a
	jp		TryDMAAgain

@FoundSize:
	ret

WaitForRasterPos:
	call	ReadRaster
	xor		a
	cp		h
	jr		nz,WaitForRasterPos
	ld		a,$30
	cp		l
	jr		nz,WaitForRasterPos
	ret



; ********************************************************************************************
;	A  = root bank of MOD file (tune always starts at 0)
;   B  = InitSamples (0 = no)
; ********************************************************************************************
ModLoad:
	;ld		de,255*50
	;call	GenerateNoteTable

	ld		(ModBaseBank),a
	NextReg	MOD_BANK,a				; bank in mod file
	ld		a,b
	ld		(ModInitSamples),a

	; pre-process the 31 samples.
	ld		ix,MOD_ID						; get number of instruments
	call	ModGetInstrumentsChannels		; detect the number of instruments	


	ld		b,a
	ld		ix,MOD_SAMPLES			; base of sample table
	ld		iy,ModSamples			; sample structs
@SetUpAllSamples:
	; swap sample length from amiga format
	ld		h,(ix+file_sample_len)			; sample size in WORDS (*2 for bytes)
	ld		l,(ix+(file_sample_len+1))
	add		hl,hl
	ld		(iy+sample_len),l
	ld		(iy+(sample_len+1)),h
	ld		a,0
	adc		a,0
	ld		(iy+(sample_len+2)),l
	
	; fine tune
	ld		a,(ix+file_sample_fine)
	ld		(iy+sample_fine),a

	; volume adjust
	ld		a,(ix+file_sample_vol)
	cp		63
	jr		c,@SkipReset
	ld		a,63
@SkipReset:
	ld		(iy+sample_vol),a

	; swap sample repeat point from amiga format
	ld		a,(ix+file_sample_rep)		
	ld		(iy+(sample_rep+1)),a
	ld		a,(ix+(file_sample_rep+1))
	ld		(iy+sample_rep),a

	; swap sample repeat length  from amiga format
	ld		h,(ix+file_sample_rep_len)		
	ld		l,(ix+(file_sample_rep_len+1))
	ld		(iy+sample_rep_len),l
	ld		(iy+(sample_rep_len+1)),h

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
CopyPattern
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


	; ----------------------------------------------------------------------------------------
	; work out start bank+offset of each sequence start address	
	; ----------------------------------------------------------------------------------------
CalcSeqStartAdd:
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
	


	; ----------------------------------------------------------------------------------------
	; Now work out the start and bank of all SAMPLES
	; also convert all samples to unsigned (and pre-scale)
	; ----------------------------------------------------------------------------------------
ModReadSamples:
	; HL now points to SAMPLE data (offset), while C is the bank
	ld		ix,ModSamples
	ld		a,(ModNumInst)
	ld		b,a

AllChannels2:
	ld		a,h
	and		$1f
	ld		h,a
	ld		(ix+sample_offset),l
	ld		(ix+(sample_offset+1)),h
	ld		a,c
	ld		(ix+sample_bank),c

	ld		e,(ix+sample_len)				; get sample length (we can only deal with sample lengths of 65534 and less)
	ld		d,(ix+(sample_len+1))
	add		hl,de

	ld		a,h
	swapnib							; swap from $1f to $f1
	and		$0e						; now mask to keep $0e
	rrca							; /2 and get number of banks  (lower bit is 0)
	add		a,c
	ld		c,a

	ld		a,(ModInitSamples)
	and		a
	jr		z,DontInitSamples

	; Now convert the sample into unsigned and pre-scale it
	exx
	ld		l,(ix+sample_offset)
	ld		h,(ix+(sample_offset+1))
	add		hl,MOD_ADD
	ld		a,(ix+sample_bank)
	NextReg	MOD_BANK,a
	ex		af,af'
	ld		c,(ix+sample_len)				; get sample length (we can only deal with sample lengths of 65534 and less)
	ld		b,(ix+(sample_len+1))
	ld		a,c
	or		b
	jr		z,@EmptySample
@DoAllSample:
	ld		a,(hl)
	sra		a
	sra		a
	;add		$80
	;srl		a
	;srl		a
	ld		(hl),a
	inc		hl

	ld		a,h
	cp		Hi(MOD_ADD+$2000)
	jr		nz,@NotNextBank
	;		swap bank
	add		hl,-$2000	
	ex		af,af'
	inc		a
	NextReg	MOD_BANK,a
	ex		af,af'
	
@NotNextBank:
	add		bc,-1
	ld		a,b
	or		c
	jr		nz,@DoAllSample
@EmptySample
	exx



DontInitSamples:
	ld		de,sample_info_len			; move to next sample
	add		ix,de
	djnz	AllChannels2
	

	; ----------------------------------------------------------------------------------------
	; clear playback buffer
	; ----------------------------------------------------------------------------------------
	ld		b,SamplesPerFrame*2
	ld		hl,ModSamplePlayback
@ClearSample:
	xor		a
	ld		(hl),a
	djnz	@ClearSample

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
	ld		a,(hl)		; get number of channels
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

		; set global volume
		ld		a,$40
		ld		(ModGlobalVolume),a

		; init all channels
		ld		ix,ModChanData
		ld		a,(ModNumChan)
		ld		b,a
		
InitAllChannels:
		ld		a,$40
		ld		(ix+note_volume_sample),a
		ld		(ix+note_volume_channel),a
		ld		(ix+note_volume),a
	
		xor		a
		ld		(ix+note_sample),a
		ld		(ix+note_sample_off),a
		ld		(ix+(note_sample_off+1)),a
		ld		(ix+note_sample_length),a
		ld		(ix+(note_sample_length+1)),a
		ld		(ix+note_sample_lengthF),a

		ld		de,note_size
		add		ix,de
		djnz	InitAllChannels
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




; ********************************************************************************************
; Generate note table
; DE = Frequency
; ********************************************************************************************
GenerateNoteTable:
		ld		(Mod_table_freq),de
		ld		bc,4095
		ld		hl,NoteLookup+(4095*2)

@BuildAll:
		push	hl
		push	bc
		exx
		
		ld		hl,$6C3E			; PAL = 7093789.2*256
		ld		ix,$1D33
		pop		bc
		sla		c					; PAL / (note*2)
		rl		b

		call	Div_32x16			; hlix / bc = hlix = answer, de   = remainder

		ld		bc,(Mod_table_freq)
		call	Div_32x16			; hlix / bc
		
		pop		hl
		push	ix
		pop		de
		ld		(hl),e
		inc		hl
		ld		(hl),d
		exx
		dec		hl
		dec		hl
		dec		bc
		ld		a,b
		or		c
		jr		nz,@BuildAll
		ret

Mod_table_freq	dw	0



		include	"mod_tick.asm"
		include	"mod_misc.asm"
		include	"mod_effect.asm"
		include	"mod_data.asm"
NoteLookup:		
		incbin	"note_table.dat"			; MOD->PAL->SampleRate conversion

		Seg		MOD_VOLUME	
VolumeTable:
		incbin	"mod_volume.dat"			; sample*volume conversion



