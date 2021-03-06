; Mod player
; By Mike Dailly, (c) Copyright 2020 all rights reserved.

; mod file data

MOD_BANK		equ	$52				; which 2xMMU banks to use (this one and the next)
MOD_ADD			equ	$4000			; base address of this bank
MOD_VOL_BANK	equ	$50				; which 2xMMU banks to use for volumes (this one and the next)
MOD_VOL_ADD		equ	$0000			; base of volume banks


DMABaseFreq		equ	875000					; DMA base freq
TVRate			equ	50						; framerate
SamplesPerFrame	equ	255						; 104 samples per frame  (71 the LOWEST value possible - timings change onm HDMI/VGA etc)
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
file_sample_rep			rw	1		; repeat point (upto 128k location)
file_sample_rep_len		rw	1		; repeat length (3 bytes - 128K sample length BYTES 64k WORD)
file_sample_info_len	rb	0


					rsreset
sample_len			rb	3		; length in words (*2=bytes)
sample_fine			rb	1		; sample fine tune 0-7, +8-$f = -8 to -1
sample_vol			rb	1		; volume, range is $00 to $40
sample_rep			rb	3		; repeat point
sample_rep_bank		rb	1		; repeat point BANK
sample_rep_len		rb	3		; repeat length
sample_end			rb	3		; END point of sample (sometimes the end of ta repeat, rather than end of sample)
sample_end_bank		rb	1		; END bank
sample_offset		rw	1		; the offset into the bank for the actual sample data
sample_bank			rb	1		; the start bank of the sample
sample_info_len		rb	0


					rsreset
note_volume			rb	1		; current channel volume
note_volume_channel	rb	1		; when setting volume, we need to be able to override the sample one
note_volume_sample	rb	1		; the last sample volume
note_sample			rb	1		; the sample being played (0 for nothing playing)
note_period			rw	1		; 12 bit sample period (or effect paramater)
note_pitch_bend		rw	1		; the pitch bend delta (signed 16bit)
note_last_period	rw	1		; Last note period (incase we need to restore it)
note_effect			rw	1		; 12 bit effect value
note_sample_off		rw	1		; base address of sample
note_sample_bank	rw	1		; base bank of sample
note_sample_rep		rw	1		; base address of repeat for sample
note_sample_repb	rb	1		; base bank of repeat for sample  (0 for no repeat)
note_sample_cur		rw	1		; CURRENT address of sample playing
note_sample_curb	rb	1		; CURRENT bank of sample playing
note_sample_end		rw	1		; END of sample - for repeates
note_sample_endb	rb	1		; End of sample bank - for repeates
note_sample_delta	rw	1		; sample delta
note_sample_replen	rw	1		; Repeat length
note_sample_length	rb	3		; Current length still to play
note_sample_lengthF	rb	1		; Current length fraction
note_length_delta	rw	1		; number of bytes copied each frame
note_length_deltaF	rb	1		; number of bytes copied each frame - fraction
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
ModSamplesPerFrame			dw	0			; number of samples per frame we're working to....
ModDMAValue					db	0			; 875000/(samples_per_frame*TVRate)

ModInitSamples				db	0			; temp so we know to init the samples or not (unsign, shift etc)
ModBaseBank					db	0			; base bank of mod file
ModMMUStore					db	0,0,0,0		; backup the MMU regs
ModTuneBase					dw	0			; the tune base address
ModDestbuffer				dw	0			; The playback buffer we're about to write to
ModSongLength				db	0			; the length of the mod (in sequences)
ModSongRestart				db	0			; restart point (in sequences)
ModSequanceOrder			dw	0			; the sequence order
ModSequanceOrder_current	dw	0			; current pointer to the sequence order
ModSequanceOffset			dw	0			; the value to offset the NEXT sequence (usually 0)
ModNumInst					db	0			; number of instruments (15 or 31)
ModNumChan					db	0			; number of channels 1-8
ModHighestPattern			db	0			; largest pattern number
ModChannelData				dw	0			; base of channel data
ModSequenceSize				dw	0			; size of a single sequence (4*channels*64 notes)
ModGlobalVolume				db	0			; the global mod volume
Mod_table_freq				dw	0			; used in table generation
ModSamplesToFill			dw	0			; number of sample bytes to fill with this note/sample

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
ModTemp						db	0			; tmep usage

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











