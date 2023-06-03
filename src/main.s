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
	lda frames
	bne :+
	dec frames+1
:	dec frames
	lda frames
	ora frames+1
	bne loop
	lda #<filename2
	ldy #>filename2
	ldx #1
	jsr zsmkit::zsm_setfile
	ldx #1
	jsr zsmkit::zsm_play
	jsr zsmkit::zsm_fill_buffers
	bra loop
filename:
	.byte "LIVINGROCKS.ZSM",0
filename2:
	.byte "FANFARE.ZSM",0
frames:
	.word 600
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