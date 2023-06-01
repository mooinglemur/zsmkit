.ifndef __MACROS_INC__
.define __MACROS_INC__

RAMBank = 0
ROMBank = 1

.macro PRESERVE_BANK_NO_CLOBBER
	php
	pha
	lda RAMBank
	cmp zsmkit_bank
	beq :+
	sta saved_bank
	lda zsmkit_bank
	sta RAMBank
:	pla
	plp
.endmacro

.macro PRESERVE_BANK_CLOBBER_A_P
	lda RAMBank
	cmp zsmkit_bank
	beq :+
	sta saved_bank
	lda zsmkit_bank
	sta RAMBank
:
.endmacro

.macro RESTORE_BANK
	lda saved_bank
	sta RAMBank
.endmacro

.macro PRESERVE_BANK_NO_CLOBBER_IRQ
	php
	pha
	lda RAMBank
	cmp zsmkit_bank
	beq :+
	sta saved_bank_irq
	lda zsmkit_bank
	sta RAMBank
:	pla
	plp
.endmacro

.macro PRESERVE_BANK_CLOBBER_A_P_IRQ
	lda RAMBank
	cmp zsmkit_bank
	beq :+
	sta saved_bank_irq
	lda zsmkit_bank
	sta RAMBank
:
.endmacro

.macro RESTORE_BANK_IRQ
	lda saved_bank_irq
	sta RAMBank
.endmacro


.endif
