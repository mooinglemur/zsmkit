.macpack longbranch

.include "x16.inc"

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

.segment "STARTUP"

.proc main
	lda #1
	jsr zsmkit::init_engine

	lda #2
	sta Vera::Reg::Ctrl
	lda #($A0-1)
	sta Vera::Reg::DCHStop
	stz Vera::Reg::Ctrl

	jsr setup_handler

	lda #2
	sta X16::Reg::RAMBank

	lda #filename2-filename-1
	ldx #<filename
	ldy #>filename

	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx #$00
	ldy #$a0
	lda #0

	jsr X16::Kernal::LOAD

	lda #2
	sta X16::Reg::RAMBank

	lda #$00
	ldy #$a0

	ldx #0	
	jsr zsmkit::zsm_setmem

	ldx #0
	jsr zsmkit::zsm_play

loop:
	stz Vera::Reg::DCBorder
	wai
	lda #1
	sta Vera::Reg::DCBorder
	jsr zsmkit::zsm_fill_buffers
	lda frames1
	bne :+
	dec frames1+1
:	dec frames1
	lda frames1
	ora frames1+1
	bne check2
	lda #'!'
	jsr X16::Kernal::BSOUT
	lda #<filename2
	ldy #>filename2
	ldx #1
	jsr zsmkit::zsm_setfile
	ldx #1
	jsr zsmkit::zsm_play
	jsr zsmkit::zsm_fill_buffers
	jsr zsmkit::zsm_fill_buffers
	ldx #0
	lda #$28
	jsr zsmkit::zsm_setatten
	bra loop
check2:
	lda frames2
	bne :+
	dec frames2+1
:	dec frames2
	lda frames2
	ora frames2+1
	bne check3
	lda #'!'
	jsr X16::Kernal::BSOUT
	lda #<filename3
	ldy #>filename3
	ldx #2
	jsr zsmkit::zsm_setfile
	ldx #2
	jsr zsmkit::zsm_play
	jsr zsmkit::zsm_fill_buffers
	ldx #1
	jsr zsmkit::zsm_stop
	bra loop
check3:
	lda frames3
	bne :+
	dec frames3+1
:	dec frames3
	lda frames3
	ora frames3+1
	jne loop
	lda #'!'
	jsr X16::Kernal::BSOUT
	ldx #0
	lda #0
	jsr zsmkit::zsm_setatten
	jmp loop


filename:
	.byte "SONG1.ZSM",0
filename2:
	.byte "SONG2.ZSM",0
filename3:
	.byte "SONG3.ZSM",0
frames1:
	.word 600
frames2:
	.word 1800
frames3:
	.word 2100
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
	jsr zsmkit::zsm_tick
	jmp (oldirq)
.endproc