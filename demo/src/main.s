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

	stx song3
	sty song3+1

	lda X16::Reg::RAMBank
	sta song3+2


	lda #filename4-filename3
	ldx #<filename3
	ldy #>filename3

	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx song3
	ldy song3+1
	lda #0

	jsr X16::Kernal::LOAD

	stx song4
	sty song4+1

	lda X16::Reg::RAMBank
	sta song4+2


	lda #filename5-filename4
	ldx #<filename4
	ldy #>filename4

	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx song4
	ldy song4+1
	lda #0

	jsr X16::Kernal::LOAD

	stx song5
	sty song5+1

	lda X16::Reg::RAMBank
	sta song5+2


	lda #filename6-filename5
	ldx #<filename5
	ldy #>filename5

	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx song5
	ldy song5+1
	lda #0

	jsr X16::Kernal::LOAD

	stx song6
	sty song6+1

	lda X16::Reg::RAMBank
	sta song6+2



	lda #filename7-filename6
	ldx #<filename6
	ldy #>filename6

	jsr X16::Kernal::SETNAM

	lda #2
	ldx #8
	ldy #2
	jsr X16::Kernal::SETLFS

	ldx song6
	ldy song6+1
	lda #0

	jsr X16::Kernal::LOAD


	lda song1+2
	sta X16::Reg::RAMBank

	lda song1
	ldy song1+1

	ldx #0
	jsr zsmkit::zsm_setmem

	ldx #0
	jsr zsmkit::zsm_play

	lda #0
	sta X16::Reg::ROMBank

	jsr X16::Kernal::PRIMM
	.byte "HELLO! WELCOME TO THE OPENING STAGE.",13
	.byte "PRESS RETURN WHEN YOU'RE READY TO PROCEED.",13,0

	jsr X16::Kernal::BASIN

	lda song2+2
	sta X16::Reg::RAMBank
	lda song2
	ldy song2+1
	ldx #1
	jsr zsmkit::zsm_setmem
	ldx #1
	jsr zsmkit::zsm_play
	ldx #1
	lda #$3f
	jsr zsmkit::zsm_setatten

	jsr X16::Kernal::PRIMM
	.byte 13,"YOU SLOWLY APPROACH A CURIOUS ENEMY.",13,0
ppapproach:
	wai
	wai
	ldx #1
	lda v2
	jsr zsmkit::zsm_setatten
	wai
	wai
	ldx #0
	lda v1
	jsr zsmkit::zsm_setatten

	inc v1
	lda v2
	cmp #$10
	beq :+
	dec v2
:
	lda v1
	cmp #$38

	bne ppapproach

	jsr X16::Kernal::PRIMM
	.byte 13,"IT IS ASLEEP. PRESS RETURN TO INCH CLOSER.",13,0

	jsr X16::Kernal::BASIN

ppapproach2:
	wai
	wai
	ldx #0
	lda v1
	jsr zsmkit::zsm_setatten

	inc v1
	lda v1
	cmp #$7f
	bne ppapproach2

	ldx #1
	jsr zsmkit::zsm_close

	lda #0
	ldx #0
	jsr zsmkit::zsm_setatten

	wai

	lda #0
	ldx #1
	jsr zsmkit::zsm_setatten

	wai

	lda song3+2
	sta X16::Reg::RAMBank
	lda song3
	ldy song3+1
	ldx #1
	jsr zsmkit::zsm_setmem
	ldx #1
	jsr zsmkit::zsm_play


	jsr X16::Kernal::PRIMM
	.byte 13,"OH NO! IT WOKE UP AND IS ATTACKING.",13
	.byte "BETTER WALK AWAY.",13,0

	jsr X16::Kernal::BASIN

	ldx #1
	jsr zsmkit::zsm_close

	jsr X16::Kernal::PRIMM
	.byte 13,"MAYBE YOU CAN FIND A STAR IF YOU PRESS PAUSE",13
	.byte "AND LOOK AT THE OVERVIEW OF THE STAGE",13,0

	jsr X16::Kernal::BASIN

	ldx #0
	jsr zsmkit::zsm_stop

	lda song6+2
	sta X16::Reg::RAMBank
	lda song6
	ldy song6+1
	ldx #1
	jsr zsmkit::zsm_setmem
	ldx #1
	jsr zsmkit::zsm_play

	ldy #30
:
	wai
	dey
	bne :-

	jsr X16::Kernal::PRIMM
	.byte 13,"LOOK, THERE IT IS!",13
	.byte "UNPAUSE AND GET OVER THERE!",13,0

	jsr X16::Kernal::BASIN

	ldx #1
	jsr zsmkit::zsm_rewind

	ldx #1
	jsr zsmkit::zsm_play

	ldx #0
	jsr zsmkit::zsm_play

	jsr X16::Kernal::PRIMM
	.byte 13,"JUMP UP AND HIT THE BOX",13,0

	jsr X16::Kernal::BASIN

	lda #$20
	ldx #0
	jsr zsmkit::zsm_setatten

	lda song4+2
	sta X16::Reg::RAMBank
	lda song4
	ldy song4+1
	ldx #1
	jsr zsmkit::zsm_setmem
	ldx #1
	jsr zsmkit::zsm_play

	ldy #255
:
	wai
	dey
	bne :-

	lda #0
	ldx #0
	jsr zsmkit::zsm_setatten

	jsr X16::Kernal::PRIMM
	.byte 13,"GRAB THE STAR!",13,0

	jsr X16::Kernal::BASIN

	lda song5+2
	sta X16::Reg::RAMBank
	lda song5
	ldy song5+1
	ldx #0
	jsr zsmkit::zsm_setmem
	ldx #0
	jsr zsmkit::zsm_play

	ldy #255
:
	wai
	dey
	bne :-

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
	.byte "SONG1.ZSM"
filename2:
	.byte "SONG2.ZSM"
filename3:
	.byte "SONG3.ZSM"
filename4:
	.byte "SONG4.ZSM"
filename5:
	.byte "SONG5.ZSM"
filename6:
	.byte "SONG6.ZSM"
filename7:
song1:
	.byte 0,0,0
song2:
	.byte 0,0,0
song3:
	.byte 0,0,0
song4:
	.byte 0,0,0
song5:
	.byte 0,0,0
song6:
	.byte 0,0,0
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
