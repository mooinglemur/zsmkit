# Define the compiler and flags
CC       = mos-cx16-clang
CXX      = mos-cx16-clang++
CFLAGS   = -Oz -flto -I . -Wall -Wextra -std=c23
CXXFLAGS = -Oz -flto -I . -Wall -Wextra
LDFLAGS  = -T link.ld
TEST     = test.prg
ZSMKIT   = zsmkit.o

# Default target
all: $(TEST)

# Compile zsmkit.o
$(ZSMKIT): zsmkit.c zsmkit.h
	$(CC) $(CFLAGS) -c zsmkit.c -o $(ZSMKIT)

# Compile and link the target
$(TEST): test.c $(ZSMKIT)
	$(CC) $(CFLAGS) test.c $(ZSMKIT) -o $(TEST) $(LDFLAGS)

# Clean up the build files
clean:
	rm -f $(TEST) $(TEST).elf $(ZSMKIT) 

run: $(TEST)
	x16emu -prg $(TEST) -run

# Phony targets
.PHONY: all clean run
