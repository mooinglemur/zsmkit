DEFINES =

# Comment this to save space if you don't plan to stream ZSMs from disk without
# loading them in their entirety
DEFINES += -D ZSMKIT_ENABLE_STREAMING

UC = $(shell echo '$1' | tr '[:lower:]' '[:upper:]')

PROJECT	:= zsmkit
AS		:= ca65
LD		:= ld65
AR		:= ar65
MKDIR	:= mkdir -p
RMDIR	:= rmdir -p
ASFLAGS	:= --cpu 65C02 -g
SRC		:= ./src
OBJ		:= ./obj
LIB		:= ./lib
SRCS	:= $(wildcard $(SRC)/*.s)
OBJS    := $(patsubst $(SRC)/%.s,$(OBJ)/%.o,$(SRCS))
EXE		:= $(call UC,$(PROJECT).PRG)
LIBRARY := $(LIB)/$(PROJECT).lib
INCBIN1 := $(LIB)/zsmkit-0810.bin
INCBIN2 := $(LIB)/zsmkit-0830.bin
BASBIN  := $(LIB)/zsmkit-8c00.bin


default: all

all: library

library: $(LIBRARY)

incbin: $(INCBIN1) $(INCBIN2)

basicbin: $(BASBIN)

$(INCBIN1): $(LIBRARY) $(OBJ)/jmptbl.o
	$(LD) $(LDFLAGS) -C 0810.cfg $(OBJ)/jmptbl.o $(LIBRARY) -o $@

$(INCBIN2): $(LIBRARY) $(OBJ)/jmptbl.o
	$(LD) $(LDFLAGS) -C 0830.cfg $(OBJ)/jmptbl.o $(LIBRARY) -o $@

$(BASBIN): $(LIBRARY) $(OBJ)/jmptbl.o
	$(LD) $(LDFLAGS) -C 8c00.cfg $(OBJ)/jmptbl.o $(LIBRARY) -o $@

$(OBJ)/jmptbl.o:
	$(AS) $(ASFLAGS) $(SRC)/ibjmptbl.asm $(DEFINES) -o $(OBJ)/jmptbl.o


$(LIBRARY): $(OBJS) | $(LIB) 
	$(AR) a $@ $(OBJS)

$(OBJ)/%.o: $(SRC)/%.s | $(OBJ)
	$(AS) $(ASFLAGS) $(DEFINES) $< -o $@

$(OBJ):
	$(MKDIR) $@

$(LIB):
	$(MKDIR) $@

.PHONY: clean run
clean:
	$(RM) $(OBJS) $(OBJ)/jmptbl.o $(LIBRARY) $(INCBIN1) $(INCBIN2) $(BASBIN)


