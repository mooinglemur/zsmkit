DEFINES =

# Disabled to save space as most don't plan to stream ZSMs from disk
# Saves about 1.5kB of low RAM
#DEFINES += -D ZSMKIT_ENABLE_STREAMING

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
BIN     := $(LIB)/zsmkit-a000.bin
MAPFILE := ./$(PROJECT).map
SYMFILE := ./$(PROJECT).sym


default: all

all: $(BIN)

$(BIN): $(OBJS)
	$(LD) $(LDFLAGS) -m $(MAPFILE) -Ln $(SYMFILE) -C zsmkit.cfg $(OBJS) -o $@

$(OBJ)/%.o: $(SRC)/%.s | $(OBJ)
	$(AS) $(ASFLAGS) $(DEFINES) $< -o $@

$(OBJ):
	$(MKDIR) $@

$(LIB):
	$(MKDIR) $@

.PHONY: clean run
clean:
	$(RM) $(OBJS) $(BIN)
