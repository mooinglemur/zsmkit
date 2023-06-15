.include "zsmkit.inc"

.segment "JMPTBL"
jmp init_engine ; $0810
jmp zsm_tick    ; $0813
jmp zsm_play    ; $0816
jmp zsm_stop    ; $0819
jmp zsm_rewind  ; $081C
jmp zsm_close   ; $081F
jmp zsm_fill_buffers ; $0822
jmp zsm_setlfs  ; $0825
jmp zsm_setfile ; $0828
jmp zsm_setmem  ; $082B
jmp zsm_setatten ; $082E
