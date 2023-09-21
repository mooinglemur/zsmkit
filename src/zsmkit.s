.include "x16.inc"
.include "audio.inc"
.include "macros.inc"

.macpack longbranch

.export zsm_init_engine
.export zsm_tick
.export zsm_play
.export zsm_stop
.export zsm_close
.ifdef ZSMKIT_ENABLE_STREAMING
.export zsm_fill_buffers
.export zsm_setlfs
.export zsm_setfile
.export zsm_loadpcm
.endif
.export zsm_setmem
.export zsm_setatten
.export zsm_rewind
.export zsm_setcb
.export zsm_clearcb
.export zsm_getstate
.export zsm_setrate
.export zsm_getrate
.export zsm_setloop
.export zsm_opmatten
.export zsm_psgatten
.export zsm_pcmatten
.export zsm_set_int_rate

.export zcm_setmem
.export zcm_play
.export zcm_stop

.export zsmkit_setisr
.export zsmkit_clearisr

; exports for peeking inside from players, etc
.export vera_psg_shadow
.export opm_key_shadow
.export opm_shadow
.export pcm_busy

; exports for players (Melodius) to see where
; the song cursors are
.export zsm_loop_bank
.export zsm_loop_l
.export zsm_loop_h

.export zsm_ptr_bank
.export zsm_ptr_l
.export zsm_ptr_h

.export pcm_cur_bank
.export pcm_cur_l
.export pcm_cur_h

.export loop_enable


NUM_ZCM_SLOTS = 32
NUM_PRIORITIES = 4
FILENAME_MAX_LENGTH = 64
RINGBUFFER_SIZE = 1024

.segment "ZSMKITLIB"
zsmkit_bank: ; the RAM bank dedicated to ZSMKit to use for state
	.res 1
saved_bank: ; used for preserving the bank in main loop calls
	.res 1
saved_bank_irq: ; used for preserving the bank in IRQ call
	.res 1
buff: ; used for things like filenames which need to be in low RAM
	.res FILENAME_MAX_LENGTH
tmp1 := buff
tmp2 := buff+4
tmp3 := buff+8

.segment "ZSMKITBANK"
_ZSM_BANK_START := *

; To support the option of streaming ZSM data from SD card,
; ZSMKit allocates 1k for each of the four priorities.
; These ring buffers are fed by calling `zsm_fill_buffers`
; in the program's main loop. In the event of an underrun,
; the engine will halt the song and mark it as not playable.
;
; The ring buffers for the four priorities are located at:
; 0:$A000 1:$A400 2:$A800 3:$AC00
;
; offset = (priority * 1024)
zsm_ringbuffers:        .res NUM_PRIORITIES*RINGBUFFER_SIZE

; offset = priority*256
opm_shadow:             .res NUM_PRIORITIES*256

; offset = (priority * 64) + (register)
vera_psg_shadow:        .res NUM_PRIORITIES*64

; offset = (priority * 8) + (voice)
opm_atten_shadow:       .res NUM_PRIORITIES*8

; offset = (priority * 8) + (voice)
opm_key_shadow:			.res NUM_PRIORITIES*8

; offset = (priority * 16) + (voice)
vera_psg_atten_shadow:  .res NUM_PRIORITIES*16

pcm_ctrl_shadow:        .res NUM_PRIORITIES
pcm_rate_shadow:        .res NUM_PRIORITIES
pcm_atten_shadow:       .res NUM_PRIORITIES

; These two arrays are set via properties on the ZSM
; based on which voices are used.  If the priority slot
; is not active, these are zeroed.

; offset = (priority * 8) + (voice)
opm_voice_mask:         .res NUM_PRIORITIES*8

; offset = (priority * 16) + (voice)
vera_psg_voice_mask:    .res NUM_PRIORITIES*16

; Is the song playing? Nonzero is truth.
; offset = (priority)
prio_active:            .res NUM_PRIORITIES

; Did the player encounter a fault of some sort?
; This is set zero whenever that happens
; It is set nonzero when a file is loaded and
; is ready
prio_playable:          .res NUM_PRIORITIES

; Callback is called whenever the song ends or loops
callback_addr_l:        .res NUM_PRIORITIES
callback_addr_h:        .res NUM_PRIORITIES
callback_bank:          .res NUM_PRIORITIES
callback_enabled:       .res NUM_PRIORITIES

.ifdef ZSMKIT_ENABLE_STREAMING
; Is the song fully in memory or played through a 1k ring buffer?
; zero = traditional memory storage, nonzero = ring buffer
; offset = (priority)
streaming_mode:         .res NUM_PRIORITIES

; The ring buffer positions (absolute addresses)
; offset = (priority)
ringbuffer_start_l:     .res NUM_PRIORITIES
ringbuffer_start_h:     .res NUM_PRIORITIES

; offset = (priority)
; end is non-inclusive
ringbuffer_end_l:       .res NUM_PRIORITIES
ringbuffer_end_h:       .res NUM_PRIORITIES

; 24 bit address within the file
; where the loop point exists
; offset = (priority)
streaming_loop_point_l: .res NUM_PRIORITIES
streaming_loop_point_m: .res NUM_PRIORITIES
streaming_loop_point_h: .res NUM_PRIORITIES

; 24 bit offset of what has been read
; from the streamed ZSM
streaming_pos_l:        .res NUM_PRIORITIES
streaming_pos_m:        .res NUM_PRIORITIES
streaming_pos_h:        .res NUM_PRIORITIES

; 24 bit offset of where it expects to find
; the end of data marker.
; beyond this point could be PCM data
; and we don't want to slurp that in when streaming
streaming_eod_l:        .res NUM_PRIORITIES
streaming_eod_m:        .res NUM_PRIORITIES
streaming_eod_h:        .res NUM_PRIORITIES

; When `zsm_fill_buffers` encounters EOI, this flag is set.
; Since opening a file can be expensive, we save that for
; the next tick. That call then reopens the file, seeks
; to the loop point, and then returns. The call on the tick
; subsequent to that is the first to start pumping data
; into the ring buffer again.
streaming_reopen:       .res NUM_PRIORITIES

; streaming filename OPEN string, must be <=64 bytes
; we need to keep this in the engine because looping
; will typically require the file to be reopened.
; offset = (priority*64)
streaming_filename:     .res NUM_PRIORITIES*FILENAME_MAX_LENGTH
; offset = (priority)
streaming_filename_len: .res NUM_PRIORITIES

; The logical file number and the secondary address are both the same
; and are assigned by the user
streaming_lfn_sa:       .res NUM_PRIORITIES

; Device, almost always 8
streaming_dev:          .res NUM_PRIORITIES

; Goes true when streaming is finished
streaming_finished:     .res NUM_PRIORITIES
.endif

; For non-streaming mode, the bank and offset of the beginning of
; the song, loop point, and of the current pointer
; offset = (priority)
zsm_start_bank:         .res NUM_PRIORITIES
zsm_start_l:            .res NUM_PRIORITIES
zsm_start_h:            .res NUM_PRIORITIES

zsm_loop_bank:          .res NUM_PRIORITIES
zsm_loop_l:             .res NUM_PRIORITIES
zsm_loop_h:             .res NUM_PRIORITIES 

zsm_ptr_bank:           .res NUM_PRIORITIES
zsm_ptr_l:              .res NUM_PRIORITIES
zsm_ptr_h:              .res NUM_PRIORITIES

; For both streaming and non-streaming mode
loop_enable:            .res NUM_PRIORITIES

loop_number_l:          .res NUM_PRIORITIES
loop_number_h:          .res NUM_PRIORITIES

; Hz (from file)
tick_rate_l:            .res NUM_PRIORITIES
tick_rate_h:            .res NUM_PRIORITIES

; speed (Hz/60) - delays to subtract per tick
speed_f:                .res NUM_PRIORITIES
speed_l:                .res NUM_PRIORITIES
speed_h:                .res NUM_PRIORITIES

; delay (playback state)
delay_f:                .res NUM_PRIORITIES
delay_l:                .res NUM_PRIORITIES
delay_h:                .res NUM_PRIORITIES

; if exists, points to the PCM instrument table in RAM
pcm_table_exists:       .res NUM_PRIORITIES
pcm_table_bank:         .res NUM_PRIORITIES
pcm_table_l:            .res NUM_PRIORITIES
pcm_table_h:            .res NUM_PRIORITIES

pcm_inst_max:           .res NUM_PRIORITIES

pcm_data_bank:          .res NUM_PRIORITIES
pcm_data_l:             .res NUM_PRIORITIES
pcm_data_h:             .res NUM_PRIORITIES

; The prio that currently has a PCM event going
; $80 means ZCM is/was playing
; ZCM always takes over the PCM channel
pcm_prio:               .res 1

; Set while playing.  Higher priorities can take over
; PCM by emptying the FIFO and then starting their own
; sound
pcm_busy:               .res 1

; The pointer to the PCM data to read next
pcm_cur_bank:           .res 1
pcm_cur_l:              .res 1
pcm_cur_h:              .res 1

; Bytes left for reading data to pump into the FIFO
pcm_remain_l:           .res 1
pcm_remain_m:           .res 1
pcm_remain_h:           .res 1

; Loop point
pcm_loop_bank:          .res 1
pcm_loop_l:             .res 1
pcm_loop_h:             .res 1
pcm_islooped:           .res 1

pcm_loop_rem_l:         .res 1
pcm_loop_rem_m:         .res 1
pcm_loop_rem_h:         .res 1

zcm_mem_bank:           .res NUM_ZCM_SLOTS
zcm_mem_l:              .res NUM_ZCM_SLOTS
zcm_mem_h:              .res NUM_ZCM_SLOTS

; These arrays contain $FF if the voice is unused or will contain
; the priority (0-3) of the module that is allowed to use the voice.
; Other active modules will only feed their shadow instead.
;
; Forced inhibit of a voice will set this priority to $FE.
; This is useful when manipulating a voice directly in user code.
;
; Generally the value is set to the highest module
; priority (slot) which uses the voice
opm_priority:            .res 8
vera_psg_priority:       .res 16

; restore shadow at beginning of next tick
; for opm, this means releasing the note on this channel
; after setting the fastest release time possible
; before copying the shadow in
opm_restore_shadow:      .res 8
vera_psg_restore_shadow: .res 16

; the flag to indicate that we need to re-evaluate the priorities
; since it's likely a song is no longer playing
recheck_priorities:      .res 1

; chip type (from X16 audio library)
ym_chip_type:            .res 1

; interrupt rate (default 60)
int_rate:                .res 1
int_rate_frac:           .res 1

_ZSM_BANK_END := *


.segment "ZSMKITLIB"
;..................
; zsm_init_engine :
;============================================================================
; Arguments: .A = designated RAM bank to use for ZSMKit engine state
; Returns: (none)
; Preserves: .P
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Initializes the memory locations used by ZSMKit's engine and calls
; audio_init using the X16's AUDIO API to reset its state..
; Needs to be called once before any other ZSMKit function.

.proc zsm_init_engine: near
	php
	sei

	sta zsmkit_bank

	lda X16::Reg::ROMBank
	pha
	lda #$0A
	sta X16::Reg::ROMBank

	jsr audio_init
	PRESERVE_BANK_CLOBBER_A_P

	; This will overshoot the allocated part of the ZSM
	; bank and round up to the page boundary, which
	; should be fine

	ldx #<_ZSM_BANK_START
	stz P1
	lda #>_ZSM_BANK_START
	sta P1+1
eraseloop:
	stz $a000,x
P1=*-2
	inx
	bne eraseloop
	cmp #>_ZSM_BANK_END
	bcs erasedone
	lda P1+1
	inc
	sta P1+1
	bra eraseloop
erasedone:

.ifdef ZSMKIT_ENABLE_STREAMING
	ldx #NUM_PRIORITIES-1
prioloop:
	lda #8
	sta streaming_dev,x
	txa
	clc
	adc #11
	sta streaming_lfn_sa,x

	dex
	bpl prioloop
.endif
	; default rate of 60 Hz
	lda #60
	sta int_rate
	stz int_rate_frac

	ldx #$01

	jsr ym_get_chip_type
	sta ym_chip_type

	cmp #1
	bne :+
	ldx #$09
:	stx TEST_REGISTER

	pla
	sta X16::Reg::ROMBank

	RESTORE_BANK
	plp
	rts
.endproc


;.............
; zsm_setisr :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets up a default ISR handler and injects it before the existing ISR
zsmkit_setisr:
	nop
	php
	sei
	lda #$ea
	sta zsmkit_clearisr ; ungate zsmkit_clearisr
	lda #$60
	sta zsmkit_setisr ; gate zsmkit_setisr
	lda X16::Vec::IRQVec
	sta _old_isr+1
	lda X16::Vec::IRQVec+1
	sta _old_isr+2
	lda #<_isr
	sta X16::Vec::IRQVec
	lda #>_isr
	sta X16::Vec::IRQVec+1
	plp
	rts
;...............
; zsm_clearisr :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Clears the default ISR handler if it exists and restores the previous one
zsmkit_clearisr:
	rts
	php
	sei
	lda #$60
	sta zsmkit_clearisr ; gate zsmkit_clearisr
	lda #$ea
	sta zsmkit_setisr ; ungate zsmkit_setisr
	lda _old_isr+1
	sta X16::Vec::IRQVec
	lda _old_isr+2
	sta X16::Vec::IRQVec+1
	plp
	rts

;.......
; _isr :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; 
; Default ISR set by zsmkit_setisr
_isr:
	lda #0
	jsr zsm_tick

_old_isr:
	jmp $ffff

;...........
; zsm_tick :
;============================================================================
; Arguments: .A = 0 (tick music data and PCM)
;            .A = 1 (tick PCM only)
;            .A = 2 (tick music data only)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; Master player tick entry point
;
; advances songs and plays the notes
;
.proc zsm_tick: near
	sta DOX
	PRESERVE_BANK_CLOBBER_A_P_IRQ

	lda X16::Reg::ROMBank
	sta R1
	lda #$0A
	sta X16::Reg::ROMBank

	; preserve VERA state
	lda Vera::Reg::Ctrl
	sta C1
	stz Vera::Reg::Ctrl
	lda Vera::Reg::AddrL
	sta A1
	lda Vera::Reg::AddrM
	sta A2
	lda Vera::Reg::AddrH
	sta A3

	; point to PSG page, no increment
	lda #$01
	sta Vera::Reg::AddrH
	lda #$f9
	sta Vera::Reg::AddrM

	lda #$ff
DOX = *-1
	and #1
	bne ckpcm

	jsr _reprio
	jsr _reshadow

	ldx #NUM_PRIORITIES-1
	stx prio
prioloop:
	jsr _prio_tick
	ldx prio
	dex
	stx prio
	bpl prioloop

ckpcm:
	lda DOX
	and #2
	bne tdone
	jsr _pcm_player

tdone:
	; restore VERA state
	lda #$ff
A3 = *-1
	sta Vera::Reg::AddrH
	lda #$ff
A2 = *-1
	sta Vera::Reg::AddrM
	lda #$ff
A1 = *-1
	sta Vera::Reg::AddrL
	lda #$ff
C1 = *-1
	sta Vera::Reg::Ctrl
	lda #$ff
R1 = *-1
	sta X16::Reg::ROMBank
	RESTORE_BANK_IRQ
	rts
prio:
	.byte 0
.endproc

;.............
; zcm_setmem :
;============================================================================
; Arguments: .X = ZCM slot, .A .Y = data pointer, $00 = ram bank
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the start of memory for a digital sample (ZCM format)
.proc zcm_setmem: near
	sta AL
	lda X16::Reg::RAMBank
	sta BK
	PRESERVE_BANK_CLOBBER_A_P
	cpx #NUM_ZCM_SLOTS
	bcs end

	lda #$00
AL = * - 1
	sta zcm_mem_l,x
	tya
	sta zcm_mem_h,x
	lda #$00
BK = * - 1
	sta zcm_mem_bank,x

end:
	RESTORE_BANK
	rts
.endproc


;...........
; zcm_play :
;============================================================================
; Arguments: .X = ZCM slot, .A = volume
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Begins playback of a ZCM digital sample
.proc zcm_play: near
	and #$0f
	ora #$80
	sta VR
	PRESERVE_BANK_CLOBBER_A_P

	cpx #NUM_ZCM_SLOTS
	bcs end

	; If high byte of address is zero, it's not valid
	lda zcm_mem_h,x
	beq end
	sta PT+1
	lda zcm_mem_l,x
	sta PT

	lda zcm_mem_bank,x
	sta X16::Reg::RAMBank

	ldx #0
check_sig:
	jsr get_next_byte
	cmp #$00
	bne end ; we didn't see three zeroes where we expected it
	inx
	cpx #3
	bcc check_sig

	; start critical section
	php
	sei

	; slurp up the length, geometry, and rate
	ldx #5
:	jsr get_next_byte
	pha
	dex
	bne :-	

	; save bank
	lda X16::Reg::RAMBank
	pha

	lda zsmkit_bank
	sta X16::Reg::RAMBank

	pla ; bank
	sta pcm_cur_bank

	lda PT
	sta pcm_cur_l

	lda PT+1
	sta pcm_cur_h

	pla ; rate
	sta Vera::Reg::AudioRate

	pla ; geometry
	and #$30
	ora #$8f
VR = * - 1
	sta Vera::Reg::AudioCtrl

	pla ; size h
	sta pcm_remain_h

	pla ; size m
	sta pcm_remain_m

	pla ; size l
	sta pcm_remain_l

	lda #$80
	sta pcm_busy
	sta pcm_prio

	stz pcm_islooped

	plp ; restore interrupt mask state
end:
	RESTORE_BANK
	rts

.endproc

;...........
; zcm_stop :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Stops playback of a ZCM if one is playing
; Does not stop the PCM channel if a ZSM's PCM event is playing
.proc zcm_stop: near
	PRESERVE_BANK_CLOBBER_A_P

	php
	sei

	lda pcm_busy
	beq end ; nothing playing

	lda pcm_prio
	bpl end ; not a ZCM playing

	sta Vera::Reg::AudioCtrl ; reset bit is set from pcm_prio
	stz pcm_busy
end:
	plp
	RESTORE_BANK
	rts
.endproc

;..........................
; _pcm_trigger_instrument :
;============================================================================
; Arguments: .X = prio, A = instrument number
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; This routine will trigger an instrument if the PCM channel is free
; or is eligible to be stolen
.proc _pcm_trigger_instrument: near
	cmp pcm_inst_max,x
	beq :+ ; ok
	jcs error ; the last instrument known is a lower index than the one requested
:	tay
	lda pcm_table_exists,x
	jeq end

	lda pcm_busy
	beq not_busy

	cpx pcm_prio
	jcc end ; PCM is busy and we are lower priority
not_busy:
	lda Vera::Reg::AudioCtrl
	and #$3f
	sta TC

	cpx pcm_prio
	beq no_reshadow
	; we're going to switch priorities, so we need to reshadow the CTRL
	; and the rate
	lda pcm_ctrl_shadow,x
	and #$0f
	sec
	sbc pcm_atten_shadow,x
	bpl :+
	lda #0
:	sta TC
	lda pcm_rate_shadow,x
	sta Vera::Reg::AudioRate
	stx pcm_prio
no_reshadow:
	; nuke any fifo contents immediately
	; and set the volume
	; we'll set the stereo/depth bits later
	lda #$ff
TC = *-1
	ora #$80
	sta Vera::Reg::AudioCtrl
	sta pcm_busy

	lda pcm_table_l,x
	sta PTI
	lda pcm_table_h,x
	sta PTI+1
	lda pcm_table_bank,x
	sta X16::Reg::RAMBank

	; multiply the offset by 16
	tya
	stz tmp_inst
.repeat 4
	asl
	rol tmp_inst
.endrepeat

	; carry is already clear
	adc PTI
	sta PTI
	lda tmp_inst
	adc PTI+1
	sta PTI+1
	jsr validate_pt_irq

	; now we should be at the instrument definiton
	sty tmp_inst
	jsr get_next_byte_irq
	cmp tmp_inst
	jne error ; This should be the instrument definition that we asked for

	; here's the geometry byte (bit depth and number of channels)
	; apply it now
	jsr get_next_byte_irq
	and #$30
	sta tmp_inst
	lda Vera::Reg::AudioCtrl
	and #$0f ; volume only, no reset
	ora tmp_inst
	sta Vera::Reg::AudioCtrl

	; slurp up the offset and length, features and loop point
	ldx #10
:	jsr get_next_byte_irq
	pha
	dex
	bne :-

	; switch back to the zsmkit bank so we can feed our variables
	lda zsmkit_bank
	sta X16::Reg::RAMBank

	pla
	sta pcm_loop_rem_h
.repeat 3
	asl ; x8
.endrepeat
	sta pcm_loop_bank
	pla
	sta pcm_loop_rem_m
:	cmp #$20
	bcc :+
	sbc #$20
	inc pcm_loop_bank
	bra :-
:	sta pcm_loop_h
	sta pcm_loop_h
	pla
	sta pcm_loop_l
	sta pcm_loop_rem_l

	pla
	and #$80
	sta pcm_islooped

	; these get fed verbatim
	pla
	sta pcm_remain_h
	pla
	sta pcm_remain_m
	pla
	sta pcm_remain_l

	; these will need to be processed
	pla
.repeat 3
	asl ; x8
.endrepeat
	sta pcm_cur_bank

	pla
:	cmp #$20
	bcc :+
	sbc #$20
	inc pcm_cur_bank
	bra :-
:	sta pcm_cur_h

	pla
	ldx pcm_prio
	clc
	adc pcm_data_l,x
	sta pcm_cur_l

	lda pcm_data_h,x
	adc pcm_cur_h
	cmp #$c0
	bcc :+
	sbc #$20
	inc pcm_cur_bank
:	sta pcm_cur_h

	lda pcm_data_bank,x
	clc
	adc pcm_cur_bank
	sta pcm_cur_bank

	; and now pcm_cur* and pcm_remain* are initialized

	; final calc of loop point
	lda pcm_islooped,x
	beq end

	lda pcm_cur_l
	clc
	adc pcm_loop_l
	sta pcm_loop_l
	lda pcm_cur_h
	adc pcm_loop_h
	cmp #$c0
	bcc :+
	sbc #$20
	inc pcm_loop_bank
:	sta pcm_loop_h

	lda pcm_cur_bank
	clc
	adc pcm_loop_bank
	sta pcm_loop_bank

	; calculate reload length after loop
	lda pcm_remain_l
	sec
	sbc pcm_loop_rem_l
	sta pcm_loop_rem_l
	lda pcm_remain_m
	sbc pcm_loop_rem_m
	sta pcm_loop_rem_m
	lda pcm_remain_h
	sbc pcm_loop_rem_h
	sta pcm_loop_rem_h
end:
	rts
error:
	lda zsmkit_bank
	sta X16::Reg::RAMBank
	stz pcm_busy
	rts

tmp_inst:
	.byte 0
.endproc

;......................
; _finalize_pcm_table :
;============================================================================
; Arguments: .X = prio
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; Enter with rambank = zsmbank
; ---------------------------------------------------------------------------
.proc _finalize_pcm_table: near
	stx PRI
	lda pcm_table_l,x
	sta PT
	lda pcm_table_h,x
	sta PT+1
	lda pcm_table_bank,x
	sta X16::Reg::RAMBank

	; Check for PCM signature, get max inst
	ldx #0
check_sig:
	jsr get_next_byte
	cmp validation,x
	bne error ; we didn't see "PCM" where we expected it
	inx
	cpx #3
	bcc check_sig

	jsr get_next_byte
	ldy X16::Reg::RAMBank
	ldx zsmkit_bank
	stx X16::Reg::RAMBank

	ldx #$ff
PRI = * - 1
	sta pcm_inst_max,x

	tya
	sta pcm_table_bank,x
	sta pcm_data_bank,x
	lda PT
	sta pcm_table_l,x
	lda PT+1
	sta pcm_table_h,x

	; multiply number of instruments by 16 bytes to offset the instrument table
	; pcm_inst_max is one less than the number of instruments, so resolve that here
	
	stz DH
	lda pcm_inst_max,x
	inc
	bne :+
	inc DH
:
.repeat 4
	asl
	asl DH
.endrepeat
	adc pcm_table_l,x
	sta pcm_data_l,x
	lda #$ff
DH = * - 1
	adc pcm_table_h,x
	cmp #$c0
	bcc :+
	sbc #$20
	inc pcm_data_bank,x
:	sta pcm_data_h,x
	lda #$80
	sta pcm_table_exists,x
	bra end
error:
	stz pcm_table_exists,x
end:
	lda zsmkit_bank
	sta X16::Reg::RAMBank
	rts

validation:
	.byte "PCM"
.endproc

;..............
; _pcm_player :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; Checks to see if any PCM events are in progress, then calculates
; how many bytes to send to the FIFO, then does so
.proc _pcm_player: near
	ldx pcm_busy
	jeq end ; nothing is playing

	ldx Vera::Reg::AudioRate
	stx RR ; self mod to restore the rate if we happen to zero it to do the
	       ; initial load
	dex
	lda Vera::Reg::ISR
	and #$08 ; AFLOW
	beq slow ; AFLOW is clear, send slow version (if rate > 0)
fast:
	cpx #$ff
	bne :+
	ldx #$7f
:	lda pcmrate_fast,x
	bra calc_bytes
slow:
	cpx #$ff
	bne :+
	rts ; AFLOW is clear and rate is 0, don't bother feeding	
:	lda pcmrate_slow,x
calc_bytes:
	; do the << 2 base amount
	stz tmp_count+1
	asl
	rol tmp_count+1
	asl
	rol tmp_count+1
	sta tmp_count
	lda Vera::Reg::AudioCtrl
	and #$10
	beq no_stereo
	asl tmp_count
	rol tmp_count+1
no_stereo:
	lda Vera::Reg::AudioCtrl
	and #$20
	beq no_16bit
	asl tmp_count
	rol tmp_count+1
no_16bit:
	stz LPIT ; clear the loop checker
	; If the fifo is completely empty, change the rate to 0 temporarily
	; so that the FIFO can be filled without it immediately starting
	; to drain
	bit Vera::Reg::AudioCtrl
	bvc :+
	stz Vera::Reg::AudioRate
:	lda pcm_remain_h
	bne normal_load ; if high byte is set, we definitely have plenty of bytes
	; Do a test-subtract to see if we would go over
	lda pcm_remain_l
	sec
	sbc tmp_count
	lda pcm_remain_m
	sbc tmp_count+1
	bcs normal_load ; borrow clear, sufficient bytes by default

	; we have fewer bytes remaining than we were going to send
	ldx pcm_remain_l
	ldy pcm_remain_m

	; looping sample?
	lda pcm_islooped
	beq not_looped
	inc LPIT
	bra loadit	
not_looped:
	; so the PCM blitting is done. Mark the pcm channel as available
	stz pcm_busy
	bra loadit
normal_load:
	; decrement remaining
	lda pcm_remain_l
	sec
	sbc tmp_count
	sta pcm_remain_l
	lda pcm_remain_m
	sbc tmp_count+1
	sta pcm_remain_m
	lda pcm_remain_h
	sbc #0
	sta pcm_remain_h

	ldx tmp_count
	ldy tmp_count+1
loadit:
	jsr _load_fifo
	lda #$80 ; this is self-mod to restore the rate in case we loaded while empty and temporarily set the rate to zero
RR = *- 1
	sta Vera::Reg::AudioRate
	lda #$00
LPIT = * - 1
	beq end
	; We looped, reset the pointers
	lda pcm_loop_bank
	sta pcm_cur_bank
	lda pcm_loop_h
	sta pcm_cur_h
	lda pcm_loop_l
	sta pcm_cur_l
	lda tmp_count
	sec
	sbc pcm_remain_l
	sta tmp_count
	lda tmp_count+1
	sbc pcm_remain_m
	sta tmp_count+1
	lda pcm_loop_rem_l
	sec
	sbc tmp_count
	sta pcm_remain_l
	lda pcm_loop_rem_m
	sbc tmp_count+1
	sta pcm_remain_m
	lda pcm_loop_rem_h
	sbc #$00
	sta pcm_remain_h
	jmp no_16bit
end:
	rts
tmp_count:
	.byte 0,0
.endproc

;.............
; _load_fifo :
;============================================================================
; Arguments: .XY = number of bytes to read and send
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; Imported from ZSound, a very efficient FIFO filler routine
; starts at pcm_cur_* and then updates their values at the end
.proc _load_fifo: near
	__CPX		= $e0	; opcode for cpx immediate
	__BNE		= $d0

	; self-mod the page of the LDA below to the current page of pcm_cur_h
	lda pcm_cur_h
	sta data_page0
	sta data_page1
	sta data_page2
	sta data_page3

	; page-align
	txa             ;.A now holds the low-byte of n-bytes to copy
	ldx pcm_cur_l   ;.X now points at the page-aligned offset
	; add the delta to bytes_left
	clc
	adc pcm_cur_l
	sta bytes_left
	bcc :+
	iny
:	lda pcm_cur_bank ; load the bank we'll be reading from
	sta X16::Reg::RAMBank
	; determine whether we have > $FF bytes to copy. If $100 or more, then
	; use the full-page dynamic comparator. Else use the last-page comparator.
	cpy #0
	beq last_page   ; if 0, then use the last_page comparator.
	; self-mod the instruction at dynamic_comparator to:
	; BNE copy_byte
	lda #__BNE
	sta dynamic_comparator
	lda #.lobyte(copy_byte0-dynamic_comparator-2)
	sta dynamic_comparator+1
	; compute num-steps % 4 (the mod4 is done by shifting the 2 LSB into N and C)
	txa
enter_loop:
	ror
	ror
	bcc :+
	bmi copy_byte3  ; 18
	bra copy_byte2  ; 20
:	bmi copy_byte1  ; 19

copy_byte0:
	lda $FF00,x
	data_page0 = (*-1)
	sta Vera::Reg::AudioData
	inx
copy_byte1:
	lda $FF00,x
	data_page1 = (*-1)
	sta Vera::Reg::AudioData
	inx
copy_byte2:
	lda $FF00,x
	data_page2 = (*-1)
	sta Vera::Reg::AudioData
	inx
copy_byte3:
	lda $FF00,x
	data_page3 = (*-1)
	sta Vera::Reg::AudioData
	inx
dynamic_comparator:
	bne copy_byte0
	; the above instruction is modified to CPX #(bytes_left) on the last page of data
	bne copy_byte0  ; branch for final page's CPX result.
	cpx #0
	bne done        ; .X can only drop out of the loop on non-zero during the final page.
	; Thus X!=0 means we just finished the final page. Done.
	; advance data pointer before checking if done on a page offset of zero.
	lda data_page0
	inc
	cmp #$c0
	beq do_bankwrap
no_bankwrap:
	; update the self-mod for all 4 iterations of the unrolled loop
	sta data_page0
	sta data_page1
	sta data_page2
	sta data_page3
check_done:
	cpy #0		; .Y = high byte of "bytes_left"
	beq done	; .X must be zero as well if we're here. Thus 0 bytes left. Done.
	dey
	bne copy_byte0	; more than one page remains. Continue with full-page mode copy.
last_page:
	lda bytes_left
	beq done		; if bytes_left=0 then we're done at offset 0x00, so exit.
	; self-mod the instruction at dynamic_comparator to be:
	; CPX #(bytes_left)
	sta dynamic_comparator+1
	lda #__CPX
	sta dynamic_comparator
	; Compute the correct loop entry point with the new exit index
	; i.e. the last page will start at x == 0, but we won't necessarily
	; end on a value x % 4 == 0, so the first entry from here into
	; the 4x unrolled loop is potentially short in order to make up
	; for it.
	; Find: bytes_left - .X
	txa
	eor #$ff
	sec	; to carry in the +1 for converting 2s complement of .X
	adc bytes_left
	; .A *= -1 to align it with the loop entry jump table
	eor #$ff
	inc
	bra enter_loop

done:
	ldy X16::Reg::RAMBank
	lda zsmkit_bank
	sta X16::Reg::RAMBank
	lda data_page0
	sta pcm_cur_h
	stx pcm_cur_l
	sty pcm_cur_bank
	rts

do_bankwrap:
	lda #$a0
	inc X16::Reg::RAMBank
	bra no_bankwrap

bytes_left:
	.byte 0
.endproc

;.............
; _prio_tick :
;============================================================================
; Arguments: X = priority
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; 
; The meat of the engine, ticks the priority forward if it is eligible to run
;
.proc _prio_tick: near
	lda prio_active,x
	beq exit

	; subtract the delay, if we go negative we loop until we accumulate enough
	; delay to go positive
	lda delay_f,x
	sec
	sbc speed_f,x
	sta delay_f,x
	lda delay_l,x
	sbc speed_l,x
	sta delay_l,x
	lda delay_h,x
	sbc speed_h,x
	sta delay_h,x
	bpl exit ; no events this tick

	; set up the shadow writes
	lda times_64,x
	adc #<vera_psg_shadow
	sta PS
	lda #>vera_psg_shadow
	adc #0
	sta PS+1

	txa
	clc
	adc #>opm_shadow
	sta OS

.ifdef ZSMKIT_ENABLE_STREAMING
	lda streaming_mode,x
	beq memory
	lda ringbuffer_start_l,x
	sta PTR
	lda ringbuffer_start_h,x
	sta PTR+1
	bra note_loop
.endif
memory:
	lda zsm_ptr_l,x
	sta PTR
	lda zsm_ptr_h,x
	sta PTR+1
	
note_loop:
	jsr getzsmbyte
	bpl isdata
	cmp #$80 ; eod?
	beq iseod
	; is delay
	and #$7f
	cmp #$30
	clc
	adc delay_l,x
	sta delay_l,x
	bcc nextnote
	inc delay_h,x
nextnote:
	jsr advanceptr	
	bcs error
	lda delay_h,x
	bmi note_loop
exit:
	rts
plaerror:
	pla
error:
	ldx prio
	stz prio_playable,x
	ldy #$00
	lda #$80
	jsr _callback
	jmp _stop_sound
isdata:
	cmp #$40
	beq isext
	bcs isopm
	; is psg
	stx prio
	pha
	jsr advanceptr
	bcs plaerror
	jsr getzsmbyte
	plx
	sta vera_psg_shadow,x ; operand is overwritten at sub entry
PS = *-2
	jsr _psg_write
	ldx prio
	bra nextnote
iseod:
	lda loop_enable,x
	bne islooped
	stz prio_active,x
	ldy #$00
	; A == 0 already
	jsr _callback
	jsr _stop_sound
	rts
isext:
	jsr advanceptr
	bcs error
	jsr getzsmbyte
	cmp #$40
	jcc ispcm
	cmp #$80
	bcc ischip
	cmp #$c0
	jcc issync
	; channel 3, future use, ignore
ischip: ; external chip, ignore
	and #$3f
	; eat the data bytes, up to 63 of them
	tay
	beq nextnote
:	jsr advanceptr
	bcs error
	dey
	bne :-
	bra nextnote
isopm:
	and #$3f
	tay
opmloop:
	jsr advanceptr
	bcs error
	jsr getzsmbyte
	stx prio
	cmp #$01 ; OPM TEST register
	bne :+
	lda #$01 ; Translated TEST register - changed to 9 for OPP
TEST_REGISTER = * - 1
:	pha
	jsr advanceptr
	jcs plaerror
	jsr getzsmbyte
	plx
	sta opm_shadow,x ; operand is overwritten at sub entry
OS = *-1
	phy
	jsr _ym_write
	ply
	cpx #$08 ; key on/off
	beq savekey
back2ymblock:
	ldx #$00
prio = * - 1
	dey
	bne opmloop
	jmp nextnote
islooped:
	inc loop_number_l,x
	bne :+
	inc loop_number_h,x
:	lda loop_number_l,x
	ldy #$01
	jsr _callback
.ifdef ZSMKIT_ENABLE_STREAMING
	; if we're in streaming mode, we basically ignore the eod
	; and assume there's valid ZSM data that's been fetched
	; for us immediately afterwards
	lda streaming_mode,x
	jne nextnote
.endif
	; if it's memory, we just repoint the pointer
	lda zsm_loop_bank,x
	sta zsm_ptr_bank,x
	lda zsm_loop_l,x
	sta zsm_ptr_l,x
	sta PTR
	lda zsm_loop_h,x
	sta zsm_ptr_h,x
	sta PTR+1
	jmp note_loop
issync:
	and #$3f
	pha ; save count
	jsr advanceptr
	bcs plaerror2
	jsr getzsmbyte
	cmp #$02
	bcc isgensync
	jsr advanceptr
	bcs plaerror2
endsync:
	pla ; restore count
	dec
	dec
	bne issync
	jmp nextnote
savekey:
	sta SK
	and #$07
	ldx prio
	clc
	adc times_8,x
	tax
	lda #$00
SK = * -1
	sta opm_key_shadow,x
	bra back2ymblock
isgensync:
	adc #2 ; sync message 2 or 3
	tay
	jsr advanceptr
	bcs plaerror2
	jsr getzsmbyte
	ldx prio
	jsr _callback
	bra endsync
ispcm:
	ldx prio
	pha ; save count
	jsr advanceptr
	bcs plaerror2
	jsr getzsmbyte
	beq ispcmctrl
	cmp #1
	beq ispcmrate
	; PCM trigger
	jsr advanceptr
	bcs error2
	jsr getzsmbyte
	jsr _pcm_trigger_instrument
endpcm:
	pla ; restore count
	dec
	dec
	bne ispcm
	jmp nextnote
plaerror2:
	pla
error2:
	jmp error
ispcmctrl:
	jsr advanceptr
	bcs error2
	jsr getzsmbyte
	sta pcm_ctrl_shadow,x
	cpx pcm_prio
	bne endpcm
	and #$0f
	sec
	sbc pcm_atten_shadow,x
	bpl :+
	lda #0
:	sta AV
	lda pcm_ctrl_shadow,x
	and #$80
	ora #$0f
AV = *-1
	sta AV
	lda Vera::Reg::AudioCtrl
	and #$30
	ora AV
	sta Vera::Reg::AudioCtrl
	bpl :+ ; if we just reset the fifo, the PCM channel is no longer busy
	stz pcm_busy
:	bra endpcm
ispcmrate:
	jsr advanceptr
	bcs error2
	jsr getzsmbyte
	sta pcm_rate_shadow,x
	cpx pcm_prio
	bne endpcm
	sta Vera::Reg::AudioRate
	bra endpcm

getzsmbyte:
	lda zsm_ptr_bank,x
	sta X16::Reg::RAMBank
	lda $ffff
PTR = *-2
	pha
	lda zsmkit_bank
	sta X16::Reg::RAMBank
	pla
	rts
advanceptr:
	inc PTR
	bne :+
	inc PTR+1
:	lda PTR+1
.ifdef ZSMKIT_ENABLE_STREAMING
	bit streaming_mode,x
	bpl @mem
	sta ringbuffer_start_h,x
	cmp ringbuffer_end_page,x
	bcc :+
	lda ringbuffer_start_page,x
	sta PTR+1
	sta ringbuffer_start_h,x
:   cmp ringbuffer_end_h,x
	bne :+
	lda PTR
	sta ringbuffer_start_l,x
	cmp ringbuffer_end_l,x
	rts
:	lda PTR
	sta ringbuffer_start_l,x
	clc
	rts
.endif
@mem:
	cmp #$c0
	bcc :+
	inc zsm_ptr_bank,x
	lda #$a0
	sta PTR+1
	clc
:	sta zsm_ptr_h,x
	lda PTR
	sta zsm_ptr_l,x
	rts

_psg_write:
	sta @PSGAVAL ; preserve value
	txa ; register
	lsr
	lsr ; now it's the voice number
	tay
	lda vera_psg_priority,y
	cmp prio
	bne :+
	lda #$ff ; restore value (self-mod)
@PSGAVAL = * - 1
	jmp psg_write_fast
:	rts

_ym_write:
	sta @OPMAVAL ; preserve value
	cpx #$08
	beq @key ; register 8 is key-off/key-on, and value => voice
	cpx #$0f
	beq @noi ; noise register belongs to whomever owns channel 7
	cpx #$20
	bcc @zero ; other registers < $20 are owned by prio 0
	txa ; >= $20 the voice is the low 3 bits of the register
@key:
	and #$07
	tay
@key1:
	lda opm_priority,y
@cz:
	cmp prio
	bne @skip
	lda #$ff ; restore value (self-mod)
@OPMAVAL = * - 1
	jmp ym_write
@zero:
	lda #0
	bra @cz
@noi:
	ldy #$07
	bra @key1
@skip:
	rts
.endproc

TEST_REGISTER = _prio_tick::TEST_REGISTER

;..............
; _callback   :
;============================================================================
; Arguments: .X = prio, .Y = type, .A = value
; Returns: (none)
; Preserves: .X
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; processes the callback
.proc _callback: near
	bit callback_enabled,x
	bpl nocb
	sta AVAL
	stx XVAL
	lda callback_addr_l,x
	sta CBL
	lda callback_addr_h,x
	sta CBH
	lda callback_bank,x
	sta X16::Reg::RAMBank
	lda #$00
AVAL = * - 1

	jsr $ffff
CBL = * - 2
CBH = * - 1
	lda zsmkit_bank
	sta X16::Reg::RAMBank
	ldx #$00
XVAL = * - 1
nocb:
	rts
.endproc

;............
; _reprio   :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; 
; processes any voice switch events that are needed chiefly due to songs no
; longer running, setting up for the reshadow
;
.proc _reprio: near
	lda recheck_priorities
	beq exit

	ldx #0
opmloop:
	ldy opm_priority,x
	cpy #NUM_PRIORITIES ; $fe or $ff, most likely
	bcs opmnext
	lda prio_playable,y
	beq opmswitch
	lda prio_active,y
	beq opmswitch
	lda times_8,y
	adc #<opm_voice_mask
	sta OVM
	lda #>opm_voice_mask
	adc #0
	sta OVM+1
	lda opm_voice_mask,x
OVM = * -2
	bne opmnext
opmswitch:
	lda #$80
	sta opm_restore_shadow,x
	dec opm_priority,x ; see if the next lower priority is active
	bra opmloop
opmnext:
	inx
	cpx #8
	bne opmloop

	ldx #0
psgloop:
	ldy vera_psg_priority,x
	cpy #NUM_PRIORITIES ; $fe or $ff, most likely
	bcs psgnext
	lda prio_playable,y
	beq psgswitch
	lda prio_active,y
	beq psgswitch
	lda times_16,y
	adc #<vera_psg_voice_mask
	sta PVM
	lda #>vera_psg_voice_mask
	adc #0
	sta PVM+1
	lda vera_psg_voice_mask,x
PVM = * -2
	bne psgnext
psgswitch:
	lda #$80
	sta vera_psg_restore_shadow,x
	dec vera_psg_priority,x ; see if the next lower priority is active
	bra psgloop
psgnext:
	inx
	cpx #16
	bne psgloop

	stz recheck_priorities
exit:
	rts
.endproc

;....................
; _opm_fast_release :
;============================================================================
; Arguments: Y = voice
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
.proc _opm_fast_release: near
	phy
	tya
	clc
	adc #$e0
	sta RR1
	adc #$08
	sta RR2
	adc #$08
	sta RR3
	adc #$08
	sta RR4

	; set release phase to $ff for this voice	
	lda #$ff
	ldx #$e0
RR4 = *-1
	jsr ym_write

	ldx #$e8
RR3 = *-1
	jsr ym_write

	ldx #$f0
RR2 = *-1
	jsr ym_write

	ldx #$f8
RR1 = *-1
	jsr ym_write

	; release voice
	pla
	jsr ym_release

	rts
.endproc

;............
; _reshadow :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; 
; processes any voice switch events that require reading from the shadow
; and applying the saved state to the sound chips
;
.proc _reshadow: near
	ldx #0
	stx voice

opmloop:
	lda opm_restore_shadow,x
	beq opmnext

	ldy voice
	jsr _opm_fast_release

	ldx voice
	lda opm_priority,x
	cmp #NUM_PRIORITIES
	bcs opmnext ; this happens immediately after a voice stops but no other song is taking over

	; reshadow all parameters
	ldy voice
	ldx opm_priority,y

	lda times_8,x
	adc #<opm_atten_shadow
	sta OASR
	lda #>opm_atten_shadow
	adc #0
	sta OASR+1

	lda opm_priority,y	

	clc
	adc #>opm_shadow
	sta OH
	sta OH7

	; restore noise enable / nfreq
	; shadow for our prio if it's in voice 7
	cpy #7
	bne not7
	lda opm_shadow+$0f
OH7 = * - 1
	ldx #$0f
	jsr ym_write

not7:
	lda #$20
	clc
	adc voice
	tax
shopmloop:
	lda opm_shadow,x
OH = * - 1
	jsr ym_write
	txa
	clc
	adc #$08
	tax
	bcc shopmloop

	ldy voice
	ldx opm_atten_shadow,y
OASR = *-2
	tya
	jsr ym_setatten
opmnext:
	ldx voice
	stz opm_restore_shadow,x
	inx
	stx voice
	cpx #8
	jcc opmloop


	ldx #0
	stx voice
psgloop:
	lda vera_psg_restore_shadow,x
	beq psgnext

	txa
	ldx #0
	jsr psg_setvol
	ldx voice

	lda vera_psg_priority,x
	cmp #NUM_PRIORITIES
	bcs psgnext ; this happens immediately after a voice stops but no other song is taking over

	tax
	lda times_64,x
	adc #<vera_psg_shadow
	sta PL
	lda #>vera_psg_shadow
	adc #0
	sta PL+1

	ldy voice
	ldx vera_psg_priority,y

	lda times_16,x
	clc
	adc #<vera_psg_atten_shadow
	sta PASR
	lda #>vera_psg_atten_shadow
	adc #0
	sta PASR+1

	lda voice
	asl
	asl
	tax
	ldy #4
shpsgloop:
	phy
	lda vera_psg_shadow,x
PL = *-2
	jsr psg_write_fast
	ply
	inx
	dey
	bne shpsgloop

	ldy voice
	ldx vera_psg_atten_shadow,y
PASR = *-2
	tya
	jsr psg_setatten

psgnext:
	ldx voice
	stz vera_psg_restore_shadow,x
	inx
	stx voice
	cpx #16
	bcc psgloop

	rts
voice:
	.byte 0
.endproc


;...............
; zsm_getstate :
;============================================================================
; Arguments: .X = priority
; Returns: .C set if playing, .Z set if not playable, .A .Y (lo hi) loop number
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Gets the current song state
;
.proc zsm_getstate: near
	PRESERVE_BANK_CLOBBER_A_P

	lda prio_active,x
	cmp #$01
	lda prio_playable,x
	php

	lda loop_number_l,x
	ldy loop_number_h,x
	
	tax
	RESTORE_BANK
	txa
	plp

	rts
.endproc

;..............
; zsm_setcb :
;============================================================================
; Arguments: .X = priority, .A .Y (lo hi) of callback address
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the callback address for the priority
; This will get called whenever the song ends on its own or loops
;
.proc zsm_setcb: near
	pha
	lda X16::Reg::RAMBank
	sta BK
	PRESERVE_BANK_CLOBBER_A_P
	pla

	stz callback_enabled,x

	sta callback_addr_l,x
	tya
	sta callback_addr_h,x

	lda #$00
BK = * - 1
	sta callback_bank,x

	lda #$80
	sta callback_enabled,x

	RESTORE_BANK
	rts
.endproc


;..............
; zsm_clearcb :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Clears the callback
.proc zsm_clearcb: near
	PRESERVE_BANK_CLOBBER_A_P

	stz callback_enabled,x

	RESTORE_BANK
	rts
.endproc

;..................
; zsm_set_intrate :
;============================================================================
; Arguments: .A = rate (integer part), .Y fractional part (1/256ths)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the global interrupt rate that ZSMKit will expect ticks
.proc zsm_set_int_rate: near
	pha
	PRESERVE_BANK_CLOBBER_A_P
	pla
	sta int_rate
	sty int_rate_frac

	ldx #(NUM_PRIORITIES-1)

@1:
	lda prio_playable,x
	beq @2
	php
	sei

	jsr _calculate_speed

	plp
@2:	dex
	bpl @1


	RESTORE_BANK
	rts
.endproc


;..............
; zsm_setrate :
;============================================================================
; Arguments: .X = priority, .A .Y (lo hi) of tick rate
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the current tick rate of the song.
.proc zsm_setrate: near
	pha
	PRESERVE_BANK_CLOBBER_A_P
	pla
	sta tick_rate_l,x
	tya
	sta tick_rate_h,x

	php
	sei

	jsr _calculate_speed

	plp

	RESTORE_BANK
	rts
.endproc


;..............
; zsm_getrate :
;============================================================================
; Arguments: .X = priority
; Returns: .A .Y (lo hi) of tick rate
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Returns the current tick rate of the song.
.proc zsm_getrate: near
	PRESERVE_BANK_CLOBBER_A_P
	lda tick_rate_l,x
	ldy tick_rate_h,x

	pha
	RESTORE_BANK
	pla
	rts
.endproc


;..............
; zsm_setloop :
;============================================================================
; Arguments: .X = priority, .C = boolean
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the priority to loop if carry is set, if clear, disables looping
.proc zsm_setloop: near
	php
	PRESERVE_BANK_CLOBBER_A_P
	lda #$80
	plp
	bcs :+
	lda #$00
	sta loop_enable,x

	RESTORE_BANK
	rts
.endproc

;............
; _opmatten :
;============================================================================
; Arguments: .X = priority, .A = value, .Y = channel
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; Sets the OPM attenuation value of a voice/prio.  $00 = full volume, $3F = muted
.proc _opmatten: near
	cmp #$3f
	bcc :+
	lda #$7f
	sta VAL
	bra bounds_checked
:	sta V1
	lsr
	sta VAL
	lda #$00
V1 = * - 1
	sec
	sbc VAL
	sta VAL

bounds_checked:
	stx PRI

	lda times_8,x
	adc #<opm_atten_shadow
	sta OAS
	lda #>opm_atten_shadow
	adc #0
	sta OAS+1

	lda opm_priority,y
	cmp #$00
PRI = * - 1
	bne :+
	ldx #$00
VAL = * - 1

	lda X16::Reg::ROMBank
	pha
	lda #$0a
	sta X16::Reg::ROMBank

	tya
	phy
	jsr ym_setatten
	ply 

	pla
	sta X16::Reg::ROMBank

:	lda VAL
	sta opm_atten_shadow,y
OAS = * -2

	rts

.endproc

;...............
; zsm_opmatten :
;============================================================================
; Arguments: .X = priority, .A = value, .Y = channel
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the OPM attenuation value of a channel/prio.  $00 = full volume, $3F = muted
.proc zsm_opmatten: near
	php
	pha
	PRESERVE_BANK_CLOBBER_A_P
	pla

	sei
	jsr _opmatten
end:
	plp
	RESTORE_BANK
	rts	
.endproc

;............
; _psgatten :
;============================================================================
; Arguments: .X = priority, .A = value, .Y = channel
; Returns: (none)
; Preserves: .Y
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; Sets the PSG attenuation value of a channel/prio.  $00 = full volume, $3F = muted
.proc _psgatten: near
	cmp #$3f
	bcc :+
	lda #$3f
:	sta VAL
	stx PRI

	lda times_16,x
	clc
	adc #<vera_psg_atten_shadow
	sta PAS
	lda #>vera_psg_atten_shadow
	adc #0
	sta PAS+1

	lda vera_psg_priority,y
	cmp #$00
PRI = * - 1
	bne :+
	ldx #$00
VAL = * - 1

	lda X16::Reg::ROMBank
	pha
	lda #$0a
	sta X16::Reg::ROMBank

	tya
	phy
	jsr psg_setatten
	ply

	pla
	sta X16::Reg::ROMBank

:	lda VAL
	sta vera_psg_atten_shadow,y
PAS = *-2
	rts
.endproc

;...............
; zsm_psgatten :
;============================================================================
; Arguments: .X = priority, .A = value, .Y = channel
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the PSG attenuation value of a channel/prio.  $00 = full volume, $3F = muted
.proc zsm_psgatten: near
	php
	pha
	PRESERVE_BANK_CLOBBER_A_P
	pla

	sei
	jsr _psgatten
end:
	plp
	RESTORE_BANK
	rts	
.endproc

;............
; _pcmatten :
;============================================================================
; Arguments: .X = priority, .A = value
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; Sets the PCM attenuation value of a song.  $00 = full volume, $3F = muted
.proc _pcmatten: near
	cmp #$3f
	bcc :+
	lda #$3f
:	lsr
	lsr
	sta pcm_atten_shadow,x
	cpx pcm_prio
	bne end

	lda pcm_ctrl_shadow,x
	and #$0f
	sec
	sbc pcm_atten_shadow,x
	bpl :+
	lda #0
:	sta NV
	lda Vera::Reg::AudioCtrl
	and #$30
	ora #$0f
NV = * -1
	sta Vera::Reg::AudioCtrl
end:
	rts
.endproc

;...............
; zsm_pcmatten :
;============================================================================
; Arguments: .X = priority, .A = value
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the PCM attenuation value of a song.  $00 = full volume, $3F = muted
.proc zsm_pcmatten: near
	php
	pha
	PRESERVE_BANK_CLOBBER_A_P
	pla

	sei
	jsr _pcmatten
end:
	plp
	RESTORE_BANK
	rts	
.endproc

;...............
; zsm_setatten :
;============================================================================
; Arguments: .X = priority, .A = value
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the attenuation value of a song.  $00 = full volume, $3F = muted
.proc zsm_setatten: near
	; psg steps are 0.5dB
	; pcm steps average 1.2dB but for simplicity we're treating them as 2dB
	; opm steps are 0.75dB
	sta val
	stx prio

	PRESERVE_BANK_CLOBBER_A_P

	php ; protect critical section
	sei

; PCM
	lda val
	jsr _pcmatten

dopsg:
	ldy #0
psgloop:

	ldx prio
	lda val
	jsr _psgatten

	iny
	cpy #16
	bne psgloop

	ldy #0
opmloop:

	ldx prio
	lda val

	jsr _opmatten

	iny
	cpy #8
	bne opmloop

	plp

exit:
	RESTORE_BANK
	rts
prio:
	.byte 0
val:
	.byte 0
.endproc

;.............
; zsm_rewind :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; stops playback if necessary and resets the song pointer to the beginning
;
.proc zsm_rewind: near
	stx prio
	PRESERVE_BANK_CLOBBER_A_P
	lda prio_active,x
	beq :+
	RESTORE_BANK
	jsr zsm_stop
	PRESERVE_BANK_CLOBBER_A_P
	ldx prio
:
.ifdef ZSMKIT_ENABLE_STREAMING
	lda streaming_mode,x
	beq memory
	stz prio_playable,x
	stz streaming_finished,x
	jsr _open_and_parse

	ldx prio
	bra cont
.endif
memory:	
	lda zsm_start_l,x
	sta zsm_ptr_l,x
	lda zsm_start_h,x
	sta zsm_ptr_h,x
	lda zsm_start_bank,x
	sta zsm_ptr_bank,x	
cont:
	stz delay_f,x
	stz delay_l,x
	stz delay_h,x

	stz loop_number_h,x
	stz loop_number_l,x
	RESTORE_BANK
	rts
prio:
	.byte 0
.endproc


;............
; zsm_close :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; closes streaming songs, sets priority to unused/not playable
;
.proc zsm_close: near
	stx prio
	PRESERVE_BANK_CLOBBER_A_P
	lda prio_active,x
	beq :+
	RESTORE_BANK
	jsr zsm_stop
	PRESERVE_BANK_CLOBBER_A_P
	ldx prio
:
.ifdef ZSMKIT_ENABLE_STREAMING
	lda streaming_mode,x
	beq :+
	lda streaming_lfn_sa,x
	jsr X16::Kernal::CLOSE
	ldx prio
	stz streaming_finished,x
:	
.endif
	stz prio_playable,x

	RESTORE_BANK
	rts
prio:
	.byte 0
.endproc

;...........
; zsm_stop :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Stops or pauses a song priority.  For in-memory songs, nothing else is needed
; for cleanup.  For streaming priorities, the file is held open until `zsm_close`
; is called
.proc zsm_stop: near
	PRESERVE_BANK_CLOBBER_A_P
	lda X16::Reg::ROMBank
	pha
	lda #$0a
	sta X16::Reg::ROMBank
	php ; mask interrupts while we clean up
	sei

	lda prio_active,x
	beq exit

	jsr _stop_sound
exit:
	plp ; restore interrupt mask state
	pla
	sta X16::Reg::ROMBank
	RESTORE_BANK
	rts
.endproc


;..............
; _stop_sound :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; stops sound on all channels in the current priority, used by zsm_stop
; and in the tick routine if a streaming song runs out of data
; or if EOD is otherwise reached
.proc _stop_sound: near
	stx PR

	ldy #0
psgloop:
	lda vera_psg_priority,y
	cmp #$00
PR = * - 1
	bne psgnext
	phy
	tya
	ldx #0
	jsr psg_setvol
	ply
psgnext:
	iny
	cpy #16
	bne psgloop

	ldy #0
opmloop:
	lda opm_priority,y
	cmp PR
	bne opmnext
	phy
	jsr _opm_fast_release
	ply
opmnext:
	iny
	cpy #8
	bne opmloop

	ldx PR
	cpx pcm_prio
	bne no_pcm_halt
	lda Vera::Reg::AudioCtrl
	and #$3f
	ora #$80
	sta Vera::Reg::AudioCtrl
	stz pcm_busy
no_pcm_halt:
	stz prio_active,x
	lda #$80
	sta recheck_priorities

	rts
.endproc


;...........
; zsm_play :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets up the song to start playing back on the next tick if
; the song is valid and ready to play
.proc zsm_play: near
	PRESERVE_BANK_CLOBBER_A_P
	lda prio_active,x
	bne exit ; already playing

	lda prio_playable,x
	beq exit

.ifdef ZSMKIT_ENABLE_STREAMING
	lda streaming_finished,x
	bne exit

	lda streaming_mode,x
	bne ok
.endif

	lda zsm_ptr_bank,x
	bne ok
	lda zsm_ptr_h,x
	cmp #$A0
	bcc exit
ok:
	stx prio
	; prevent interrupt during critical section
	php
	sei

	; check to see if we restore shadow from somewhere active next tick
	; opm voices
	ldy times_8,x
	ldx #0
opmloop:
	lda opm_voice_mask,y
	beq nextopm
	lda opm_priority,x
	cmp #$ff
	beq opmvoice
	cmp prio
	bcs nextopm
opmvoice:
	lda #$80
	sta opm_restore_shadow,x
	lda prio
	sta opm_priority,x
nextopm:
	iny
	inx
	cpx #8
	bcc opmloop

	; psg voices
	ldx prio
	ldy times_16,x
	ldx #0
psgloop:
	lda vera_psg_voice_mask,y
	beq nextpsg
	lda vera_psg_priority,x
	cmp #$ff
	beq psgvoice
	cmp prio
	bcs nextpsg
psgvoice:
	lda #$80
	sta vera_psg_restore_shadow,x
	lda prio
	sta vera_psg_priority,x
nextpsg:
	iny
	inx
	cpx #16
	bcc psgloop

	; indicate prio is now active
	ldx prio
	lda #$80
	sta prio_active,x

.ifdef ZSMKIT_ENABLE_STREAMING
	jsr zsm_fill_buffers
.endif

	plp ; end critical section
exit:
	RESTORE_BANK
	rts
prio:
	.byte 0
.endproc

.ifdef ZSMKIT_ENABLE_STREAMING
;...................
; zsm_fill_buffers :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; If the priority has a song being streamed from a file, top the ring buffer
; off if appropriate. Must be called from the main loop since it deals with
; file I/O

.proc zsm_fill_buffers: near
	PRESERVE_BANK_CLOBBER_A_P
	ldx #(NUM_PRIORITIES-1)
loop:
	stx prio
	lda prio_active,x
	jeq next
	lda streaming_mode,x
	jeq next
	lda streaming_finished,x
	jne next
	lda streaming_reopen,x
	beq no_reopen

	jsr _open_zsm ; does not clobber x

	lda streaming_loop_point_l,x
	sta streaming_pos_l,x
	lda streaming_loop_point_m,x
	sta streaming_pos_m,x
	lda streaming_loop_point_h,x
	sta streaming_pos_h,x

	stz streaming_reopen,x
	jmp next
no_reopen:
	; find the amount of free ring buffer space
	lda ringbuffer_end_h,x
	cmp ringbuffer_start_h,x
	bcc mode2
mode1:
	; end is greater than or equal to start
	; (right boundary of load is high ring boundary)
	lda ringbuffer_start_h,x
	clc
	adc #(ringbuffer_end_page-ringbuffer_start_page)
	sta stop_before
	lda ringbuffer_end_page,x ; non-inclusive
	clc ; we're going to subtract one extra intentionally
	sbc ringbuffer_end_h,x
	beq shortpage
	lda #255 ; max less than one page
	bra check_eod
mode2:
	; start is greater than end
	; (right boundary of load is end of page one page before start)
	lda ringbuffer_start_h,x
	sta stop_before
	clc ; we're going to subtract one extra intentionally
	sbc ringbuffer_end_h,x
	beq shortpage
	lda #255 ; max less than one page
	bra check_eod
shortpage:
	; but first test if we need to skip the load entirely
	lda stop_before
	clc
	sbc ringbuffer_end_h,x
	bne :+
	lda ringbuffer_end_l,x
	jne next ; skip the load, not enough ring buffer
	lda #$ff
	bra check_eod
:	; read to the end of the page
	lda #$ff
	eor ringbuffer_end_l,x
	inc
	bne check_eod
	dec ; except when we'd ask for 256 bytes.  Ask for 255 instead
check_eod:
	sta tmp2 ; save requested byte count
	lda streaming_eod_l,x
	ora streaming_eod_m,x
	ora streaming_eod_h,x
	beq loadit ; we don't have an expected end-of-data
	lda streaming_pos_h,x
	cmp streaming_eod_h,x
	bcc loadit ; high byte is different, plenty of time
	lda streaming_eod_l,x
	; carry already set
	sbc streaming_pos_l,x
	sta tmp1
	lda streaming_eod_m,x
	sbc streaming_pos_m,x
	bne loadit ; med byte is at least 256 away
	lda tmp1
	beq check_if_loopable ; we are already at the end, 0 left
	cmp tmp2
	bcs loadit ; requested bytes < what we have left
	sta tmp2   ; we need exactly this many bytes to reach EOD
loadit:
	lda streaming_lfn_sa,x
	tax
	jsr X16::Kernal::CHKIN
	ldx prio
	ldy ringbuffer_end_h,x
	lda ringbuffer_end_l,x
	tax
	lda tmp2 ; restore requested byte count
	clc
	jsr X16::Kernal::MACPTR
	bcs error
	txa
	sta tmp1 ; store the number of bytes fetched
	ldx prio
	php ; mask interrupts while changing the lo/hi of end
	sei
	adc ringbuffer_end_l,x
	sta ringbuffer_end_l,x
	lda ringbuffer_end_h,x
	adc #0
	cmp ringbuffer_end_page,x ; non-inclusive
	bcc :+
	lda ringbuffer_start_page,x ; we wrap now
:	sta ringbuffer_end_h,x
	lda tmp1 ; restore the number of bytes fetched
	clc
	adc streaming_pos_l,x
	sta streaming_pos_l,x
	bcc :+
	inc streaming_pos_m,x
	bne :+
	inc streaming_pos_h,x
:	plp ; restore interrupt mask state
	; now check for EOI
	jsr X16::Kernal::READST
	and #$40
	beq check_enough
	; we reached EOI, re-seek next call if we loop
check_if_loopable:
	lda loop_enable,x
	beq finish
	lda #$80
	sta streaming_reopen,x
check_enough:
	jsr X16::Kernal::CLRCHN
	ldx prio
	sec
	lda ringbuffer_end_h,x
	sbc ringbuffer_start_h,x
	bcs :+
	adc #>RINGBUFFER_SIZE
:	cmp #$03
	jcc loop ; get more if start and end are not at least two pages apart
next:
	dex
	jpl loop
	RESTORE_BANK
	rts
error:
	; error is the same as finish
finish:
	jsr X16::Kernal::CLRCHN
	ldx prio
	lda streaming_lfn_sa,x
	jsr X16::Kernal::CLOSE
	ldx prio
	lda #$80
	sta streaming_finished,x

	bra next
prio:
	.byte 0
stop_before:
	.byte 0
.endproc

;.............
; zsm_setlfs :
;============================================================================
; Arguments: .A = lfn/sa, .X = priority, .Y = device
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the logical file number, secondary address, and IEC device
; for a particular priority
;
; Must only be called from main loop routines.
;
; Calling this function is not necessary if you wish to use defaults
; that have been set at engine init:
;
; Priority 0: lfn/sa 11, device 8
; Priority 1: lfn/sa 12, device 8
; Priority 2: lfn/sa 13, device 8
; Priority 3: lfn/sa 14, device 8
.proc zsm_setlfs: near
	PRESERVE_BANK_NO_CLOBBER
	sta streaming_lfn_sa,x
	tya
	sta streaming_dev,x
	RESTORE_BANK
	rts
.endproc

;..............
; zsm_setfile :
;============================================================================
; Arguments: .X = priority, .A .Y = null terminated filename pointer
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the filename for the priority, opens it, and parses the header
;
; Must only be called from main loop routines.
.proc zsm_setfile: near
	sta ZSF1
	sty ZSF1+1
	PRESERVE_BANK_CLOBBER_A_P

	stz prio_playable,x

	lda times_fn_max_length,x
	clc
	adc #<streaming_filename
	sta ZSF2
	lda #>streaming_filename
	adc #0
	sta ZSF2+1
	ldy #0
loop:
	lda $ffff,y
ZSF1 = *-2
	beq done
	sta $ffff,y
ZSF2 = *-2
	iny
	bne loop
done:
	tya
	sta streaming_filename_len,x
	stz pcm_table_exists,x

	jsr _zero_shadow

	jsr _open_and_parse
	RESTORE_BANK
	rts
.endproc

;..............
; zsm_loadpcm :
;============================================================================
; Arguments: .X = priority, .A .Y (lo hi) load address, $00 = load bank
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; For a streaming prio, loads the PCM data into RAM
.proc zsm_loadpcm: near
	sta AL
	sty AH
	lda X16::Reg::RAMBank
	sta BK
	PRESERVE_BANK_CLOBBER_A_P

	tya
	sta pcm_table_h,x
	lda AL
	sta pcm_table_l,x
	lda BK
	sta pcm_table_bank,x

	; ensure not playing
	lda prio_active,x
	jne end

	; ensure playable
	lda prio_playable,x
	jeq end

	; ensure streaming mode
	lda streaming_mode,x
	jeq end

	; ensure streaming not finished
	lda streaming_finished,x
	jne end

	stx PRI

	lda #$80
	sta PCME ; assume PCM will exist

	; seek to location containing PCM data offset
	lda streaming_lfn_sa,x
	sta seekpoint+1
	lda #6
	sta seekpoint+2
	stz seekpoint+3
	stz seekpoint+4

	jsr _seek
	jcs error

	ldy PRI
	ldx streaming_lfn_sa,y
	jsr X16::Kernal::CHKIN

	; seek to PCM data offset itself
	jsr X16::Kernal::BASIN
	sta seekpoint+2
	jsr X16::Kernal::BASIN
	sta seekpoint+3
	jsr X16::Kernal::BASIN
	sta seekpoint+4

	ora seekpoint+3
	ora seekpoint+2
	bne :+
	stz PCME ; no PCM section
	bra done
:	ldx PRI
	jsr _seek
	bcs error

	ldy PRI
	ldx streaming_lfn_sa,y
	jsr X16::Kernal::CHKIN

	lda #$00
BK = * - 1
	sta X16::Reg::RAMBank
loadloop:
	ldx #$00
AL = * - 1
	ldy #$00
AH = * - 1
	lda #$00
	clc
	jsr X16::Kernal::MACPTR
	bcs done

	stx CNTL
	sty CNTH
	txa
	adc AL
	sta AL
	tya
	adc AH
	cmp #$c0
	bcc :+
	sbc #$20
:	sta AH

	lda #$00
CNTL = * - 1
	ora #$00
CNTH = * - 1
	bne loadloop

done:
	jsr X16::Kernal::CLRCHN
	lda X16::Reg::RAMBank
	sta BK

	lda zsmkit_bank
	sta X16::Reg::RAMBank

	ldx PRI
	lda #$80
PCME = * - 1
	beq :+
	jsr _finalize_pcm_table

:	RESTORE_BANK
	jsr zsm_rewind
	lda BK
	sta X16::Reg::RAMBank
	lda AL
	ldy AH
	clc
	rts
end:
	RESTORE_BANK
	rts
error:
	ldx #$00
PRI = * - 1
	lda #$80
	sta streaming_finished,x
	sta recheck_priorities
	stz prio_playable,x
	sec	
	rts
.endproc


;..................
; _open_and_parse :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; internal function that opens the associated file and, and parses the header
;
; Must only be called from main loop routines.

.proc _open_and_parse: near
	stx prio

	stz streaming_loop_point_l,x
	stz streaming_loop_point_m,x
	stz streaming_loop_point_h,x

	jsr _open_zsm
	jcs error

	; parse header
	lda streaming_lfn_sa,x
	tax
	jsr X16::Kernal::CHKIN

	jsr X16::Kernal::BASIN
	cmp #$7a ; 'z'
	bne err2

	jsr X16::Kernal::BASIN
	cmp #$6d ; 'm'
	bne err2

	jsr X16::Kernal::BASIN
	cmp #1 ; expected version number
	beq noerr2
err2:
	jmp error
noerr2:

	; loop point
	ldx prio
	jsr X16::Kernal::BASIN
	sta streaming_loop_point_l,x
	jsr X16::Kernal::BASIN
	sta streaming_loop_point_m,x
	jsr X16::Kernal::BASIN
	sta streaming_loop_point_h,x

	; PCM offset
	jsr X16::Kernal::BASIN
	sta streaming_eod_l,x
	jsr X16::Kernal::BASIN
	sta streaming_eod_m,x
	jsr X16::Kernal::BASIN
	sta streaming_eod_h,x

	; FM channel mask
	jsr X16::Kernal::BASIN
	ldy prio
	ldx times_8,y
.repeat 8,i
	lsr
	stz opm_voice_mask+i,x
	ror opm_voice_mask+i,x
.endrepeat

	; PSG channel mask
	jsr X16::Kernal::BASIN
	ldx times_16,y
.repeat 8,i
	lsr
	stz vera_psg_voice_mask+i,x
	ror vera_psg_voice_mask+i,x
.endrepeat
	jsr X16::Kernal::BASIN
.repeat 8,i
	lsr
	stz vera_psg_voice_mask+i+8,x
	ror vera_psg_voice_mask+i+8,x
.endrepeat

	; ZSM tick rate
	jsr X16::Kernal::BASIN
	sta tick_rate_l,y
	jsr X16::Kernal::BASIN
	sta tick_rate_h,y

	; two reserved bytes
	jsr X16::Kernal::BASIN
	jsr X16::Kernal::BASIN

	jsr X16::Kernal::CLRCHN

	; finish setup of state
	ldx prio
	lda #16
	sta streaming_pos_l,x
	stz streaming_pos_m,x
	stz streaming_pos_h,x

	stz delay_f,x
	stz delay_l,x
	stz delay_h,x

	stz loop_number_h,x
	stz loop_number_l,x

	stz ringbuffer_start_l,x
	stz ringbuffer_end_l,x
	lda ringbuffer_start_page,x
	sta ringbuffer_start_h,x
	sta ringbuffer_end_h,x

	; non-zero loop point sets loop_enable
	lda streaming_loop_point_l,x
	ora streaming_loop_point_m,x
	ora streaming_loop_point_h,x
	cmp #1
	stz loop_enable,x
	ror loop_enable,x

	; if loop point is $000000, set it to $000010
	; just in case it is manually turned on
	bne :+
	lda #$10
	sta streaming_loop_point_l,x
:

	lda #$80
	sta streaming_mode,x
	sta prio_playable,x

	lda zsmkit_bank
	sta zsm_ptr_bank,x

	jsr _calculate_speed ; X = prio
	clc
exit:
	rts
error:
	jsr X16::Kernal::CLRCHN
	ldx prio
	lda streaming_lfn_sa,x
	jsr X16::Kernal::CLOSE
	ldx prio
	lda #$80
	sta streaming_finished,x
	sta recheck_priorities
	stz prio_playable,x
	sec
	rts
prio:
	.byte 0
.endproc

;............
; _open_zsm :
;============================================================================
; Arguments: .X = priority
; Returns: .C set for error
; Preserves: .X
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; This internal routine (re-)opens a ZSM file for use in streaming mode.
; If it's the first time the file is opened, streaming_loop_point_[lmh],x
; must be zeroed first so that the seek points to the beginning of the file. 
;
; Must only be called from main loop routines.
.proc _open_zsm: near

	stx prio ; save priority locally

	; make sure handle (lfn) is closed
	lda streaming_lfn_sa,x
	jsr X16::Kernal::CLOSE
	ldx prio


	ldy streaming_filename_len,x
	phy ; save filename length
	lda times_fn_max_length,x
	clc
	adc #<streaming_filename
	sta FP
	lda #>streaming_filename
	adc #0
	sta FP+1
	dey
fnloop:
	lda $ffff,y
FP = *-2
	sta buff,y
	dey
	bpl fnloop

	ldx #<buff
	ldy #>buff
	pla ; restore filename length
	jsr X16::Kernal::SETNAM

	ldx prio
	ldy streaming_lfn_sa,x
	lda streaming_dev,x
	tax
	tya
	jsr X16::Kernal::SETLFS

	jsr X16::Kernal::OPEN

	; seek to loop point
	ldx prio
	lda streaming_lfn_sa,x
	sta seekpoint+1
	lda streaming_loop_point_l,x
	sta seekpoint+2
	lda streaming_loop_point_m,x
	sta seekpoint+3
	lda streaming_loop_point_h,x
	sta seekpoint+4

	jsr _seek
	bcs error

	ldx prio
	clc
	rts
error:
	ldx prio
	lda #$80
	sta streaming_finished,x
	sec	
	rts
prio:
	.byte 0
.endproc

;........
; _seek :
;============================================================================
; Arguments: .X = priority
; Returns: .C set for error
; Preserves: (none
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
.proc _seek: near
	stx PRI
	lda #6
	ldx #<seekpoint
	ldy #>seekpoint

	jsr X16::Kernal::SETNAM

	ldx #$00
PRI = * - 1
	lda streaming_dev,x
	tax
	lda #15
	tay
	jsr X16::Kernal::SETLFS

	jsr X16::Kernal::OPEN

	ldx #15
	jsr X16::Kernal::CHKIN
	jsr X16::Kernal::BASIN
	pha ; preserve byte read
	jsr X16::Kernal::READST
	and #$40
	bne errorp
	pla ; restore byte read from command channel
	beq errord
	cmp #'0'
	bne error
eat:
	jsr X16::Kernal::BASIN
	jsr X16::Kernal::READST
	and #$40
	beq eat

	jsr X16::Kernal::CLRCHN
	lda #15
	jsr X16::Kernal::CLOSE
	clc
	rts
errord:
	dec
	pha
errorp:
	ply
error:
	jsr eat
	sec
	rts
.endproc
.endif

;.............
; zsm_setmem :
;============================================================================
; Arguments: .X = priority, .A .Y = data pointer, $00 = ram bank
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the start of memory for the priority, reads it,
; and parses the header
;
; Must only be called from main loop routines.
.proc zsm_setmem: near
	sta ZM1
	sta buff+16
	sty ZM1+1
	sty buff+17
	lda X16::Reg::RAMBank
	sta buff+18

	PRESERVE_BANK_CLOBBER_A_P

	stx prio
	lda prio_active,x
	beq :+

	RESTORE_BANK

	jsr zsm_close ; will also stop
:	RESTORE_BANK
	ldy #0
hdrloop: ; copy the header to our low ram buffer
	lda $ffff
ZM1 = *-2
	sta buff,y
	inc ZM1
	bne :+
	inc ZM1+1
:	lda ZM1+1
	cmp #$c0
	bcc :+
	sbc #$20
	sta ZM1+1
	inc X16::Reg::RAMBank
:	iny
	cpy #16
	bcc hdrloop

	ldy zsmkit_bank ; switch back to our bank and copy the values out of the buffer into the state
	sty X16::Reg::RAMBank

	ldx prio
	lda buff+18
	sta zsm_start_bank,x
	sta zsm_ptr_bank,x
	lda ZM1
	sta zsm_start_l,x
	sta zsm_ptr_l,x
	lda ZM1+1
	sta zsm_start_h,x
	sta zsm_ptr_h,x

	lda buff
	cmp #$7a ; 'z'
	bne err1

	lda buff+1
	cmp #$6d ; 'm'
	bne err1

	lda buff+2 ; version (1)
	cmp #1
	beq noerr1

err1:
	stz prio_playable,x
	sec
	rts

noerr1:

	lda buff+5 ; loop point [23:16]
	asl        ; each of these is
	asl        ; worth 64 k
	asl        ; or 8 banks
	clc
	adc buff+18 ; start bank
	sta zsm_loop_bank,x

	lda buff+4 ; loop point [15:8]
	lsr        ; each of these
	lsr        ; is worth a page
	lsr        ; and 32 of them
	lsr        ; is worth
	lsr        ; one 8k bank
	clc
	adc zsm_loop_bank,x
	sta zsm_loop_bank,x

	lda buff+4 ; keep the remainder
	and #$1f   ; which when added to the start
	sta buff+19 ; will be < $ff

	lda buff+3 ; loop point [7:0]
	clc
	adc buff+16 ; start of zsm data (LSB)
	sta zsm_loop_l,x
	lda buff+19 ; loop point [12:8]
	adc buff+17 ; start of zsm data (MSB)
:	cmp #$c0    ; if we're past
	bcc :+
	sbc #$20    ; subtract $20
	inc zsm_loop_bank,x ; and increment bank
	bra :-
:	sta zsm_loop_h,x ; and we're done figuring out the loop point


	lda buff+3  ; but do we even loop at all?
	ora buff+4
	ora buff+5
	cmp #1
	stz loop_enable,x
	ror loop_enable,x

	; if loop point is $000000, set it to $000010
	; just in case it is manually turned on
	bne has_loop
	lda #$10
	adc zsm_loop_l,x
	sta zsm_loop_l,x
	lda zsm_loop_h,x
	adc #0
	cmp #$c0
	bcc :+
	sbc #$20
	inc zsm_loop_bank,x
:	sta zsm_loop_h,x
has_loop:

	stz pcm_table_exists,x
	lda buff+8
	ora buff+7
	ora buff+6
	beq nopcm

	; buff offset 6 7 8 (PCM offset)
	lda buff+8 ; PCM offset [23:16]
	asl        ; each of these is
	asl        ; worth 64 k
	asl        ; or 8 banks
	clc
	adc buff+18 ; start bank
	sta pcm_table_bank,x

	lda buff+7 ; PCM offset [15:8]
	lsr        ; each of these
	lsr        ; is worth a page
	lsr        ; and 32 of them
	lsr        ; is worth
	lsr        ; one 8k bank
	clc
	adc pcm_table_bank,x
	sta pcm_table_bank,x	

	lda buff+7 ; keep the remainder
	and #$1f   ; which when added to the start
	sta buff+19 ; will be < $ff

	lda buff+6 ; PCM offset [7:0]
	clc
	adc buff+16 ; start of zsm data (LSB)
	sta pcm_table_l,x
	lda buff+19 ; PCM offset [12:8]
	adc buff+17 ; start of zsm data (MSB)
:	cmp #$c0    ; if we're past
	bcc :+
	sbc #$20    ; subtract $20
	inc pcm_table_bank,x ; and increment bank
	bra :-
:	sta pcm_table_h,x ; and we're done figuring out the PCM table location

	jsr _finalize_pcm_table
nopcm:
	; FM channel mask
	lda buff+9
	ldy prio
	ldx times_8,y
.repeat 8,i
	lsr
	stz opm_voice_mask+i,x
	ror opm_voice_mask+i,x
.endrepeat

	; PSG channel mask
	lda buff+10
	ldx times_16,y
.repeat 8,i
	lsr
	stz vera_psg_voice_mask+i,x
	ror vera_psg_voice_mask+i,x
.endrepeat
	lda buff+11
.repeat 8,i
	lsr
	stz vera_psg_voice_mask+i+8,x
	ror vera_psg_voice_mask+i+8,x
.endrepeat

	; ZSM tick rate
	lda buff+12
	sta tick_rate_l,y
	lda buff+13
	sta tick_rate_h,y

	; 14 and 15 are reserved bytes
	; finish setup of state
	ldx prio
	stz delay_f,x
	stz delay_l,x
	stz delay_h,x

	stz loop_number_h,x
	stz loop_number_l,x

.ifdef ZSMKIT_ENABLE_STREAMING
	stz streaming_mode,x
.endif
	lda #$80
	sta prio_playable,x

	jsr _zero_shadow

	jsr _calculate_speed

	RESTORE_BANK
	rts
prio:
	.byte 0
.endproc

;...............
; _zero_shadow :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: .X
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
.proc _zero_shadow: near
	phx

	lda #0
	ldy times_16,x
	ldx #64
:	sta vera_psg_shadow,y
	iny
	dex
	bne :-

	plx
	phx

	lda #0
	ldy times_8,x
	ldx #8
:	sta opm_key_shadow,y
	iny
	dex
	bne :-

	plx
	rts
.endproc

;...................
; _calculate_speed :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: .X
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; performs the calculation tick_rate_*/60 and stores in speed_*
;
.proc _calculate_speed: near
	stx prio
	; set speed to 60 if ZSM says it's zero
	lda tick_rate_l,x
	ora tick_rate_h,x
	bne :+
	lda #60
	sta tick_rate_l,x
:	
	; initialize remainder to 0
	stz tmp1
	stz tmp1+1
	; dividend = tick_rate*65536
	; so that the quotient is a 16.8 fixed point result
	stz tmp2
	stz tmp2+1
	lda tick_rate_l,x
	sta tmp2+2
	lda tick_rate_h,x
	sta tmp2+3
	; initialize divisor to int_rate (default 60.0)
	lda int_rate_frac
	sta tmp3
	lda int_rate
	sta tmp3+1

	; 32 bits in the dividend
	ldx #32
l1:
	asl tmp2
	rol tmp2+1
	rol tmp2+2
	rol tmp2+3
	rol tmp1
	rol tmp1+1
	lda tmp1
	sec
	sbc tmp3
	tay
	lda tmp1+1
	sbc tmp3+1
	bcc l2
	sta tmp1+1
	sty tmp1
	inc tmp2
l2:
	dex
	bne l1

	ldx prio
	lda tmp2
	sta speed_f,x
	lda tmp2+1
	sta speed_l,x
	lda tmp2+2
	sta speed_h,x

	rts
prio:
	.byte 0
.endproc

get_next_byte:
	lda $ffff
PT = *-2
	inc PT
	bne gnb2
	inc PT+1
validate_pt:
	pha
	lda PT+1
	cmp #$c0
	bcc gnb1
	sbc #$20
	sta PT+1
	inc X16::Reg::RAMBank
gnb1:
	pla
gnb2:
	rts

get_next_byte_irq:
	lda $ffff
PTI = *-2
	inc PTI
	bne gnb2
	inc PTI+1
validate_pt_irq:
	pha
	lda PTI+1
	cmp #$c0
	bcc gnb1
	sbc #$20
	sta PTI+1
	inc X16::Reg::RAMBank
	rts

seekpoint:
	.byte 'P', $00, $00, $00, $00, $00

.ifdef ZSMKIT_ENABLE_STREAMING
ringbuffer_start_page:
.repeat NUM_PRIORITIES, i
	.byte $A0+(i*(RINGBUFFER_SIZE >> 8))
.endrepeat

ringbuffer_end_page: ; non-inclusive
.repeat NUM_PRIORITIES, i
	.byte $A0+((i+1)*(RINGBUFFER_SIZE >> 8))
.endrepeat
.endif

times_fn_max_length:
.repeat NUM_PRIORITIES, i
	.byte i*FILENAME_MAX_LENGTH
.endrepeat

times_8:
.repeat NUM_PRIORITIES, i
	.byte i*8
.endrepeat

times_16:
.repeat NUM_PRIORITIES, i
	.byte i*16
.endrepeat

times_64:
.repeat NUM_PRIORITIES, i
	.byte i*64
.endrepeat

; ZSound-derived FIFO-fill LUTs
pcmrate_fast: ; <<4 for 16+stereo, <<3 for 16|stereo, <<2 for 8+mono
	.byte $03,$04,$06,$07,$09,$0B,$0C,$0E,$10,$11,$13,$15,$16,$17,$19,$1A
	.byte $1C,$1E,$1F,$21,$22,$24,$26,$27,$29,$2A,$2C,$2E,$2F,$31,$33,$34
	.byte $36,$37,$39,$3B,$3C,$3E,$3F,$41,$43,$44,$46,$47,$49,$4B,$4C,$4E
	.byte $50,$51,$53,$54,$56,$58,$59,$5B,$5C,$5E,$60,$61,$63,$65,$66,$68
	.byte $69,$6B,$6D,$6E,$70,$71,$73,$75,$76,$78,$79,$7B,$7D,$7E,$80,$82
	.byte $83,$85,$86,$88,$8A,$8B,$8D,$8E,$90,$92,$93,$95,$97,$98,$9A,$9B
	.byte $9D,$9F,$A0,$A2,$A3,$A5,$A7,$A8,$AA,$AC,$AD,$AF,$B0,$B2,$B4,$B5
	.byte $B7,$B8,$BA,$BC,$BD,$BF,$C0,$C2,$C4,$C5,$C7,$C9,$CA,$CC,$CD,$CF

pcmrate_slow:
	.byte $01,$02,$04,$05,$07,$09,$0A,$0C,$0E,$0F,$11,$12,$14,$16,$17,$19
	.byte $1A,$1C,$1E,$1F,$21,$22,$24,$26,$27,$29,$2A,$2C,$2E,$2F,$31,$32
	.byte $34,$36,$37,$39,$3A,$3C,$3D,$3F,$41,$42,$44,$45,$47,$49,$4A,$4C
	.byte $4D,$4F,$51,$52,$54,$55,$57,$58,$5A,$5C,$5D,$5F,$60,$62,$64,$65
	.byte $67,$68,$6A,$6C,$6D,$6F,$70,$72,$74,$75,$77,$78,$7A,$7B,$7D,$7F
	.byte $80,$82,$83,$85,$87,$88,$8A,$8B,$8D,$8F,$90,$92,$93,$95,$96,$98
	.byte $9A,$9B,$9D,$9E,$A0,$A2,$A3,$A5,$A6,$A8,$AA,$AB,$AD,$AE,$B0,$B1
	.byte $B3,$B5,$B6,$B8,$BA,$BC,$BE,$BF,$C1,$C2,$C4,$C6,$C7,$C9,$CA,$CC
