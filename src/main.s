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

	lda #<filename
	ldy #>filename
	ldx #0
	jsr zsmkit::zsm_setfile
	ldx #0
	jsr zsmkit::zsm_play
	jsr zsmkit::zsm_fill_buffers
	jsr zsmkit::zsm_fill_buffers

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
	bra loop
check2:
	lda frames2
	bne :+
	dec frames2+1
:	dec frames2
	lda frames2
	ora frames2+1
	bne loop
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
	lda #$20
	jsr zsmkit::zsm_setatten
	bra loop

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