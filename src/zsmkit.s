.include "x16.inc"
.include "audio.inc"
.include "macros.inc"

.import __ZSMKIT_LOWRAM_LOAD__, __ZSMKIT_LOWRAM_SIZE__

.macpack longbranch

ZSMKIT_VERSION = $0203

NUM_ZCM_SLOTS = 32
NUM_PRIORITIES = 8
NUM_OPM_PRIORITIES = 4

PTR = $02 ; temporary ZP used for indirect addressing, preserved and restored

.segment "JMPTBL"
jmp zsm_init_engine      ; $A000
jmp zsm_tick             ; $A003
jmp zsm_play             ; $A006
jmp zsm_stop             ; $A009
jmp zsm_rewind           ; $A00C
jmp zsm_close            ; $A00F
jmp zsm_getloop          ; $A012
jmp zsm_getptr           ; $A015
jmp zsm_getksptr         ; $A018
jmp zsm_setbank          ; $A01B
jmp zsm_setmem           ; $A01E
jmp zsm_setatten         ; $A021
jmp zsm_setcb            ; $A024
jmp zsm_clearcb          ; $A027
jmp zsm_getstate         ; $A02A
jmp zsm_setrate          ; $A02D
jmp zsm_getrate          ; $A030
jmp zsm_setloop          ; $A033
jmp zsm_opmatten         ; $A036
jmp zsm_psgatten         ; $A039
jmp zsm_pcmatten         ; $A03C
jmp zsm_set_int_rate     ; $A03F
jmp zsm_getosptr         ; $A042
jmp zsm_getpsptr         ; $A045
jmp zcm_setbank          ; $A048
jmp zcm_setmem           ; $A04B
jmp zcm_play             ; $A04E
jmp zcm_stop             ; $A051
jmp zsmkit_setisr        ; $A054
jmp zsmkit_clearisr      ; $A057
jmp zsmkit_version       ; $A05A
jmp zsm_set_ondeck_bank  ; $A05D
jmp zsm_set_ondeck_mem   ; $A060
jmp zsm_clear_ondeck     ; $A063

.segment "ZSMKITBSS"
_ZSM_BSS_START := *

; offset = priority*256
opm_shadow:             .res NUM_OPM_PRIORITIES*256

; offset = (priority * 64) + (register)
vera_psg_shadow:        .res NUM_PRIORITIES*64

; offset = (priority * 8) + (voice)
opm_atten_shadow:       .res NUM_OPM_PRIORITIES*8

; offset = (priority * 8) + (voice)
opm_key_shadow:			.res NUM_OPM_PRIORITIES*8

; offset = (priority * 16) + (voice)
vera_psg_atten_shadow:  .res NUM_PRIORITIES*16

pcm_ctrl_shadow:        .res NUM_PRIORITIES
pcm_rate_shadow:        .res NUM_PRIORITIES
pcm_atten_shadow:       .res NUM_PRIORITIES

; These two arrays are set via properties on the ZSM
; based on which voices are used.  If the priority slot
; is not active, these are zeroed.

; offset = (priority * 8) + (voice)
; allocating more than we need to reduce code complexity
opm_voice_mask:         .res NUM_PRIORITIES*8*2

; offset = (priority * 16) + (voice)
vera_psg_voice_mask:    .res NUM_PRIORITIES*16*2

; Is the song playing? Nonzero is truth.
; offset = (priority)
prio_active:            .res NUM_PRIORITIES

; Does the song have a configured on-deck
; assignment? Non-zero is true
prio_ondeck:            .res NUM_PRIORITIES

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

; The bank and offset of the beginning of
; the song, loop point, and of the current pointer
; offset = (priority)
zsm_start_bank:         .res NUM_PRIORITIES*2
zsm_start_l:            .res NUM_PRIORITIES*2
zsm_start_h:            .res NUM_PRIORITIES*2

zsm_loop_bank:          .res NUM_PRIORITIES*2
zsm_loop_l:             .res NUM_PRIORITIES*2
zsm_loop_h:             .res NUM_PRIORITIES*2

zsm_ptr_bank:           .res NUM_PRIORITIES
zsm_ptr_l:              .res NUM_PRIORITIES
zsm_ptr_h:              .res NUM_PRIORITIES

loop_enable:            .res NUM_PRIORITIES*2

loop_number_l:          .res NUM_PRIORITIES
loop_number_h:          .res NUM_PRIORITIES

; Hz (from file)
tick_rate_l:            .res NUM_PRIORITIES*2
tick_rate_h:            .res NUM_PRIORITIES*2

; speed (Hz/60) - delays to subtract per tick
speed_f:                .res NUM_PRIORITIES
speed_l:                .res NUM_PRIORITIES
speed_h:                .res NUM_PRIORITIES

; delay (playback state)
delay_f:                .res NUM_PRIORITIES
delay_l:                .res NUM_PRIORITIES
delay_h:                .res NUM_PRIORITIES

; if exists, points to the PCM instrument table in RAM
pcm_table_exists:       .res NUM_PRIORITIES*2
pcm_table_bank:         .res NUM_PRIORITIES*2
pcm_table_l:            .res NUM_PRIORITIES*2
pcm_table_h:            .res NUM_PRIORITIES*2

pcm_inst_max:           .res NUM_PRIORITIES*2

pcm_data_bank:          .res NUM_PRIORITIES*2
pcm_data_l:             .res NUM_PRIORITIES*2
pcm_data_h:             .res NUM_PRIORITIES*2

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
; the priority (0-3/0-7) of the module that is allowed to use the voice.
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

; "fetch" state
fetch_bank:              .res 1

; low RAM region provided by the user to copy the ISR and PCM code to.
lowram:                  .res 2

; tick-preserved ZP state
zp_preserve_tick:        .res 2

_ZSM_BSS_END := *


.segment "ZSMKITLIB"
;..................
; zsm_init_engine :
;============================================================================
; Arguments: .X .Y address of low RAM reservation that ZSMKit can use
;            at last check, we use 219 bytes for this, and our limit is 255
;            (could be made 256), so asking for a page is reasonable.
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

	PRESERVE_ZP_PTR

	lda X16::Reg::ROMBank
	pha
	lda #$0A
	sta X16::Reg::ROMBank

	; preserve low ram allocation
	phy
	phx

	jsr audio_init

	; initialize BSS

	ldx #<_ZSM_BSS_START
	lda #>_ZSM_BSS_START
	sta P1+1
eraseloop:
	stz $a000,x
P1=*-2
	cmp #>_ZSM_BSS_END
	bcs last_page
	inx
	bne eraseloop
	lda P1+1
	inc
	sta P1+1
	bra eraseloop
last_page:
	inx
	cpx #<_ZSM_BSS_END
	bcc eraseloop
erasedone:

	plx
	stx lowram
	ply
	sty lowram+1

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

	jsr _copy_and_fixup_low_ram_routines

	RESTORE_ZP_PTR

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

	PRESERVE_ZP_PTR

	lda #$ea
	sta zsmkit_clearisr ; ungate zsmkit_clearisr
	lda #$60
	sta zsmkit_setisr ; gate zsmkit_setisr

	lda lowram
	sta PTR
	lda lowram+1
	sta PTR+1

	ldy #<(ISRBANK - __ZSMKIT_LOWRAM_LOAD__)
	lda X16::Reg::RAMBank
	sta (PTR),y

	ldy #<((_old_isr + 1) - __ZSMKIT_LOWRAM_LOAD__)
	lda X16::Vec::IRQVec
	sta (PTR),y

	iny
	lda X16::Vec::IRQVec+1
	sta (PTR),y

	lda lowram
	clc
	adc #<(_isr - __ZSMKIT_LOWRAM_LOAD__)
	sta X16::Vec::IRQVec
	lda lowram+1
	adc #0
	sta X16::Vec::IRQVec+1

	RESTORE_ZP_PTR

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
	lda lowram
	clc
	adc #<(_old_isr - __ZSMKIT_LOWRAM_LOAD__ + 1)
	sta X16::Vec::IRQVec
	lda lowram+1
	adc #>(_old_isr - __ZSMKIT_LOWRAM_LOAD__ + 1)
	sta X16::Vec::IRQVec+1
	plp
	rts

.pushseg
.segment "ZSMKIT_LOWRAM"
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
	lda X16::Reg::RAMBank
	pha
	lda #$ff
ISRBANK = * - 1
	sta X16::Reg::RAMBank
	lda #0
	jsr zsm_tick
	pla
	sta X16::Reg::RAMBank

_old_isr:
	jmp $ffff
.popseg

;..............
; zsm_version :
;============================================================================
; Arguments: (none)
; Returns: .A = major version
;          .X = minor version
; Preserves: .Y
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
.proc zsmkit_version: near
	lda #>ZSMKIT_VERSION
	ldx #<ZSMKIT_VERSION
	rts
.endproc

;.............
; zsm_getptr :
;============================================================================
; Arguments: .X = priority
; Returns: If song is playable, returns .X. Y = pointer to song cursor,
;          .A = bank, and carry clear
;          If song is not playable, carry is set
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; This routine is mainly for player programs to determine progress
.proc zsm_getptr: near
	lda prio_playable,x
	beq err
	ldy zsm_ptr_h,x
	lda zsm_ptr_l,x
	pha
	lda zsm_ptr_bank,x
	plx
	clc
	rts
err:
	sec
	rts
.endproc

;...............
; zsm_getksptr :
;============================================================================
; Arguments: .X = priority
; Returns: returns .X. Y = pointer to OPM key shadow
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; This routine is mainly for player programs to get the OPM key down/up state
.proc zsm_getksptr: near
	lda times_8,x
	clc
	adc #<opm_key_shadow
	tax
	lda #>opm_key_shadow
	adc #0
	tay

	rts
.endproc

;...............
; zsm_getosptr :
;============================================================================
; Arguments: .X = priority
; Returns: returns .X. Y = pointer to OPM register shadow
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; This routine is mainly for player programs to get the OPM register state
.proc zsm_getosptr: near
	txa
	clc
	adc #>opm_shadow
	tay
	ldx #<opm_shadow
	rts
.endproc

;...............
; zsm_getpsptr :
;============================================================================
; Arguments: .X = priority
; Returns: returns .X. Y = pointer to PSG register shadow
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; This routine is mainly for player programs to get the PSG register state
.proc zsm_getpsptr: near
	lda times_64,x
	clc
	adc #<vera_psg_shadow
	pha
	lda times_64h,x
	adc #>vera_psg_shadow
	tay
	plx

	rts
.endproc

;..............
; zsm_getloop :
;============================================================================
; Arguments: .X = priority
; Returns: If song is playable and looped, returns .X. Y = pointer to song
;          loop point, .A = bank, and carry clear
;          If song is not playable or not looped, carry is set
; Preserves: (none)
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
; This routine is mainly for player programs to determine progress
.proc zsm_getloop: near
	lda prio_playable,x
	beq err
	lda loop_enable,x
	beq err
	ldy zsm_loop_h
	lda zsm_loop_l,x
	pha
	lda zsm_loop_bank,x
	plx
	clc
	rts
err:
	sec
	rts
.endproc


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

	PRESERVE_ZP_PTR_TICK

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
	ldx #$ff
prio = * - 1
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

	RESTORE_ZP_PTR_TICK

	rts
.endproc

;..............
; zcm_setbank :
;============================================================================
; Arguments: .X = ZCM slot, .A = ram bank
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the bank of the start of memory for a digital sample (ZCM format)
.proc zcm_setbank: near
	sta zcm_mem_bank,x
	rts
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
	cpx #NUM_ZCM_SLOTS
	bcs end

	lda #$00
AL = * - 1
	sta zcm_mem_l,x
	tya
	sta zcm_mem_h,x
end:
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

	PRESERVE_ZP_PTR

	cpx #NUM_ZCM_SLOTS
	bcs end

	; If high byte of address is zero, it's not valid
	lda zcm_mem_h,x
	beq end
	sta PTR+1
	lda zcm_mem_l,x
	sta PTR

	lda zcm_mem_bank,x
	sta fetch_bank

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

	lda fetch_bank
	sta pcm_cur_bank

	lda PTR
	sta pcm_cur_l

	lda PTR+1
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
	RESTORE_ZP_PTR
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
	jpl end

	PRESERVE_ZP_PTR

	lda pcm_busy
	beq not_busy

	cpx pcm_prio
	jcc end_r ; PCM is busy and we are lower priority
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
	sta PTR
	lda pcm_table_h,x
	sta PTR+1
	lda pcm_table_bank,x
	sta fetch_bank

	; multiply the offset by 16
	tya
	stz tmp_inst
.repeat 4
	asl
	rol tmp_inst
.endrepeat

	; carry is already clear
	adc PTR
	sta PTR
	lda tmp_inst
	adc PTR+1
	sta PTR+1
	jsr validate_pt

	; now we should be at the instrument definiton
	sty tmp_inst
	jsr get_next_byte
	cmp tmp_inst
	jne error_r ; This should be the instrument definition that we asked for

	; here's the geometry byte (bit depth and number of channels)
	; apply it now
	jsr get_next_byte
	and #$30
	sta tmp_inst
	lda Vera::Reg::AudioCtrl
	and #$0f ; volume only, no reset
	ora tmp_inst
	sta Vera::Reg::AudioCtrl

	; slurp up the offset and length, features and loop point
	ldx #10
:	jsr get_next_byte
	pha
	dex
	bne :-

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
	; carry is almost certainly clear from above
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
	beq end_r

	lda pcm_cur_l
	; carry is almost certainly clear from above (unless PCM banks are corrupt)
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
end_r:
	RESTORE_ZP_PTR
end:
	rts
error_r:
	RESTORE_ZP_PTR
error:
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
; Preserves: .X
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
.proc _finalize_pcm_table: near
	stx PRI
	lda pcm_table_l,x
	sta PTR
	lda pcm_table_h,x
	sta PTR+1
	lda pcm_table_bank,x
	sta fetch_bank

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

	ldx #$ff
PRI = * - 1
	sta pcm_inst_max,x

	lda fetch_bank
	sta pcm_table_bank,x
	sta pcm_data_bank,x
	lda PTR
	sta pcm_table_l,x
	lda PTR+1
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
	rol DH
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
LOADFIFOA = * - 2
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

.pushseg
.segment "ZSMKIT_LOWRAM"

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
	bytes_left  = PTR   ; reuse PTR for bytes left
	__CPX		= $e0	; opcode for cpx immediate
	__BNE		= $d0

	PRESERVE_ZP_PTR
	lda X16::Reg::RAMBank
	pha

	; self-mod the page of the LDA below to the current page of pcm_cur_h
	lda pcm_cur_h
_selfmod_code_data_pages1:
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
_selfmod_code_dynamic_comparator1:
	sta dynamic_comparator
	lda #.lobyte(copy_byte0-dynamic_comparator-2)
_selfmod_code_dynamic_comparator1p1:
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
_selfmod_code_data_page0:
	lda data_page0
	inc
	cmp #$c0
	beq do_bankwrap
no_bankwrap:
	; update the self-mod for all 4 iterations of the unrolled loop
_selfmod_code_data_pages2:
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
_selfmod_code_dynamic_comparator2p1:
	sta dynamic_comparator+1
	lda #__CPX
_selfmod_code_dynamic_comparator2:
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
	pla
	sta X16::Reg::RAMBank
_selfmod_code_data_page0a:
	lda data_page0
	sta pcm_cur_h
	stx pcm_cur_l
	sty pcm_cur_bank
	RESTORE_ZP_PTR
	rts

do_bankwrap:
	lda #$a0
	inc X16::Reg::RAMBank
	bra no_bankwrap

.endproc

.popseg

.proc _promote_ondeck: near
	; clear ondeck state
	stz prio_ondeck,x

	; copy song location state
	lda zsm_start_bank+NUM_PRIORITIES,x
	sta zsm_start_bank,x
	sta zsm_ptr_bank,x
	lda zsm_start_l+NUM_PRIORITIES,x
	sta zsm_start_l,x
	sta zsm_ptr_l,x
	sta PTR
	lda zsm_start_h+NUM_PRIORITIES,x
	sta zsm_start_h,x
	sta zsm_ptr_h,x
	sta PTR+1

	lda zsm_loop_bank+NUM_PRIORITIES,x
	sta zsm_loop_bank,x
	lda zsm_loop_l+NUM_PRIORITIES,x
	sta zsm_loop_l,x
	lda zsm_loop_h+NUM_PRIORITIES,x
	sta zsm_loop_h,x

	lda loop_enable+NUM_PRIORITIES,x
	sta loop_enable,x

	lda pcm_table_exists+NUM_PRIORITIES,x
	sta pcm_table_exists,x
	lda pcm_table_bank+NUM_PRIORITIES,x
	sta pcm_table_bank,x
	lda pcm_table_l+NUM_PRIORITIES,x
	sta pcm_table_l,x
	lda pcm_table_h+NUM_PRIORITIES,x
	sta pcm_table_h,x

	lda pcm_inst_max+NUM_PRIORITIES,x
	sta pcm_inst_max,x
	lda pcm_data_bank+NUM_PRIORITIES,x
	sta pcm_data_bank,x
	lda pcm_data_l+NUM_PRIORITIES,x
	sta pcm_data_l,x
	lda pcm_data_h+NUM_PRIORITIES,x
	sta pcm_data_h,x

	lda tick_rate_l+NUM_PRIORITIES,x
	sta tick_rate_l,x
	lda tick_rate_h+NUM_PRIORITIES,x
	sta tick_rate_h,x

	stz loop_number_l,x
	stz loop_number_h,x

	lda times_8,x
	tay
	clc
	adc #8
	sta OVMS
opmloop:
	phy
	lda opm_voice_mask+(NUM_PRIORITIES*8),y
	cmp opm_voice_mask,y
	beq opmnext ; no change
	sta opm_voice_mask,y
	ora #0
	beq opmvoiceoff
opmvoiceon:
	tya
	and #7
	tay
	lda opm_priority,y
	cmp #$ff
	beq opmgrab
	txa
	cmp opm_priority,y
	bcc opmnext
opmgrab:
	txa
	sta opm_priority,y
	bra opmnext
opmvoiceoff:
	lda #$80
	sta recheck_priorities
opmnext:
	ply
	iny
	cpy #$ff
OVMS = * - 1
	bcc opmloop

	lda times_16,x
	tay
	clc
	adc #16
	sta PVMS
psgloop:
	phy
	lda vera_psg_voice_mask+(NUM_PRIORITIES*16),y
	cmp vera_psg_voice_mask,y
	beq psgnext ; no change
	sta vera_psg_voice_mask,y
	ora #0
	beq psgvoiceoff
psgvoiceon:
	tya
	and #15
	tay
	lda vera_psg_priority,y
	cmp #$ff
	beq psggrab
	txa
	cmp vera_psg_priority,y
	bcc psgnext
psggrab:
	txa
	sta vera_psg_priority,y
	bra psgnext
psgvoiceoff:
	lda #$80
	sta recheck_priorities
psgnext:
	ply
	iny
	cpy #$ff
PVMS = * - 1
	bcc psgloop

	jsr _calculate_speed

	rts
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

	stx prio
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
	clc ; carry is almost certainly clear from above unless delay was already negative.  In case that changes (early bail gets implemented, for example), we keep the clc here
	adc #<vera_psg_shadow
	sta PS
	lda #>vera_psg_shadow
	adc times_64h,x
	sta PS+1

	txa
	; carry is almost certainly already clear
	adc #>opm_shadow
	sta OS

memory:
	lda zsm_ptr_l,x
	sta PTR
	lda zsm_ptr_h,x
	sta PTR+1

note_loop:
	jsr getzsmbyte
GETZSMBYTEA = * -2
	ora #0
	bpl isdata
	cmp #$80 ; eod?
	beq iseod
	; is delay
	and #$7f
	clc
	adc delay_l,x
	sta delay_l,x
	bcc nextnote
	inc delay_h,x
nextnote:
	jsr advanceptr
	lda delay_h,x
	bmi note_loop
exit:
	rts
isdata:
	cmp #$40
	beq isext
	bcs isopm
	; is psg
	pha
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTEB = * -2
	plx
	sta vera_psg_shadow,x ; operand is overwritten at sub entry
PS = *-2
	jsr _psg_write
	ldx prio
	bra nextnote
iseod:
	lda loop_enable,x
	bne islooped
	lda prio_ondeck,x
	bne ondeck
	stz prio_active,x
	ldy #$00
	; A == 0 already
	jsr _callback
	jsr _stop_sound
	rts
isext:
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTEC = * -2
	cmp #$40
	jcc ispcm
	cmp #$80
	bcc ischip
	cmp #$c0
	bcc issync
	; channel 3, future use, ignore
ischip: ; external chip, ignore
	and #$3f
	; eat the data bytes, up to 63 of them
	tay
	beq nextnote
:	jsr advanceptr
	dey
	bne :-
	bra nextnote
isopm:
	and #$3f
	tay
	lda prio
	cmp #NUM_OPM_PRIORITIES
	jcs skip_opm
opmloop:
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTED = * -2
	cmp #$01 ; OPM TEST register
	bne :+
	lda #$01 ; Translated TEST register - changed to 9 for OPP
TEST_REGISTER = * - 1
:	pha
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTEE = * -2
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
ondeck:
	jsr _promote_ondeck
	ldy #$10
	jsr _callback
	jmp note_loop
islooped:
	inc loop_number_l,x
	bne :+
	inc loop_number_h,x
:	lda loop_number_l,x
	ldy #$01
	jsr _callback
	; repoint the pointer
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
	jsr getzsmbyte
GETZSMBYTEF = * -2
	cmp #$0e ; ZSM sync type 0-13
	bcc isgensync
	jsr advanceptr
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
	adc #2 ; callback type 0-13, shifted to 2-15, arriving after bcc so carry is clear
	tay
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTEG = * -2
	jsr _callback
	bra endsync
ispcm:
	pha ; save count
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTEH = * -2
	ora #0
	beq ispcmctrl
	cmp #1
	beq ispcmrate
	; PCM trigger
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTEI = * -2
	jsr _pcm_trigger_instrument
	ldx prio
endpcm:
	pla ; restore count
	dec
	dec
	bne ispcm
	jmp nextnote
ispcmctrl:
	jsr advanceptr
	jsr getzsmbyte
GETZSMBYTEJ = * -2
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
	jsr getzsmbyte
GETZSMBYTEK = * -2
	sta pcm_rate_shadow,x
	cpx pcm_prio
	bne endpcm
	sta Vera::Reg::AudioRate
	bra endpcm
advanceptr:
	inc PTR
	bne :+
	inc PTR+1
:	lda PTR+1
	cmp #$c0
	bcc :+
	inc zsm_ptr_bank,x
	lda #$a0
	sta PTR+1
:	sta zsm_ptr_h,x
	lda PTR
	sta zsm_ptr_l,x
	rts
skip_opm:
	jsr advanceptr
	jsr advanceptr
	dey
	bne skip_opm
	jmp nextnote

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

.pushseg
.segment "ZSMKIT_LOWRAM"

getzsmbyte:
	lda zsm_ptr_bank,x
fetchbyte:
	phx
	ldx X16::Reg::RAMBank
	phx
	sta X16::Reg::RAMBank
	lda (PTR)
	plx
	stx X16::Reg::RAMBank
	plx
	rts
.popseg

;...................................
; _copy_and_fixup_low_ram_routines :
;============================================================================
; Arguments: (none)
; Returns: (none)
; Preserves: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
.proc _copy_and_fixup_low_ram_routines: near
	lda lowram
	sta PTR
	lda lowram+1
	sta PTR+1
	ldy #0
copyloop:
	lda __ZSMKIT_LOWRAM_LOAD__,y
	sta (PTR),y
	iny
	cpy #<__ZSMKIT_LOWRAM_SIZE__
	bcc copyloop

	ldx #(selfmod_targets-selfmod_offsets)
modloop:
	ldy selfmod_offsets-1,x
	lda lowram
	clc
	adc selfmod_targets-1,x
	sta (PTR),y
	iny
	lda lowram+1
	adc #0
	sta (PTR),y
	dex
	bne modloop

	ldy #1 ; for the sta (PTR),y in the loop below
	ldx #(fixups_h-fixups_l)
fuloop:
	lda fixups_l-1,x
	sta PTR
	lda fixups_h-1,x
	sta PTR+1
	clc
	lda fixup_targets-1,x
	adc lowram
	sta (PTR)
	lda #0
	adc lowram+1
	sta (PTR),y
	dex
	bne fuloop

	rts
selfmod_offsets:
	.byte <(_load_fifo::_selfmod_code_data_pages1 - __ZSMKIT_LOWRAM_LOAD__ + 1)
	.byte <(_load_fifo::_selfmod_code_data_pages1 - __ZSMKIT_LOWRAM_LOAD__ + 4)
	.byte <(_load_fifo::_selfmod_code_data_pages1 - __ZSMKIT_LOWRAM_LOAD__ + 7)
	.byte <(_load_fifo::_selfmod_code_data_pages1 - __ZSMKIT_LOWRAM_LOAD__ + 10)
	.byte <(_load_fifo::_selfmod_code_dynamic_comparator1 - __ZSMKIT_LOWRAM_LOAD__ + 1)
	.byte <(_load_fifo::_selfmod_code_dynamic_comparator1p1 - __ZSMKIT_LOWRAM_LOAD__ + 1)
	.byte <(_load_fifo::_selfmod_code_data_page0 - __ZSMKIT_LOWRAM_LOAD__ + 1)
	.byte <(_load_fifo::_selfmod_code_data_pages2 - __ZSMKIT_LOWRAM_LOAD__ + 1)
	.byte <(_load_fifo::_selfmod_code_data_pages2 - __ZSMKIT_LOWRAM_LOAD__ + 4)
	.byte <(_load_fifo::_selfmod_code_data_pages2 - __ZSMKIT_LOWRAM_LOAD__ + 7)
	.byte <(_load_fifo::_selfmod_code_data_pages2 - __ZSMKIT_LOWRAM_LOAD__ + 10)
	.byte <(_load_fifo::_selfmod_code_dynamic_comparator2p1 - __ZSMKIT_LOWRAM_LOAD__ + 1)
	.byte <(_load_fifo::_selfmod_code_dynamic_comparator2 - __ZSMKIT_LOWRAM_LOAD__ + 1)
	.byte <(_load_fifo::_selfmod_code_data_page0a - __ZSMKIT_LOWRAM_LOAD__ + 1)
selfmod_targets:
	.byte <(_load_fifo::data_page0 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page1 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page2 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page3 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::dynamic_comparator - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::dynamic_comparator+1 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page0 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page0 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page1 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page2 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page3 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::dynamic_comparator+1 - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::dynamic_comparator - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo::data_page0 - __ZSMKIT_LOWRAM_LOAD__)
fixups_l:
	.lobytes _prio_tick::GETZSMBYTEA, _prio_tick::GETZSMBYTEB, _prio_tick::GETZSMBYTEC, _prio_tick::GETZSMBYTED, _prio_tick::GETZSMBYTEE, _prio_tick::GETZSMBYTEF
	.lobytes _prio_tick::GETZSMBYTEG, _prio_tick::GETZSMBYTEH, _prio_tick::GETZSMBYTEI, _prio_tick::GETZSMBYTEJ, _prio_tick::GETZSMBYTEK, FETCHBYTEA, _pcm_player::LOADFIFOA
fixups_h:
	.hibytes _prio_tick::GETZSMBYTEA, _prio_tick::GETZSMBYTEB, _prio_tick::GETZSMBYTEC, _prio_tick::GETZSMBYTED, _prio_tick::GETZSMBYTEE, _prio_tick::GETZSMBYTEF
	.hibytes _prio_tick::GETZSMBYTEG, _prio_tick::GETZSMBYTEH, _prio_tick::GETZSMBYTEI, _prio_tick::GETZSMBYTEJ, _prio_tick::GETZSMBYTEK, FETCHBYTEA, _pcm_player::LOADFIFOA
fixup_targets:
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(getzsmbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(fetchbyte - __ZSMKIT_LOWRAM_LOAD__)
	.byte <(_load_fifo - __ZSMKIT_LOWRAM_LOAD__)
.endproc


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
	phx
	pha

	lda callback_addr_l,x
	sta CBL
	lda callback_addr_h,x
	sta CBH

	RESTORE_ZP_PTR_TICK
	pla

	jsr $ffff
CBL = * - 2
CBH = * - 1

	PRESERVE_ZP_PTR_TICK

	plx

	; IMPORTANT: be aware of this state-restoring shortcut.
	; All calls to _callback happen from within the tick
	; where PTR is the song data pointer, so this always does
	; the right thing for now.  If _callback is called for
	; any different reason, we need to revisit this.
	lda zsm_ptr_l,x
	sta PTR
	lda zsm_ptr_h,x
	sta PTR+1
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
	cpy #NUM_OPM_PRIORITIES ; $fe or $ff, most likely
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
	cmp #NUM_OPM_PRIORITIES
	bcs opmnext ; this happens immediately after a voice stops but no other song is taking over

	; reshadow all parameters
	ldy voice
	ldx opm_priority,y

	; carry is clear from bcs test above
	lda times_8,x
	adc #<opm_atten_shadow
	sta OASR
	lda #>opm_atten_shadow
	adc #0
	sta OASR+1

	txa

	; carry is almost certainly already clear
	adc #>opm_shadow
	sta OH
	sta OH7

	; restore noise enable / nfreq
	; shadow for our prio if it's in voice 7
	cpy #7
	bne not7
	ldx #$0f
	lda opm_shadow,x
OH7 = * - 1
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
	adc times_64h,x
	sta PL+1

	ldy voice
	ldx vera_psg_priority,y

	lda times_16,x
	; carry is almost certainly already clear
	adc #<vera_psg_atten_shadow
	sta PASR
	lda #>vera_psg_atten_shadow
	adc #0
	sta PASR+1

	lda voice
	asl
	asl
	tax
	ldy #4 ; number of data bytes per channel
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
	lda prio_active,x
	cmp #$01
	lda prio_playable,x
	php

	lda loop_number_l,x
	ldy loop_number_h,x

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
	stz callback_enabled,x

	sta callback_addr_l,x
	tya
	sta callback_addr_h,x

	lda #$80
	sta callback_enabled,x

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
	stz callback_enabled,x
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
	sta int_rate
	sty int_rate_frac

	ldx #(NUM_PRIORITIES-1)

@1:
	lda prio_playable,x
	beq @2

	jsr _calculate_speed

@2:	dex
	bpl @1

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
	sta tick_rate_l,x
	tya
	sta tick_rate_h,x

	jsr _calculate_speed

	rts
.endproc


;..............
; zsm_getrate :
;============================================================================
; Arguments: .X = priority
; Returns: .A .Y (lo hi) of tick rate
; Preserves: .X
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Returns the current tick rate of the song.
.proc zsm_getrate: near
	lda tick_rate_l,x
	ldy tick_rate_h,x

	rts
.endproc


;..............
; zsm_setloop :
;============================================================================
; Arguments: .X = priority, .C = boolean
; Returns: (none)
; Preserves: .X
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the priority to loop if carry is set, if clear, disables looping
.proc zsm_setloop: near
	php
	lda #$80
	plp
	bcs :+
	lda #$00
:	sta loop_enable,x

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
	sta VAL ; divide by 3
	lsr
	lsr
	adc VAL
	ror
	lsr
	adc VAL
	ror
	lsr
	adc VAL
	ror
	lsr
	adc VAL
	ror
	lsr
	sta VAL
	lda #$00
V1 = * - 1
	sec
	sbc VAL ; subtract 1/3 from the atten value (multiply by 2/3)
	sta VAL

bounds_checked:
	stx PRI
	cpx #NUM_OPM_PRIORITIES
	bcs end

	lda times_8,x
	; carry is almost certainly already clear
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
end:
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
	sei
	jsr _opmatten
end:
	plp
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
	cpx #NUM_PRIORITIES
	bcs end
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
end:
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
	sei
	jsr _psgatten
end:
	plp
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
	cpx #NUM_PRIORITIES
	bcs end
	ldy #16
:	dey
	cmp scalelut,y
	bcc :-
	tya
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
scalelut:
	.byte 0,5,9,14,18,23,27,31
	.byte 36,40,45,49,54,58,61,63
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
	sei
	jsr _pcmatten
end:
	plp
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

	php ; protect critical section
	sei

; PCM
	lda #$ff
val = * - 1
	jsr _pcmatten

dopsg:
	ldy #15
psgloop:

	ldx #$ff
prio = * - 1
	lda val
	jsr _psgatten

	dey
	bpl psgloop

	ldy #7
opmloop:

	ldx prio
	lda val

	jsr _opmatten

	dey
	bpl opmloop

	plp

exit:
	rts
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
	lda prio_active,x
	beq :+
	jsr zsm_stop
	ldx #$ff
prio = * - 1
:
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
	rts
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
; sets priority to unused/not playable
;
.proc zsm_close: near
	stx prio
	lda prio_active,x
	beq :+
	jsr zsm_stop
	ldx #$ff
prio = * - 1
:
	stz prio_playable,x

	rts
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
; for cleanup.

.proc zsm_stop: near
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
; Allowed in interrupt handler: with caveats
; ---------------------------------------------------------------------------
;
; This routine is safe to call within an interrupt handler
; (such as within a ZSM callback)
;
; Sets up the song to start playing back on the next tick if
; the song is valid and ready to play
.proc zsm_play: near
	lda prio_active,x
	bne exit ; already playing

	lda prio_playable,x
	beq exit

	lda zsm_ptr_bank,x
	bne ok
	lda zsm_ptr_h,x
	cmp #$A0
	bcc exit
ok:
	; prevent interrupt during critical section
	php
	sei

	stx prio
	cpx #NUM_OPM_PRIORITIES
	bcs noopm
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
	ldx #$ff
prio = * - 1
noopm:
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

	plp ; end critical section
exit:
	rts
.endproc

;..............
; zsm_setbank :
;============================================================================
; Arguments: .X = priority, .A = RAM bank
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the bank of the start of memory for the priority,
; !! must be set before calling zsm_setmem !!
.proc zsm_setbank: near
	sta zsm_start_bank,x
	rts
.endproc

;...................
; zsm_clear_ondeck :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Clears the priority's on-deck tune
.proc zsm_clear_ondeck: near
	stz prio_ondeck,x
	rts
.endproc

;......................
; zsm_set_ondeck_bank :
;============================================================================
; Arguments: .X = priority, .A = RAM bank
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the bank of the start of memory for the priority's next song,
; !! must be set before calling zsm_ondeck_mem !!
.proc zsm_set_ondeck_bank: near
	sta zsm_start_bank+NUM_PRIORITIES,x
	rts
.endproc

.proc _zsm_setmem_p1: near
	; start bank of ZSM header
	lda zsm_start_bank,x
	sta fetch_bank

	lda PTR
	sta zsm_start_l,x
	lda PTR+1
	sta zsm_start_h,x

	jsr get_next_byte
	cmp #$7a ; 'z'
	bne err1

	jsr get_next_byte
	cmp #$6d ; 'm'
	bne err1

	jsr get_next_byte
	cmp #1 ; version (1)
	beq noerr1

err1:
	stz prio_playable,x
	sec
	rts

noerr1:
	jsr get_next_byte ; loop point low
	sta tmp1
	jsr get_next_byte ; loop point med
	sta tmp1+1
	jsr get_next_byte ; loop point high
	sta tmp1+2

	asl        ; each of these is
	asl        ; worth 64 k
	asl        ; or 8 banks
	; carry is almost certainly clear unless loop point high is corrupt
	adc zsm_start_bank,x
	sta zsm_loop_bank,x

	lda tmp1+1 ; loop point med
	tay
	lsr        ; each of these
	lsr        ; is worth a page
	lsr        ; and 32 of them
	lsr        ; is worth
	lsr        ; one 8k bank
	clc
	adc zsm_loop_bank,x
	sta zsm_loop_bank,x

	tya         ; keep the remainder
	and #$1f    ; which when added to the start
	tay         ; will be < $ff

	lda tmp1    ; loop point low
	; carry is almost certainly clear unless loop point high is corrupt (added to med)
	adc zsm_start_l,x
	sta zsm_loop_l,x
	tya
	adc zsm_start_h,x
:	cmp #$c0
	bcc :+
	sbc #$20
	inc zsm_loop_bank,x
	bra :-
:	sta zsm_loop_h,x

	; do we even loop?
	lda tmp1
	ora tmp1+1
	ora tmp1+2

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

	; PCM table
	jsr get_next_byte
	sta tmp1
	jsr get_next_byte
	sta tmp1+1
	jsr get_next_byte
	sta tmp1+2

	stz pcm_table_exists,x
	lda tmp1
	ora tmp1+1
	ora tmp1+2
	beq nopcm

	; offset 6 7 8 (PCM offset)
	lda tmp1+2 ; PCM offset [23:16]
	asl        ; each of these is
	asl        ; worth 64 k
	asl        ; or 8 banks
	; carry is almost certainly already clear unless PCM offset high is corrupt
	adc zsm_start_bank,x
	sta pcm_table_bank,x

	lda tmp1+1 ; PCM offset [15:8]
	lsr        ; each of these
	lsr        ; is worth a page
	lsr        ; and 32 of them
	lsr        ; is worth
	lsr        ; one 8k bank
	clc
	adc pcm_table_bank,x
	sta pcm_table_bank,x

	lda tmp1+1 ; keep the remainder
	and #$1f   ; which when added to the start
	tay        ; will be < $ff

	lda tmp1   ; PCM offset [7:0]
	; carry is almost certainly already clear unless PCM offset high is corrupt (added to med)
	adc zsm_start_l,x ; start of zsm data (LSB)
	sta pcm_table_l,x
	tya         ; PCM offset [12:8]
	adc zsm_start_h,x ; start of zsm data (MSB)
:	cmp #$c0    ; if we're past
	bcc :+
	sbc #$20    ; subtract $20
	inc pcm_table_bank,x ; and increment bank
	bra :-
:	sta pcm_table_h,x ; and we're done figuring out the PCM table location

	inc pcm_table_exists,x ; set to 1 so we can finalize the table later

nopcm:
	clc
	rts
tmp1:
	.byte 0,0,0
.endproc

.proc _zsm_setmem_p2: near
	; FM channel mask
	jsr get_next_byte
	phx
	ply
	cpy #NUM_PRIORITIES*2
	bcs noopm
	ldx times_8,y
.repeat 8,i
	lsr
	stz opm_voice_mask+i,x
	ror opm_voice_mask+i,x
.endrepeat
noopm:
	; PSG channel mask
	jsr get_next_byte
	ldx times_16,y
.repeat 8,i
	lsr
	stz vera_psg_voice_mask+i,x
	ror vera_psg_voice_mask+i,x
.endrepeat
	jsr get_next_byte
.repeat 8,i
	lsr
	stz vera_psg_voice_mask+i+8,x
	ror vera_psg_voice_mask+i+8,x
.endrepeat
	rts
.endproc

.proc _zsm_setmem_p3: near
	; ZSM tick rate
	jsr get_next_byte
	sta tick_rate_l,x
	jsr get_next_byte
	sta tick_rate_h,x

	; eat reserved bytes
	jsr get_next_byte
	jsr get_next_byte

	lda fetch_bank
	sta zsm_start_bank,x
	cpx #NUM_PRIORITIES
	bcs :+
	sta zsm_ptr_bank,x
:	lda PTR
	sta zsm_start_l,x
	bcs :+
	sta zsm_ptr_l,x
:	lda PTR+1
	sta zsm_start_h,x
	bcs :+
	sta zsm_ptr_h,x

:	lda pcm_table_exists,x
	beq :+
	jsr _finalize_pcm_table
:
	rts
.endproc

;.............
; zsm_setmem :
;============================================================================
; Arguments: .X = priority, .A .Y = data pointer
; Preparatory routines: zsm_setbank
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the start of memory for the priority, reads it,
; and parses the header
;
; Must only be called from main loop routines.
.proc zsm_setmem: near
	sta TMPA
	PRESERVE_ZP_PTR

	cpx #NUM_PRIORITIES
	bcs end

	lda #$00
TMPA = * - 1
	sta PTR
	sty PTR+1

	stx prio
	lda prio_active,x
	beq :+
	jsr zsm_close ; will also stop
:
	ldx prio

	jsr _zsm_setmem_p1 ; first part of header
	bcs end

	jsr _zsm_setmem_p2 ; OPM/PSG channel masks

	ldx #$ff
prio = * - 1

	jsr _zsm_setmem_p3 ; PCM table setup

	; finish setup of state
	stz delay_f,x
	stz delay_l,x
	stz delay_h,x

	stz loop_number_h,x
	stz loop_number_l,x

	lda #$80
	sta prio_playable,x

	jsr _zero_shadow

	jsr _calculate_speed

end:
	RESTORE_ZP_PTR
	rts
.endproc

;.....................
; zsm_set_ondeck_mem :
;============================================================================
; Arguments: .X = priority, .A .Y = data pointer
; Preparatory routines: zsm_setbank
; Returns: (none)
; Allowed in interrupt handler: no
; ---------------------------------------------------------------------------
;
; Sets the start of memory for the priority's on-deck data, reads it,
; and parses the header
;
; Must only be called from main loop routines.
.proc zsm_set_ondeck_mem: near
	sta TMPA
	PRESERVE_ZP_PTR

	cpx #NUM_PRIORITIES
	bcs end

	lda #$00
TMPA = * - 1
	sta PTR
	sty PTR+1

	stz prio_ondeck,x
	stx prio

	txa
	; carry is almost certainly already clear
	adc #NUM_PRIORITIES
	tax

	stx prio2

	jsr _zsm_setmem_p1 ; first part of header
	bcs end

	jsr _zsm_setmem_p2 ; OPM/PSG channel masks

	ldx #$ff
prio2 = * - 1

	jsr _zsm_setmem_p3 ; PCM table setup

	ldx #$ff
prio = * - 1
	lda #$80
	sta prio_ondeck,x
end:
	RESTORE_ZP_PTR
	rts
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

	cpx #NUM_OPM_PRIORITIES
	bcs end

	lda #0
	ldy times_8,x
	ldx #8
:	sta opm_key_shadow,y
	iny
	dex
	bne :-
end:
	plx
	rts
.endproc

;...................
; _calculate_speed :
;============================================================================
; Arguments: .X = priority
; Returns: (none)
; Preserves: .X
; Allowed in interrupt handler: yes
; ---------------------------------------------------------------------------
;
; performs the calculation tick_rate_*/60 and stores in speed_*
;
.proc _calculate_speed: near
	php
	sei
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

	ldx #$ff
prio = * - 1
	lda tmp2
	sta speed_f,x
	lda tmp2+1
	sta speed_l,x
	lda tmp2+2
	sta speed_h,x

	plp
	rts
tmp1:
	.byte 0,0
tmp2:
	.byte 0,0,0,0
tmp3:
	.byte 0,0
.endproc

get_next_byte:
	lda fetch_bank
	jsr fetchbyte
FETCHBYTEA = * - 2
	inc PTR
	bne gnb2
	inc PTR+1
validate_pt:
	pha
	lda PTR+1
	cmp #$c0
	bcc gnb1
	sbc #$20
	sta PTR+1
	inc fetch_bank
gnb1:
	pla
gnb2:
	rts

times_8:
.repeat NUM_PRIORITIES*2, i
	.byte i*8
.endrepeat

times_16:
.repeat NUM_PRIORITIES*2, i
	.byte i*16
.endrepeat

times_64:
.repeat NUM_PRIORITIES, i
	.byte <(i*64)
.endrepeat

times_64h:
.repeat NUM_PRIORITIES, i
	.byte >(i*64)
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

.assert NUM_PRIORITIES <= 8, error, "Memory constraints restrict number of priorities to be <= 8"

.assert __ZSMKIT_LOWRAM_SIZE__ <= 255, error, "Low RAM copy and fixup code assumes ZSMKIT_LOWRAM segment is 255 bytes or smaller in length"
