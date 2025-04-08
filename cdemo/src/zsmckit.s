.import popa
.import pusha
.import popax
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

zsm_bank: .byte 0
RAM_BANK = $00

_zsm_init_engine:
	sta	zsm_bank		; Save Bank where ZSMkit is loaded
	sta	RAM_BANK
	jsr	popa			; Get low part of address where ZSMkit is loaded
	tax
	jsr	popa			; Get hi part of address where ZSM kit is loaded
	tay
	jmp	zsm_init_engine

_zsm_tick:
	pha				; Save parameter on stack while correct bank is set
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	pla				; Restore parameter from stack
	jmp	zsm_tick

_zsm_play:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_play

_zsm_stop:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_stop

_zsm_rewind:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_rewind

_zsm_close:
	tax				; Move priority to X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_close

_zsm_getloop = zsm_getloop
_zsm_getptr = zsm_getptr
_zsm_getksptr = zsm_getksptr
_zsm_setbank:
	pha				; Save priority bank on stack	
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore priority bank from stack
	jmp	zsm_setbank

_zsm_setmem:
	pha				; Save low part of address on stack
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	txa				; Move hi part of address into .Y
	tay
	jsr	popa			; Get priority ID into X
	tax
	pla				; Restore low part of address on stack
	jmp	zsm_setmem

_zsm_setatten = zsm_setatten
_zsm_setcb = zsm_setcb
_zsm_clearcb:
	tax				; Move priority ID into X
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsm_clearcb

_zsm_getstate = zsm_getstate
_zsm_setrate = zsm_setrate
_zsm_getrate = zsm_getrate
_zsm_setloop = zsm_setloop
_zsm_opmatten = zsm_opmatten
_zsm_psgatten = zsm_psgatten
_zsm_pcmatten = zsm_pcmatten
_zsm_set_int_rate = zsm_set_int_rate
_zsm_getosptr = zsm_getosptr
_zsm_getpsptr = zsm_getpsptr
_zcm_setbank = zcm_setbank
_zcm_setmem = zcm_setmem
_zcm_play = zcm_play
_zcm_stop = zcm_stop
_zsmkit_setisr:
	lda	zsm_bank		; Ensure correct RAM bank is selected before call
	sta	RAM_BANK
	jmp	zsmkit_setisr

_zsmkit_clearisr = zsmkit_clearisr
_zsmkit_version = zsmkit_version
_zsm_set_ondeck_bank =  zsm_set_ondeck_bank
_zsm_set_ondeck_mem = zsm_set_ondeck_mem
_zsm_clear_ondeck = zsm_clear_ondeck
_zsm_midi_init = zsm_midi_init
_zsm_psg_suspend = zsm_psg_suspend
_zsm_opm_suspend = zsm_opm_suspend
