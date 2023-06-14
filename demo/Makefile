UC = $(shell echo '$1' | tr '[:lower:]' '[:upper:]')

PROJECT	:= demo
AS		:= ca65
LD		:= ld65
AR		:= ar65
MKDIR	:= mkdir -p
RMDIR	:= rmdir -p
CONFIG  := ./$(PROJECT).cfg
ASFLAGS	:= --cpu 65C02 -g
LDFLAGS	:= -C $(CONFIG)
SRC		:= ./src
OBJ		:= ./obj
SRCS	:= $(wildcard $(SRC)/*.s)
LIBS	:= $(wildcard $(LIB)/*.lib)
OBJS    := $(patsubst $(SRC)/%.s,$(OBJ)/%.o,$(SRCS))
EXE		:= $(call UC,$(PROJECT).PRG)
SDCARD	:= ./sdcard.img
MAPFILE := ./$(PROJECT).map
SYMFILE := ./$(PROJECT).sym
LIBRARY := ../lib/zsmkit.lib

default: all

all: $(LIBRARY) $(EXE)

$(LIBRARY):
	cd .. && make

$(EXE): $(OBJS) $(CONFIG)
	$(LD) $(LDFLAGS) $(OBJS) -m $(MAPFILE) -Ln $(SYMFILE) $(LIBRARY) -o $@ 

$(OBJ)/%.o: $(SRC)/%.s | $(OBJ)
	$(AS) $(ASFLAGS) $< -o $@

$(OBJ):
	$(MKDIR) $@

$(SDCARD): $(EXE)
	$(RM) $(SDCARD)
	truncate -s 100M $(SDCARD)
	parted -s $(SDCARD) mklabel msdos mkpart primary fat32 2048s -- -1
	mformat -i $(SDCARD)@@1M -v $(call UC,$(PROJECT)) -F
	mcopy -i $(SDCARD)@@1M -o -m $(EXE) ::
	mcopy -i $(SDCARD)@@1M -o -m *.ZSM ::

.PHONY: clean run
clean:
	$(RM) $(EXE) $(OBJS) $(SDCARD) $(MAPFILE) $(SYMFILE)

box: $(EXE) $(SDCARD)
	SDL_AUDIODRIVER=alsa box16 -sdcard $(SDCARD) -prg $(EXE) -run

run: $(EXE) $(SDCARD)
	x16emu -sdcard $(SDCARD) -prg $(EXE) -debug -scale 2 -run
	
