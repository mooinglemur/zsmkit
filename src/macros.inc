.ifndef __MACROS_INC__
.define __MACROS_INC__

.macro PRESERVE_ZP_PTR
	lda PTR+1
	pha
	lda PTR
	pha
.endmacro

.macro PRESERVE_ZP_PTR_TICK
	lda PTR+1
	sta zp_preserve_tick+1
	lda PTR
	sta zp_preserve_tick
.endmacro

.macro RESTORE_ZP_PTR
	pla
	sta PTR
	pla
	sta PTR+1
.endmacro

.macro RESTORE_ZP_PTR_TICK
	lda zp_preserve_tick
	sta PTR
	lda zp_preserve_tick+1
	sta PTR+1
.endmacro

.endif
