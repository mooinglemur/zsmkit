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

; These values are used to tell zsm_tick what to update
MUSIC_PCM  = 0
PCM_ONLY   = 1
MUSIC_ONLY = 2

; These values are used to interpret the state of a priority
PLAYING    = 1
UNPLAYABLE = 2

_zsm_init_engine = zsm_init_engine
_zsm_tick = zsm_tick
_zsm_play = zsm_play
_zsm_stop = zsm_stop
_zsm_rewind = zsm_rewind
_zsm_close = zsm_close
_zsm_getloop = zsm_getloop
_zsm_getptr = zsm_getptr
_zsm_getksptr = zsm_getksptr
_zsm_setbank = zsm_setbank
_zsm_setmem =  zsm_setmem
_zsm_setatten = zsm_setatten
_zsm_setcb = zsm_setcb
_zsm_clearcb = zsm_clearcb
_zsm_getstate = zsm_getstate
_zsm_setrate = zsm_setrate
_zsm_getrate = zsm_getrate
_zsm_setloop = zsm_setloop
_zsm_opmatten = zsm_opmatten
_zsm_psgatten = zsm_psgatten
_zsm_pcmatten = zsm_pcmatten
_zsm_set_int_rat = zsm_set_int_ratee
_zsm_getosptr = zsm_getosptr
_zsm_getpsptr = zsm_getpsptr
_zcm_setbank = zcm_setbank
_zcm_setmem = zcm_setmem
_zcm_play = zcm_play
_zcm_stop = zcm_stop
_zsmkit_setisr = zsmkit_setisr
_zsmkit_clearisr = zsmkit_clearisr
_zsmkit_version = zsmkit_version
_zsm_set_ondeck_bank =  zsm_set_ondeck_bank
_zsm_set_ondeck_mem = zsm_set_ondeck_mem
_zsm_clear_ondeck = zsm_clear_ondeck
_zsm_midi_init = zsm_midi_init
_zsm_psg_suspend = zsm_psg_suspend
_zsm_opm_suspend = zsm_opm_suspend
