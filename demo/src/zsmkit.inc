; This "include" file can be imported into assembly projects.
; To call any of these routines, first, switch to the bank where the code is loaded
; then jsr to the routine

zsm_init_engine      = $A000 ; GLOBAL: initialize the ZSMKit engine
zsm_tick             = $A003 ; GLOBAL: process one tick of music data
zsm_play             = $A006 ; PER-PRIORITY: start playback
zsm_stop             = $A009 ; PER-PRIORITY: pause or stop playback
zsm_rewind           = $A00C ; PER-PRIORITY: reset to start of music
zsm_close            = $A00F ; PER-PRIORITY: stop playback and clear playable status
zsm_getloop          = $A012 ; PER-PRIORITY: get loop flag and address of loop point
zsm_getptr           = $A015 ; PER-PRIORITY: get address of playback cursor
zsm_getksptr         = $A018 ; PER-PRIORITY: get address of OPM keydown shadow
zsm_setbank          = $A01B ; PER-PRIORITY: set bank <- do this first
zsm_setmem           = $A01E ; PER-PRIORITY: set address <- do this second
zsm_setatten         = $A021 ; PER-PRIORITY: set attenuation (master volume)
zsm_setcb            = $A024 ; PER-PRIORITY: set up callback (persists through song changes)
zsm_clearcb          = $A027 ; PER-PRIORITY: clear callback
zsm_getstate         = $A02A ; PER-PRIORITY: get playback state
zsm_setrate          = $A02D ; PER-PRIORITY: set tick rate (tempo)
zsm_getrate          = $A030 ; PER-PRIORITY: get tick rate
zsm_setloop          = $A033 ; PER-PRIORITY: set or clear loop flag
zsm_opmatten         = $A036 ; PER-PRIORITY: set attenuation of specific FM channel
zsm_psgatten         = $A039 ; PER-PRIORITY: set attenuation of specific PSG channel
zsm_pcmatten         = $A03C ; PER-PRIORITY: set attenuation of PCM events in song
zsm_set_int_rate     = $A03F ; GLOBAL: inform ZSMKit of expected tick rate
zsm_getosptr         = $A042 ; PER-PRIORITY: get address of OPM shadow
zsm_getpsptr         = $A045 ; PER-PRIORITY: get address of PSG shadow
zcm_setbank          = $A048 ; PER-SLOT: set bank of ZCM (PCM) <- do this first
zcm_setmem           = $A04B ; PER-SLOT: set address of ZCM (PCM) <- do this second
zcm_play             = $A04E ; PER-SLOT: play ZCM (PCM)
zcm_stop             = $A051 ; GLOBAL: cancel ZCM playback
zsmkit_setisr        = $A054 ; GLOBAL: install a default interrupt handler
zsmkit_clearisr      = $A057 ; GLOBAL: restore the previous interrupt handler
zsmkit_version       = $A05A ; GLOBAL: get the ZSMKit version
zsm_set_ondeck_bank  = $A05D ; PER-PRIORITY: set next song's bank <- do this first
zsm_set_ondeck_mem   = $A060 ; PER-PRIORITY: set next song's address <- do this second
zsm_clear_ondeck     = $A063 ; PER-PRIOTITY: clear queued on-deck song
zsm_midi_init        = $A066 ; GLOBAL: initialize/set params for MIDI out support
zsm_psg_suspend      = $A069 ; PER-VOICE: suspend ZSMKit's use of VERA PSG channel
zsm_opm_suspend      = $A06C ; PER-VOICE: suspend ZSMKit's use of FM channel
