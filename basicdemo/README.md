# BASIC demo

This example uses a binary blob of ZSMKit loaded at the end of low RAM. It allows for uninterrupted playback during your BASIC program.

```BASIC
10 BLOAD"ZSMKITA000.BIN",8,1,$A000 : REM LOAD ZSMKIT LIB
20 REM INITIALIZE ZSMKIT
30 BANK 1
40 POKE$30D,$00 : REM LOW RAM REGION $400-$4FF GIVEN TO ZSMKIT
50 POKE$30E,$04 : REM LOW RAM REGION $400-$4FF GIVEN TO ZSMKIT
60 SYS$A000 : REM ZSM-INIT-ENGINE
70 REM SET UP THE DEFAULT INTERRUPT HANDLER
80 SYS$A054 : REM ZSMKIT-SETISR
90 REM NOW ZSMKIT IS ALL SET UP TO PLAY MUSIC
100 REM LOAD THE DEFAULT SONG. ZSMKIT OWNS BANK 1, SO LOAD SONG
110 BLOAD"CANYON.ZSM",8,2,$A000 : REM STARTING IN BANK 2
120 REM NOW TELL ZSMKIT WHERE THE SONG LIVES
130 REM USE ZSMKIT PRIORITY (SLOT) 0
140 BANK 1
150 POKE $30C,2:POKE $30D,0:SYS $A01B : REM ZSM-SETBANK
160 POKE $30C,$00:POKE $30E,$A0:POKE $30D,0 : SYS $A01E : REM ZSM-SETMEM
170 REM NOW WE'RE CLEAR TO START SONG PLAYBACK
180 POKE$30D,0 : REM PRIORITY (SLOT) 0
190 SYS$A006 : REM ZSM-PLAY
200 PRINT "TO STOP SONG TYPE: RUN 230"
210 PRINT "SONG DRIVER WILL STAY RESIDENT"
220 END
230 POKE$30D,0 : REM PRIORITY (SLOT) 0
240 SYS$A009 : REM ZSM-STOP
250 PRINT "TO CONTINUE SONG TYPE: RUN 180"
260 END

```

These are the entry points of this ZSMKit blob that can be used from BASIC.

Ensure that you have called `BANK` to point to the RAM bank where you have loaded ZSMKit before calling `SYS`, keeping in mind that BLOAD can and will change this value to reflect where the load ended.

See the [quick reference](..) in the README of the parent directory of this one for documentation for each of these calls.

```
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


```

Use the SYS communication locations provided by the BASIC interpreter to
pass register values.  `POKE` values in before `SYS` and optionally `PEEK` them after the `SYS` to check for return values.

```
$030C: Accumulator
$030D: X Register
$030E: Y Register
$030F: Status Register/Flags
```
