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
.else
.repeat 3
rts
nop
nop
.endrepeat
.endif
jmp zsm_setmem  ; $082B / $084B
jmp zsm_setatten ; $082E / $084E
