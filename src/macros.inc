.ifndef __MACROS_INC__
.define __MACROS_INC__

.macro PRESERVE_ZP_PTR
	lda PTR+1
	pha
	lda PTR
	pha
.endmacro

.macro RESTORE_ZP_PTR
	pla
	sta PTR
	pla
	sta PTR+1
.endmacro

.endif
