.include "zsmkit.inc"

.segment "JMPTBL"
jmp zsm_init_engine ; $0810 / $0830
jmp zsm_tick    ; $0813 / $0833
jmp zsm_play    ; $0816 / $0836
jmp zsm_stop    ; $0819 / $0839
jmp zsm_rewind  ; $081C / $083C
jmp zsm_close   ; $081F / $083F
.ifdef ZSMKIT_ENABLE_STREAMING
jmp zsm_fill_buffers ; $0822 / $0842
jmp zsm_setlfs  ; $0825 / $0845
jmp zsm_setfile ; $0828 / $0848
jmp zsm_loadpcm ; $082B / $084B
.else
.repeat 4
sec
rts
nop
.endrepeat
.endif
jmp zsm_setmem  ; $082E / $084E
jmp zsm_setatten ; $0831 / $0851
jmp zsm_setcb    ; $0834 / $0854
jmp zsm_clearcb  ; $0837 / $0857
jmp zsm_getstate ; $083A / $085A
jmp zsm_setrate  ; $083D / $085D
jmp zsm_getrate  ; $0840 / $0860
jmp zsm_setloop  ; $0843 / $0863
jmp zsm_opmatten ; $0846 / $0866
jmp zsm_psgatten ; $0849 / $0869
jmp zsm_pcmatten ; $084C / $086C
.repeat 4 ; for expansion
sec
rts
nop
.endrepeat
jmp zcm_setmem  ; $085B / $087B
jmp zcm_play    ; $085E / $087E
jmp zcm_stop    ; $0861 / $0881
