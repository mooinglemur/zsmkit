# Define the compiler and flags
CXX = mos-cx16-clang++
CXXFLAGS = -Oz -flto -I . -Wall -Wno-c23-extensions -Wextra
LDFLAGS = -T link.ld
TARGET = test.prg
SRC = test.cc

# Default target
all: $(TARGET)

# Compile and link the target
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

# Clean up the build files
clean:
	rm -f $(TARGET) 

run: $(TARGET)
	x16emu -prg $(TARGET) -run

# Phony targets
.PHONY: all clean run
