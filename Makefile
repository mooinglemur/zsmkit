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
INCBIN  := $(LIB)/8010.bin

default: all

all: lib

lib: $(LIBRARY)

incbin: $(INCBIN)

$(INCBIN): $(LIBRARY)
	$(AS) $(ASFLAGS) $(SRC)/ibjmptbl.asm -o $(OBJ)/jmptbl.o
	$(LD) $(LDFLAGS) -C 0810.cfg $(OBJ)/jmptbl.o $(LIBRARY) -o $@

$(LIBRARY): $(OBJS) | $(LIB) 
	$(AR) a $@ $(OBJS)

$(OBJ)/%.o: $(SRC)/%.s | $(OBJ)
	$(AS) $(ASFLAGS) $< -o $@

$(OBJ):
	$(MKDIR) $@

$(LIB):
	$(MKDIR) $@

.PHONY: clean run
clean:
	$(RM) $(OBJS) $(LIBRARY) $(INCBIN)


