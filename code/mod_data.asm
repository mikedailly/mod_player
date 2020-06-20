; mod file data

MOD_BANK		equ	$52				; which MMU bank to use (this one and the next)
MOD_ADD			equ	$4000			; base address of this bank
MOD_VOL_BANK	equ	$50				; which MMU bank to use for volumes
MOD_VOL_ADD		equ	$4000			; base of volume banks

DMABaseFreq		equ	875000					; DMA base freq
TVRate			equ	50						; framerate
SamplesPerFrame	equ	128						; 104 samples per frame
PlaybackFreq	equ	SamplesPerFrame*TVRate	; freq


; mod file addresses
MOD_SAMPLES		equ	MOD_ADD+20		; base of sample info
MOD_ID			equ	MOD_ADD+1080	; base of 4 byte file ID

; the file structure of a sample
						rsreset
file_sample_name		rb	22
file_sample_len			rw	1		; length in words (*2=bytes)
file_sample_fine		rb	1		; sample fine tune 0-7, +8-$f = -8 to -1
file_sample_vol			rb	1		; volume, range is $00 to $40
file_sample_rep			rw	1		; repeat point
file_sample_rep_len		rw	1		; repeat length
file_sample_info_len	rb	0


					rsreset
sample_len			rb	3		; length in words (*2=bytes)
sample_fine			rb	1		; sample fine tune 0-7, +8-$f = -8 to -1
sample_vol			rb	1		; volume, range is $00 to $40
sample_rep			rw	1		; repeat point
sample_rep_len		rw	1		; repeat length
sample_offset		rw	1		; the offset into the bank for the actual sample data
sample_bank			rb	1		; the start bank of the sample
sample_info_len		rb	0


					rsreset
note_volume			rb	1		; current channel volume
note_sample			rb	1		; the sample being played
note_period			rw	1		; 12 bit sample period (or effect paramater)
note_effect			rw	1		; 12 bit effect value
note_sample_off		rw	1		; base address of sample
note_sample_bank	rw	1		; base bank of sample
note_sample_rep		rw	1		; base address of repeat for sample
note_sample_repb	rb	1		; base bank of repeat for sample
note_sample_cur		rw	1		; CURRENT offset address
note_sample_curb	rb	1		; CURRENT bank address
note_sample_delta	rw	1		; sample delta
note_sample_length	rw	1		; Current length to still play
note_length_delta	rw	1		; number of bytes copied each frame
note_size			rb	0		; size of note



ModIDs:
    db "M.K.",4		; ID,channels
    db "M!K!",4
    db "FLT4",4    
    db "FLT8",8
    db "OKTA",8
    db "OCTA",8
    db "FA08",8		; if ID is listed here, then 31 instruments
    db "CD81",8    	; if ID is NOT listed here, then 15 instruments
    db "1CHN",1
    db "2CHN",2
    db "3CHN",3
    db "5CHN",5
    db "6CHN",6
    db "7CHN",7
    db "8CHN",8
	db 0			; if we get here, then 15 instruments and 4 channels



; Mod file data
ModInitSamples				db	0			; temp so we know to init the samples or not (unsign, shift etc)
ModBaseBank					db	0			; base bank of mod file
ModMMUStore					db	0,0,0,0		; backup the MMU regs
ModTuneBase					dw	0			; the tune base address
ModDestbuffer				dw	0			; The playback buffer we're about to write to
ModSongLength				db	0			; the length of the mod (in sequences)
ModSongRestart				db	0			; restart point (in sequences)
ModSequanceOrder			dw	0			; the sequence order
ModSequanceOrder_current	dw	0			; current pointer to the sequence order
ModNumInst					db	0			; number of instruments (15 or 31)
ModNumChan					db	0			; number of channels 1-8
ModHighestPattern			db	0			; largest pattern number
ModChannelData				dw	0			; base of channel data
ModSequenceSize				dw	0			; size of a single sequence (4*channels*64 notes)
ModPattern					ds	128						; copy to pattern sequence local so we don't have to bank switch to read it
ModSamples					ds	31*sample_info_len		; Sample structs + address of all sampls (offset:w,bank:b)
ModSequenceData				ds	128*3					; start address of all sequences (n channels * 64 entries)

ModPlaying					db	0			; is the mod playing?
ModSampleCopySize			db	0			; number of bytes being copied in "this" sample
ModChannelCounter			db	0			; channel number being processed

ModPatternIndex				db	0			; the current pattern we're playing from
ModPatternAddress			dw	0			; the offset of the current pattern
ModPatternBank				db	0			; the bank of the current pattern
ModSequenceIndex			db	0			; the current note index inside a sequence (0 to 63)
ModDelayCurrent				db	0			; the current delay
ModDelayMax					db	0			; the reset delay

ModChanData					ds	note_size*8	; all the data from the last note

ModFrame					db	0			; buffer index

; debug (allows wrting the whole tune to a single sample for saving via debugger)
TuneBank					db	ModSampleBank
TuneAddress					dw	MOD_ADD


							align	256
ModSamplePlayback			ds	SamplesPerFrame
							align	256
ModSamplePlayback2			ds	SamplesPerFrame
							align	256
ModAccumulationBuffer		db	SamplesPerFrame		; WORD size buffer











