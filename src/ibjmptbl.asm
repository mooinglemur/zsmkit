.include "zsmkit.inc"

.segment "JMPTBL"
jmp zsm_init_engine ; $0810 / $0830 / $8C00
jmp zsm_tick    ; $0813 / $0833 / $8C03
jmp zsm_play    ; $0816 / $0836 / $8C06
jmp zsm_stop    ; $0819 / $0839 / $8C09
jmp zsm_rewind  ; $081C / $083C / $8C0C
jmp zsm_close   ; $081F / $083F / $8C0F
.ifdef ZSMKIT_ENABLE_STREAMING
jmp zsm_fill_buffers ; $0822 / $0842 / $8C12
jmp zsm_setlfs  ; $0825 / $0845 / $8C15
jmp zsm_setfile ; $0828 / $0848 / $8C18
jmp zsm_loadpcm ; $082B / $084B / $8C1B
.else
.repeat 4
sec
rts
nop
.endrepeat
.endif
jmp zsm_setmem  ; $082E / $084E / $8C1E
jmp zsm_setatten ; $0831 / $0851 / $8C21
jmp zsm_setcb    ; $0834 / $0854 / $8C24
jmp zsm_clearcb  ; $0837 / $0857 / $8C27
jmp zsm_getstate ; $083A / $085A / $8C2A
jmp zsm_setrate  ; $083D / $085D / $8C2D
jmp zsm_getrate  ; $0840 / $0860 / $8C30
jmp zsm_setloop  ; $0843 / $0863 / $8C33
jmp zsm_opmatten ; $0846 / $0866 / $8C36
jmp zsm_psgatten ; $0849 / $0869 / $8C39
jmp zsm_pcmatten ; $084C / $086C / $8C3C
jmp zsm_set_int_rate ; $084F / $086F / $8C3F
.repeat 3 ; for expansion
sec
rts
nop
.endrepeat
jmp zcm_setmem  ; $085B / $087B / $8C4B
jmp zcm_play    ; $085E / $087E / $8C4E
jmp zcm_stop    ; $0861 / $0881 / $8C51
jmp zsmkit_setisr    ; $0864 / $0884 / $8C54
jmp zsmkit_clearisr  ; $0867 / $0887 / $8C57
