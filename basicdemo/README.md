# BASIC demo

This example uses a binary blob of ZSMKit loaded at the end of low RAM. It allows for uninterrupted playback during your BASIC program.

```BASIC
10 REM SET $8C00 AS TOP OF BASIC RAM. THIS IS WHERE ZSMKIT LIB WILL GO
20 POKE$30F,1:SYS$FF99 : REM FETCH BANK COUNT IN ".A" REGISTER
30 POKE$30D,$00:POKE$30E,$8C:POKE$30F,0:SYS$FF99
40 CLR: REM CLEAR VARIABLES, WHICH RE-READS MEMTOP
50 BLOAD"ZSMKIT8C00.BIN",8,1,$8C00 : REM LOAD ZSMKIT LIB
60 REM INITIALIZE ZSMKIT
70 POKE$30C,1 : REM RAM BANK 1 IS GIVEN TO ZSMKIT
80 SYS$8C00 : REM ZSM-INIT-ENGINE
90 REM SET UP THE DEFAULT INTERRUPT HANDLER
100 SYS$8C54 : REM ZSMKIT-SETISR
110 REM NOW ZSMKIT IS ALL SET UP TO PLAY MUSIC
120 REM LOAD THE DEFAULT SONG. ZSMKIT OWNS BANK 1, SO LOAD SONG
130 BLOAD"CANYON.ZSM",8,2,$A000 : REM STARTING IN BANK 2
140 REM NOW TELL ZSMKIT WHERE THE SONG LIVES
150 REM USE ZSMKIT PRIORITY (SLOT) 0
160 BANK 2:POKE$30D,0:POKE$30C,$00:POKE$30E,$A0
170 SYS$8C1E : REM ZSM-SETMEM
180 REM NOW WE'RE CLEAR TO START SONG PLAYBACK
190 POKE$30D,0 : REM PRIORITY (SLOT) 0
200 SYS$8C06 : REM ZSM-PLAY
210 PRINT "TO STOP SONG TYPE: RUN 500"
220 PRINT "SONG DRIVER WILL STAY RESIDENT"
230 END
500 POKE$30D,0 : REM PRIORITY (SLOT) 0
510 SYS$8C09 : REM ZSM-STOP
520 PRINT "TO CONTINUE SONG TYPE: RUN 190"
530 END
```

These are the entry points of this ZSMKit blob that can be used from BASIC.
Use the SYS communication locations provided by the BASIC interpreter to
pass register values.

See the [quick reference](..) in the README of the parent directory of this one for documentation for each of these calls.

```
    $030C: Accumulator
    $030D: X Register
    $030E: Y Register
    $030F: Status Register/Flags
```

```
    zsm_init_engine  = $8C00
    zsm_tick         = $8C03
    zsm_play         = $8C06
    zsm_stop         = $8C09
    zsm_rewind       = $8C0C
    zsm_close        = $8C0F
    zsm_setmem       = $8C1E
    zsm_setatten     = $8C21
    zsm_setcb        = $8C24
    zsm_clearcb      = $8C27
    zsm_getstate     = $8C2A
    zsm_setrate      = $8C2D
    zsm_getrate      = $8C30
    zsm_setloop      = $8C33
    zsm_opmatten     = $8C36
    zsm_psgatten     = $8C39
    zsm_pcmatten     = $8C3C

    zcm_setmem       = $8C4B
    zcm_play         = $8C4E
    zcm_stop         = $8C51

    zsmkit_setisr    = $8C54
    zsmkit_clearisr  = $8C57
```
