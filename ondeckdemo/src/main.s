.macpack longbranch

.include "x16.inc"
.include "ascii_charmap.inc"

.segment "LOADADDR"
.word $0801

.segment "BASICSTUB"
.word entry-2
.byte $00,$00,$9e
.byte "2061"
.byte $00,$00,$00
.proc entry
	jmp main
.endproc

.scope zsmkit
.include "zsmkit.inc"
.endscope

.segment "BSS"
oldirq:
	.res 2
zsmkit_lowram:
	.res 256

ZSMKIT_BANK = 1

.segment "STARTUP"

.proc main
	lda #ZSMKIT_BANK
	sta X16::Reg::RAMBank
	lda #zsmkit_filename_end-zsmkit_filename
	ldx #<zsmkit_filename
	ldy #>zsmkit_filename
	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx #$00
	ldy #$a0
	lda #0
	jsr X16::Kernal::LOAD

	lda #ZSMKIT_BANK
	sta X16::Reg::RAMBank
	ldx #<zsmkit_lowram
	ldy #>zsmkit_lowram
	jsr zsmkit::zsm_init_engine

	jsr setup_handler

	lda #2
	sta X16::Reg::RAMBank
	sta song1+2

	lda #filename2-filename1
	ldx #<filename1
	ldy #>filename1

	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx #$00
	stx song1
	ldy #$a0
	sty song1+1
	lda #0

	jsr X16::Kernal::LOAD

	stx song2
	sty song2+1

	lda X16::Reg::RAMBank
	sta song2+2


	lda #filename3-filename2
	ldx #<filename2
	ldy #>filename2

	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx song2
	ldy song2+1
	lda #0

	jsr X16::Kernal::LOAD

	lda #ZSMKIT_BANK
	sta X16::Reg::RAMBank

	lda song1+2
	ldx #0
	jsr zsmkit::zsm_setbank

	lda song1
	ldy song1+1

	ldx #0
	jsr zsmkit::zsm_setmem

	ldx #0
	jsr zsmkit::zsm_play

	lda #0
	sta X16::Reg::ROMBank

repeat_it:

	jsr X16::Kernal::PRIMM
	.byte 13,"PRESS RETURN WHEN YOU'RE READY TO SWITCH SONGS.",13,0

	jsr X16::Kernal::BASIN
	jsr X16::Kernal::PRIMM
	.byte 13,"SWITCHING TO SONG2.",13,0

	lda song2+2
	ldx #0
	jsr zsmkit::zsm_set_ondeck_bank

	lda song2
	ldy song2+1
	ldx #0

	jsr zsmkit::zsm_set_ondeck_mem

	ldx #0
	clc
	jsr zsmkit::zsm_setloop



	jsr X16::Kernal::PRIMM
	.byte 13,"PRESS RETURN WHEN YOU'RE READY TO SWITCH SONGS.",13,0

	jsr X16::Kernal::BASIN
	jsr X16::Kernal::PRIMM
	.byte 13,"SWITCHING TO SONG1.",13,0


	lda song1+2
	ldx #0
	jsr zsmkit::zsm_set_ondeck_bank

	lda song1
	ldy song1+1
	ldx #0
	jsr zsmkit::zsm_set_ondeck_mem

	ldx #0
	clc
	jsr zsmkit::zsm_setloop


	jmp repeat_it


	jsr X16::Kernal::PRIMM
	.byte 13,"DEMO IS DONE, PRESS RETURN",13,0

	jsr X16::Kernal::BASIN

	sei

	lda oldirq
	sta X16::Vec::IRQVec
	lda oldirq+1
	sta X16::Vec::IRQVec+1

	cli

	lda #4
	sta X16::Reg::ROMBank

	rts
v1:
	.byte 0
v2:
	.byte $3f
filename1:
	.byte "RIFF1.ZSM"
filename2:
	.byte "RIFF2.ZSM"
filename3:
song1:
	.byte 0,0,0
song2:
	.byte 0,0,0
zsmkit_filename:
	.byte "zsmkit-a000.bin"
zsmkit_filename_end:
.endproc

.segment "CODE"

.proc setup_handler
	lda X16::Vec::IRQVec
	sta oldirq
	lda X16::Vec::IRQVec+1
	sta oldirq+1

	sei
	lda #<irqhandler
	sta X16::Vec::IRQVec
	lda #>irqhandler
	sta X16::Vec::IRQVec+1
	cli

	rts
.endproc

.proc irqhandler
	lda #35
	sta Vera::Reg::DCBorder
	lda X16::Reg::RAMBank
	pha
	lda #ZSMKIT_BANK
	sta X16::Reg::RAMBank
	lda #0
	jsr zsmkit::zsm_tick
	pla
	sta X16::Reg::RAMBank
	stz Vera::Reg::DCBorder
	jmp (oldirq)
.endproc
