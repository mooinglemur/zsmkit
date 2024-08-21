# Define the compiler and flags
CC = mos-cx16-clang
CXX = mos-cx16-clang++
CXXFLAGS = -Oz -flto -I . -Wall -Wno-c23-extensions -Wextra
LDFLAGS = -T link.ld
TARGET = test.prg
ZSMKIT = zsmkit.o

# Default target
all: $(TARGET)

# Compile zsmkit.o
$(ZSMKIT): zsmkit.c zsmkit.h
	$(CC) $(CXXFLAGS) -c zsmkit.c -o $(ZSMKIT)

# Compile and link the target
$(TARGET): test.cc $(ZSMKIT)
	$(CXX) $(CXXFLAGS) test.cc $(ZSMKIT) -o $(TARGET) $(LDFLAGS)

# Clean up the build files
clean:
	rm -f $(TARGET) $(TARGET).elf $(ZSMKIT) 

run: $(TARGET)
	x16emu -prg $(TARGET) -run

# Phony targets
.PHONY: all clean run
