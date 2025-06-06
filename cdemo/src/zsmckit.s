.import popa
.import pusha
.importzp sreg
.include "zsmkit.inc"

.export _zsm_init_engine
.export _zsm_tick
.export _zsm_play
.export _zsm_stop
.export _zsm_rewind
.export _zsm_close
.export _zsm_getloop
.export _zsm_getptr
.export _zsm_getksptr
.export _zsm_setbank
.export _zsm_setmem
.export _zsm_setatten
.export _zsm_setcb
.export _zsm_clearcb
.export _zsm_getstate
.export _zsm_setrate
.export _zsm_getrate
.export _zsm_setloop
.export _zsm_opmatten
.export _zsm_psgatten
.export _zsm_pcmatten
.export _zsm_set_int_rate
.export _zsm_getosptr
.export _zsm_getpsptr
.export _zcm_setbank
.export _zcm_setmem
.export _zcm_play
.export _zcm_stop
.export _zsmkit_setisr
.export _zsmkit_clearisr
.export _zsmkit_version
.export _zsm_set_ondeck_bank
.export _zsm_set_ondeck_mem
.export _zsm_clear_ondeck
.export _zsm_midi_init
.export _zsm_psg_suspend
.export _zsm_opm_suspend
.export _zsm_pcm_suspend

zsm_bank: .byte 0
RAM_BANK = $00

; GLOBAL: initialize the ZSMKit engine
_zsm_init_engine:
	sta	zsm_bank		; Save Bank where ZSMkit is loaded
	sta	RAM_BANK
	jsr	popa			; Get lo part of address where ZSMkit is loaded
	tax
	jsr	popa			; Get hi part of address where ZSM kit is loaded
	tay
	jmp	zsm_init_engine

; GLOBAL: process one tick of music data
_zsm_tick:
	pha				; Save parameter on stack while correct bank is set
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	pla				; Restore parameter from stack
	jmp	zsm_tick

; PER-PRIORITY: start playback
_zsm_play:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_play

; PER-PRIORITY: pause or stop playback
_zsm_stop:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_stop

; PER-PRIORITY: reset to start of music
_zsm_rewind:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_rewind

; PER-PRIORITY: stop playback and clear playable status
_zsm_close:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_close

; PER-PRIORITY: get loop flag and address of loop point
_zsm_getloop:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	zsm_getloop
	; If Carry clear, return values, otherwise return all 0's
	bcc	:+
	stz	sreg+0			; Set all return values to 0
	ldx	#0
	lda	#0
	rts
:	sty	sreg+0			; Save hi part of address in sreg+0
	rts

; PER-PRIORITY: get address of playback cursor
_zsm_getptr:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	zsm_getptr
	; If Carry clear, return values, otherwise return all 0's
	bcc	:+
	stz	sreg+0			; Set all return values to 0
	ldx	#0
	lda	#0
	rts
:	sty	sreg+0			; Save hi part of address in sreg+0
	rts

; PER-PRIORITY: get address of OPM keydown shadow
_zsm_getksptr:
	tax				; Move priority ID into X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	zsm_getksptr
	txa				; Move lo byte of address to A
	phy				; Move hi byte of address to X
	plx
	rts

; PER-PRIORITY: set bank <- do this first
_zsm_setbank:
	pha				; Save priority bank on stack	
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore priority bank from stack
	jmp	zsm_setbank

; PER-PRIORITY: set address <- do this second
_zsm_setmem:
	pha				; Save lo part of address on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	txa				; Move hi part of address into .Y
	tay
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore lo part of address on stack
	jmp	zsm_setmem

; PER-PRIORITY: set attenuation (master volume)
_zsm_setatten:
	pha				; Save attenuation on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore attenuation from stack
	jmp	zsm_setatten

; PER-PRIORITY: set up callback (persists through song changes)
_zsm_setcb:
	pha				; Save lo address of callback function on stack
	phx				; Save hi address of callback function on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get Priority ID into X
	tax
	cmp	#0			; Is priority ID 0
	bne	@is1
	pla				; Store address of C callback function in internal
	sta	zsm_cb0j+2		; callback function
	pla
	sta	zsm_cb0j+1
	lda	#<zsm_cb0		; Load address of internal callback function
	ldy	#>zsm_cb0
	jmp	zsm_setcb
@is1:	cmp	#1
	bne	@is2
	pla				; Store address of C callback function in internal
	sta	zsm_cb1j+2		; CB function
	pla
	sta	zsm_cb1j+1
	lda	#<zsm_cb1		; Load address of internal callback function
	ldy	#>zsm_cb1
	jmp	zsm_setcb
@is2:	cmp	#2
	bne	@is3
	pla				; Store address of C callback function in internal
	sta	zsm_cb2j+2		; CB function
	pla
	sta	zsm_cb2j+1
	lda	#<zsm_cb2		; Load address of internal callback function
	ldy	#>zsm_cb2
	jmp	zsm_setcb
@is3:	cmp	#3
	bne	@is4
	pla				; Store address of C callback function in internal
	sta	zsm_cb3j+2		; CB function
	pla
	sta	zsm_cb3j+1
	lda	#<zsm_cb3		; Load address of internal callback function
	ldy	#>zsm_cb3
	jmp	zsm_setcb
@is4:	cmp	#4
	bne	@is5
	pla				; Store address of C callback function in internal
	sta	zsm_cb4j+2		; CB function
	pla
	sta	zsm_cb4j+1
	lda	#<zsm_cb4		; Load address of internal callback function
	ldy	#>zsm_cb4
	jmp	zsm_setcb
@is5:	cmp	#5
	bne	@is6
	pla				; Store address of C callback function in internal
	sta	zsm_cb5j+2		; CB function
	pla
	sta	zsm_cb5j+1
	lda	#<zsm_cb5		; Load address of internal callback function
	ldy	#>zsm_cb5
	jmp	zsm_setcb
@is6:	cmp	#6
	bne	@mustbe7
	pla				; Store address of C callback function in internal
	sta	zsm_cb6j+2		; CB function
	pla
	sta	zsm_cb6j+1
	lda	#<zsm_cb6		; Load address of internal callback function
	ldy	#>zsm_cb6
	jmp	zsm_setcb
@mustbe7:
	pla				; Store address of C callback function in internal
	sta	zsm_cb7j+2		; CB function
	pla
	sta	zsm_cb7j+1
	lda	#<zsm_cb7		; Load address of internal callback function
	ldy	#>zsm_cb7
	jmp	zsm_setcb

; PER-PRIORITY: clear callback
_zsm_clearcb:
	tax				; Move priority ID into X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_clearcb

; PER-PRIORITY: get playback state
_zsm_getstate:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	zsm_getstate
	; If Carry clear, return values, otherwise return all 0's
	bcc	:+
	stz	sreg+0			; Set all return values to 0
	ldx	#0
	lda	#0
	rts
:	php				; Save flags, they are used for state
	sty	sreg+0			; Save hi part of address in sreg+0
	tax				; Save lo part of address in X
	pla				; Restore state from stack 
	and	#$03			; Only use Z and C flags
	rts

; PER-PRIORITY: set tick rate (tempo)
_zsm_setrate:
	pha				; Save lo byte of tick rate on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	txa				; Move hi byte of tick rate from X to Y
	tay
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore lo byte of tick rate from stack
	jmp	zsm_setrate

; PER-PRIORITY: get tick rate
_zsm_getrate:
	tax				; Move priority ID into X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	zsm_getrate
	phy				; Move hi byte of tick rate to X (A is already lo byte)
	plx
	rts

; PER-PRIORITY: set or clear loop flag
_zsm_setloop:
	pha				; Save loop setting on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore loop setting from stack and shift into Carryflag
	lsr
	jmp	zsm_setloop

; PER-PRIORITY: set attenuation of specific FM channel
_zsm_opmatten:
	pha				; Save value on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get channel into Y
	tay
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore value from stack
	jmp	zsm_opmatten

; PER-PRIORITY: set attenuation of specific PSG channel
_zsm_psgatten:
	pha				; Save value on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get channel into Y
	tay
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore value from stack
	jmp	zsm_psgatten

; PER-PRIORITY: set attenuation of PCM events in song
_zsm_pcmatten:
	pha				; Save value on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore value from stack
	jmp	zsm_pcmatten

; GLOBAL: inform ZSMKit of expected tick rate
_zsm_set_int_rate:
	pha				; Save interrupt rate on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get fractional portion into Y
	tay
	pla				; Restore interrupt rate from stack
	jmp	zsm_set_int_rate

; PER-PRIORITY: get address of OPM shadow
_zsm_getosptr:
	tax				; Move priority ID into X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	zsm_getosptr
	txa				; Move lo part of address into A
	phy				; Move hi part of address from Y to X
	plx
	rts

; PER-PRIORITY: get address of PSG shadow
_zsm_getpsptr:
	tax				; Move priority ID into X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	zsm_getpsptr
	txa				; Move lo part of address into A
	phy				; Move hi part of address from Y to X
	plx
	rts

; PER-SLOT: set bank of ZCM (PCM) <- do this first
_zcm_setbank:
	pha				; Save RAM bank on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get slot ID into X
	tax
	pla				; Restore RAM bank from stack
	jmp	zcm_setbank

; PER-SLOT: set address of ZCM (PCM) <- do this second
_zcm_setmem:
	pha				; Save lo part of address on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	txa				; Move hi part of address into .Y
	tay
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore lo part of address on stack
	jmp	zcm_setmem

; PER-SLOT: play ZCM (PCM)
_zcm_play:
	pha				; Save volume on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get slot ID into X
	tax
	pla				; Restore volume from stack
	jmp	zcm_play

; GLOBAL: cancel ZCM playback
_zcm_stop:
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zcm_stop

; GLOBAL: install a default interrupt handler
_zsmkit_setisr:
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsmkit_setisr

; GLOBAL: restore the previous interrupt handler
_zsmkit_clearisr:
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsmkit_clearisr

; GLOBAL: get the ZSMKit version
_zsmkit_version:
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsmkit_version

; PER-PRIORITY: set next song's bank <- do this first
_zsm_set_ondeck_bank:
	pha				; Save RAM bank on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore RAM bank from stack
	jmp	zsm_set_ondeck_bank

; PER-PRIORITY: set next song's address <- do this second
_zsm_set_ondeck_mem:
	pha				; Save lo part of address on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	txa				; Move hi part of address into .Y
	tay
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore lo part of address on stack
	jmp	zsm_set_ondeck_mem

; PER-PRIOTITY: clear queued on-deck song
_zsm_clear_ondeck:
	tax				; Move priority into X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_clear_ondeck

; GLOBAL: initialize/set params for MIDI out support
_zsm_midi_init:
	tax				; Move callback flag into X
	jsr	popa			; Get serial/parallel toggle and save it on stack
	pha			
	jsr	popa			; Get offset and save it on stack
	pha
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	txa				; Move callback flag back to A and shift it to C
	lsr
	pla				; Restore offset from stack
	plx				; Restore serial/parallesl toggle from stack
	jmp	zsm_midi_init

; PER-VOICE: suspend ZSMKit's use of VERA PSG channel
_zsm_psg_suspend:
	pha				; Save suspend flag on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get channel into Y
	tay
	pla				; Restore suspend flag from stack and shift into C
	lsr
	jmp	zsm_psg_suspend

; PER-VOICE: suspend ZSMKit's use of FM channel
_zsm_opm_suspend:
	pha				; Save suspend flag on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get channel into Y
	tay
	pla				; Restore suspend flag from stack and shift into C
	lsr
	jmp	zsm_opm_suspend

; GLOBAL: suspend ZSMKit's use of VERA PCM
_zsm_pcm_suspend:
	lsr                 ; shift suspend flag into C
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_opm_suspend

; ****** Callback functions that will call users callback function *******
; ****** This is done to get the return values in the correct order ******
; ****** for the C function                                        *******
;void callbackfunction(uint8_t eventtype, uint8_t priority, uint8_t paramval)
zsm_cb0:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb0j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
zsm_cb1:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb1j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
zsm_cb2:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb2j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
zsm_cb3:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb3j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
zsm_cb4:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb4j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
zsm_cb5:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb5j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
zsm_cb6:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb6j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
zsm_cb7:
	pha			; Save .A as it must contain value for function
	tya			; Push .Y to soft-stack
	jsr	pusha
	txa			; Push .X to soft-stack
	jsr	pusha
	pla			; Restore .A for function call
zsm_cb7j:
	jmp	$FFFF ; This address is replaced by the C callback function when zsm_setcb is called
