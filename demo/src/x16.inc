.ifndef x16_inc
x16_inc = 1


.scope Vera
    .scope Reg
        AddrL      = $9F20    ; VRAM Address (7:0)
        AddrM      = $9F21    ; VRAM Address (15:8)
        AddrH      = $9F22    ; (7:4) addr inc (stride), (3) DECR, (2:1) unused, (0): VRAM Address (16)
        Data0      = $9F23    ; VRAM Data port 0
        Data1      = $9F24    ; VRAM Data port 1
        Ctrl       = $9F25    ; (7) reset, (6:2) unused, (1) DCSEL, (0) ADDRSEL
        IEN        = $9F26
        ISR        = $9F27
        IRQLineL   = $9F28
        DCVideo    = $9F29    ; DCSEL=0
        DCHStart   = $9F29    ; DCSEL=1
        DCHScale   = $9F2A    ; DCSEL=0
        DCHStop    = $9F2A    ; DCSEL=1
        DCVScale   = $9F2B    ; DCSEL=0
        DCVStart   = $9F2B    ; DCSEL=1
        DCBorder   = $9F2C    ; DCSEL=0
        DCVStop    = $9F2C    ; DCSEL=1
        L0Config   = $9F2D
        L0MapBase  = $9F2E
        L0TileBase = $9F2F
        L0HScrollL = $9F30
        L0HScrollH = $9F31
        L0VScrollL = $9F32
        L0VScrollH = $9F33
        L1Config   = $9F34
        L1MapBase  = $9F35
        L1TileBase = $9F36
        L1HScrollL = $9F37
        L1HScrollH = $9F38
        L1VScrollL = $9F39
        L1VScrollH = $9F3A
        AudioCtrl  = $9F3B
        AudioRate  = $9F3C
        AudioData  = $9F3D
        SPIData    = $9F3E
        SPICtrl    = $9F3F
    .endscope

    .scope Stride
        _0   = $0 << 4
        _1   = $1 << 4
        _2   = $2 << 4
        _4   = $3 << 4
        _8   = $4 << 4
        _16  = $5 << 4
        _32  = $6 << 4
        _64  = $7 << 4
        _128 = $8 << 4
        _256 = $9 << 4
        _512 = $A << 4
        _40  = $B << 4
        _80  = $C << 4
        _160 = $D << 4
        _320 = $E << 4
        _640 = $F << 4
    .endscope

    ; Layer config bit masks
    MapH32  = %00000000
    MapH64  = %01000000
    MapH128 = %10000000
    MapH256 = %11000000

    MapW32  = %00000000
    MapW64  = %00010000
    MapW128 = %00100000
    MapW256 = %00110000

    ; Layer modes, combines T256C, Bitmap mode, and Color Depth
    .scope TileMode
        _1_BPP_16  = %00000000
        _1_BPP_256 = %00001000
        _2_BPP     = %00000001
        _4_BPP     = %00000010
        _8_BPP     = %00000011
    .endscope
    .scope BitmapMode
        _1_BPP     = %00000100
        _2_BPP     = %00000101
        _4_BPP     = %00000110
        _8_BPP     = %00000111
    .endscope

    ; DC_VIDEO bit masks
    Layer1Enable  = %00100000
    Layer0Enable  = %00010000
    ChromaDisable = %00000100
    VGAOutput     = %00000001

    ; Tile width/height bit masks
    TileW8  = %00
    TileW16 = %01
    TileH8  = %00
    TileH16 = %10

    ; V_SCALE/H_SCALE
    ; Setting this value to 128 will output 1 output pixel for every input pixel.
    ;  Setting this to 64 will output 2 output pixels for every input pixel.
    Scale1X  = 128
    Scale2X  = 64
    Scale4X  = 32
    Scale8X  = 16

    ; VRAM Addresses
    VRAM_bitmap    = $00000
    VRAM_sprites   = $13000
    VRAM_text      = $1B000
    VRAM_charset   = $1F000
    VRAM_psg       = $1F9C0
    VRAM_palette   = $1FA00
    VRAM_sprattr   = $1FC00


.endscope

.scope X16
    .scope Reg
        r0   = $02
        r0L  = r0
        r0H  = r0+1
        r1   = $04
        r1L  = r1
        r1H  = r1+1
        r2   = $06
        r2L  = r2
        r2H  = r2+1
        r3   = $08
        r3L  = r3
        r3H  = r3+1
        r4   = $0A
        r4L  = r4
        r4H  = r4+1
        r5   = $0C
        r5L  = r5
        r5H  = r5+1
        r6   = $0E
        r6L  = r6
        r6H  = r6+1
        r7   = $10
        r7L  = r7
        r7H  = r7+1
        r8   = $12
        r8L  = r8
        r8H  = r8+1
        r9   = $14
        r9L  = r9
        r9H  = r9+1
        r10  = $16
        r10L = r10
        r10H = r10+1
        r11  = $18
        r11L = r11
        r11H = r11+1
        r12  = $1A
        r12L = r12
        r12H = r12+1
        r13  = $1C
        r13L = r13
        r13H = r13+1
        r14  = $1E
        r14L = r14
        r14H = r14+1
        r15  = $20
        r15L = r15
        r15H = r15+1

        GIF_ctrl = $9FB5

        ROMBank = $01
        RAMBank = $00

        .scope YM2151
            Ctrl = $9F40
            Data = $9F41
        .endscope
    .endscope

    .scope ROMBank
        Kernal   = 0
        Keyboard = 1
        CBDOS    = 2
        GEOS     = 3
        BASIC    = 4
        Monitor  = 5
        Charset  = 6
    .endscope

    .scope Vec
        ; RAM Vectors
        IRQVec      := $0314
        BRKVec      := $0316
        NMIVec      := $0318
        KbdVec      := $032E
        FETVec      := $03AF
        ;STAVec      := TBD
        ;CMPVec      := TBD
    .endscope

    SD_DEVICE   = 8 ; also host file system on emulator if no SD image mounted
    DISK_DEVICE = SD_DEVICE ; change if to be loaded off IEC device
    ; Banked Addresses

    RAM_WIN           = $A000
    RAM_WIN_SIZE      = $2000
    ROM_WIN           = $C000

    .scope Kernal
        ENTROPY_GET                   := $FECF
        CONSOLE_set_paging_message    := $FED5
        CONSOLE_put_image             := $FED8
        CONSOLE_init                  := $FEDB
        CONSOLE_put_char              := $FEDE
        CONSOLE_get_char              := $FEE1
        MEMORY_FILL                   := $FEE4
        MEMORY_COPY                   := $FEE7
        MEMORY_CRC                    := $FEEA
        MEMORY_DECOMPRESS             := $FEED
        SPRITE_set_image              := $FEF0
        SPRITE_set_position           := $FEF3
        FB_init                       := $FEF6
        FB_get_info                   := $FEF9
        FB_set_palette                := $FEFC
        FB_cursor_position            := $FEFF
        FB_cursor_next_line           := $FF02
        FB_get_pixel                  := $FF05
        FB_get_pixels                 := $FF08
        FB_set_pixel                  := $FF0B
        FB_set_pixels                 := $FF0E
        FB_set_8_pixels               := $FF11
        FB_set_8_pixels_opaque        := $FF14
        FB_fill_pixels                := $FF17
        FB_filter_pixels              := $FF1A
        FB_move_pixels                := $FF1D
        GRAPH_init                    := $FF20
        GRAPH_clear                   := $FF23
        GRAPH_set_window              := $FF26
        GRAPH_set_colors              := $FF29
        GRAPH_draw_line               := $FF2C
        GRAPH_draw_rect               := $FF2F
        GRAPH_move_rect               := $FF32
        GRAPH_draw_oval               := $FF35
        GRAPH_draw_image              := $FF38
        GRAPH_set_font                := $FF3B
        GRAPH_get_char_size           := $FF3E
        GRAPH_put_char                := $FF41
        MACPTR                        := $FF44
        ENTER_BASIC                   := $FF47
        CLOSE_ALL                     := $FF4A
        CLOCK_SET_DATE_TIME           := $FF4D
        CLOCK_GET_DATE_TIME           := $FF50
        JOYSTICK_SCAN                 := $FF53
        JOYSTICK_GET                  := $FF56
        SCREEN_MODE                   := $FF5F
        SCREEN_SET_CHARSET            := $FF62
        PFKEY                         := $FF65
        MOUSE_CONFIG                  := $FF68
        MOUSE_GET                     := $FF6B
        JSRFAR_kernal_addr            := $FF6E
        MOUSE_SCAN                    := $FF71
        FETCH                         := $FF74
        STASH                         := $FF77
        CMPARE                        := $FF7A
        PRIMM                         := $FF7D

        VERSION                        = $FF80
        SCINIT                        := $FF81
        IOINIT                        := $FF84
        RAMTAS                        := $FF87
        RESTOR                        := $FF8A
        LKUPLA                        := $FF8D
        SETMSG                        := $FF90
        SECOND                        := $FF93
        TKSA                          := $FF96
        MEMTOP                        := $FF99
        MEMBOT                        := $FF9C
        KBD_SCAN                      := $FF9F
        SETTMO                        := $FFA2
        IECIN                         := $FFA5
        IECOUT                        := $FFA8
        UNTALK                        := $FFAB
        UNLISTEN                      := $FFAE
        LISTEN                        := $FFB1
        TALK                          := $FFB4
        READST                        := $FFB7
        SETLFS                        := $FFBA
        SETNAM                        := $FFBD
        OPEN                          := $FFC0
        CLOSE                         := $FFC3
        CHKIN                         := $FFC6
        CHKOUT                        := $FFC9
        CLRCHN                        := $FFCC
        CHRIN                         := $FFCF
        BASIN                         := CHRIN ; alias
        CHROUT                        := $FFD2
        BSOUT                         := CHROUT ; alias
        LOAD                          := $FFD5
        SAVE                          := $FFD8
        SETTIM                        := $FFDB
        RDTIM                         := $FFDE
        STOP                          := $FFE1
        GETIN                         := $FFE4
        CLALL                         := $FFE7
        UDTIM                         := $FFEA
        SCREEN                        := $FFED
        PLOT                          := $FFF0
        IOBASE                        := $FFF3
    .endscope



.endscope

.scope YM2151
    .scope Reg
        TEST          = $01 ; [1] LFO RESET
        KON           = $08 ; [6:3] SN [2:0] CN
        NE_NFRQ       = $0F ; [7] NE [4:0] NFRQ
        LFRQ          = $18 ; [7:0] LFRQ
        PMD_AMD       = $19 ; [7] 1=PMD,0=AMD [6:0] PMD/AMD value
        CT_W          = $1B ; [7:6] CT [1:0] W

        RL_FL_CONNECT = $20 ; [7:6] RL [5:3] FL [2:0] CON
        KC            = $28 ; [6:4] OCT [3:0] NOTE
        KF            = $30 ; [7:2] KF
        PMS_AMS       = $38 ; [6:4] PMS [1:0] AMS

        DT1_MUL       = $40 ; [6:4] DT1 [3:0] MUL
        TL            = $60 ; [6:0] TL
        KS_AR         = $80 ; [7:6] KS [4:0] AR
        AMSEN_D1R     = $A0 ; [7] AMSEN [4:0] D1R
        DT2_D2R       = $C0 ; [7:6] DT2 [4:0] D2R
        D1L_RR        = $E0 ; [7:4] D1L [3:0] RR
    .endscope
.endscope



; BASIC Vectors
BASIC_PANIC       := $C000
BASIC_INIT        := $C003





;   Macros

.macro VERA_SET_ADDR addr, stride
   .ifnblank stride
      .if stride < 0
         lda #((^addr) | $08 | ((0-stride) << 4))
      .else
         lda #((^addr) | (stride << 4))
      .endif
   .else
      lda #(^addr) | $10
   .endif

   sta Vera::Reg::AddrH
   lda #(>addr)
   sta Vera::Reg::AddrM
   lda #(<addr)
   sta Vera::Reg::AddrL
.endmacro

.macro JSRFAR far_sr_addr, bank
    jsr X16::Kernal::JSRFAR_kernal_addr
    .addr far_sr_addr
    .byte bank
.endmacro

.endif
