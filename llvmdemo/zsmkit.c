// MIT License

// Copyright (c) 2024 Mikael Lund aka Wombat

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// ZSMKit wrapper for playback with LLVM-MOS C/C++

#include <cx16.h>
#include <stdint.h>
#include <zsmkit.h>

#define ZSM_ADDR 0x8c00
#define ZSM_INIT_ENGINE ZSM_ADDR + 0x00
#define ZSM_TICK ZSM_ADDR + 0x03
#define ZSM_PLAY ZSM_ADDR + 0x06
#define ZSM_STOP ZSM_ADDR + 0x09
#define ZSM_REWIND ZSM_ADDR + 0x0C
#define ZSM_CLOSE ZSM_ADDR + 0x0F
#define ZSM_FILL_BUFFERS ZSM_ADDR + 0x12
#define ZSM_SETLFS ZSM_ADDR + 0x15
#define ZSM_SETFILE ZSM_ADDR + 0x18
#define ZSM_LOADPCM ZSM_ADDR + 0x1B
#define ZSM_SETMEM ZSM_ADDR + 0x1E
#define ZSM_SETATTEN ZSM_ADDR + 0x21
#define ZSM_SETCB ZSM_ADDR + 0x24
#define ZSM_CLEARCB ZSM_ADDR + 0x27
#define ZSM_GETSTATE ZSM_ADDR + 0x2A
#define ZSM_SETRATE ZSM_ADDR + 0x2D
#define ZSM_GETRATE ZSM_ADDR + 0x30
#define ZSM_SETLOOP ZSM_ADDR + 0x33
#define ZSM_OPMATTEN ZSM_ADDR + 0x36
#define ZSM_PSGATTEN ZSM_ADDR + 0x39
#define ZSM_PCMATTEN ZSM_ADDR + 0x3C
#define ZSM_SET_INT_RATE ZSM_ADDR + 0x3F
#define ZCM_SETMEM ZSM_ADDR + 0x4B
#define ZCM_PLAY ZSM_ADDR + 0x4E
#define ZCM_STOP ZSM_ADDR + 0x51
#define ZSMKIT_SETISR ZSM_ADDR + 0x54
#define ZSMKIT_CLEARISR ZSM_ADDR + 0x57

#define xstr(s) str(s)
#define str(s) #s

// Inputs: .A = RAM bank to assign to ZSMKit
// This routine must be called once before any other library routines are called
// in order to initialize the state of the engine.
void zsm_init_engine(const uint8_t bank) {
  __attribute__((leaf)) asm volatile(
      "jsr " xstr(ZSM_INIT_ENGINE) "\n" ::"a"(bank)
      : "x", "y", "p");
}

// Inputs: .X = priority, .A .Y = memory location (lo hi), $00 = RAM bank
// Prior to calling, set the active RAM bank ($00) to the bank where the ZSM
// data starts. This function sets up the song pointers and parses the header
// based on a ZSM that was previously loaded into RAM. If the song is deemed
// valid, it marks the priority slot as playable.
void zsm_setmem(const uint8_t priority, const uint16_t addr,
                const uint8_t bank) {
  RAM_BANK = bank;
  __attribute__((leaf)) asm volatile(
      "jsr " xstr(ZSM_SETMEM) "\n" ::"x"(priority), "a"((uint8_t)(addr & 0xFF)),
      "y"((uint8_t)((addr >> 8) & 0xFF))
      : "p");
}

// Inputs: .A = 0 (tick music data and PCM)
//         .A = 1 (tick PCM only)
//         .A = 2 (tick music data only)
void zsm_tick(const uint8_t what) {
  __attribute__((leaf)) asm volatile("jsr " xstr(ZSM_TICK) "\n" ::"a"(what)
                                     : "x", "y", "p");
}

void zsm_play(const uint8_t priority) {
  __attribute__((leaf)) asm volatile("jsr " xstr(ZSM_PLAY) "\n" ::"x"(priority)
                                     : "a", "y", "p");
}

void zsm_stop(const uint8_t priority) {
  __attribute__((leaf)) asm volatile("jsr " xstr(ZSM_STOP) "\n" ::"x"(priority)
                                     : "a", "y", "p");
}

void zsm_rewind(const uint8_t priority) {
  __attribute__((leaf)) asm volatile(
      "jsr " xstr(ZSM_REWIND) "\n" ::"x"(priority)
      : "a", "y", "p");
}

void zsm_close(const uint8_t priority) {
  __attribute__((leaf)) asm volatile("jsr " xstr(ZSM_CLOSE) "\n" ::"x"(priority)
                                     : "a", "y", "p");
}

// Inputs: .X = priority, .A = attenuation value
void zsm_setatten(const uint8_t priority, const uint8_t attenuation) {
  __attribute__((leaf)) asm volatile(
      "jsr " xstr(ZSM_SETATTEN) "\n" ::"x"(priority), "a"(attenuation)
      : "y", "p");
}

// Inputs: .X = priority, .A .Y = pointer to callback, $00 = RAM bank
void zsm_setcb(const uint8_t priority, const uint16_t callback,
               const uint8_t bank) {
  RAM_BANK = bank;
  __attribute__((leaf)) asm volatile(
      "jsr " xstr(ZSM_SETCB) "\n" ::"x"(priority), "a"((uint8_t)(callback)),
      "y"((uint8_t)(callback >> 8))
      : "p");
}

void zsm_clearcb(const uint8_t priority) {
  __attribute__((leaf)) asm volatile(
      "jsr " xstr(ZSM_CLEARCB) "\n" ::"x"(priority)
      : "a", "y", "p");
}

// Inputs: .X = priority
// Outputs: .C = playing, Z = not playable, .A .Y = (lo hi) loop counter
struct ZsmState zsm_getstate(const uint8_t priority) {
  struct ZsmState state;
  __attribute__((leaf)) asm volatile(
      "jsr " xstr(ZSM_GETSTATE) "\n"
                                "php\n"    // P -> stack
                                "ta%2\n"   // A -> X -> loopcnt_lo
                                "pla\n"    // P -> A
                                "pha\n"    // A(=P) -> stack
                                "lsr\n"    // extract zero
                                "and #1\n" // A = 1 if Z is set
                                "sta %3\n" // A -> r -> not_playable
                                "plp\n"    // restore P
                                "lda #0\n" // extract carry
                                "adc #0\n" // C -> A -> playing
      : "=a"(state.playing), "=y"(state.loopcnt_hi), "=x"(state.loopcnt_lo),
        "=r"(state.not_playable)
      : "x"(priority)
      : "p");
  return state;
}

// Generated with `xxd -i ../lib/zsmkit-8c00.bin`.
// Alternatively use `#embed "../lib/zsmkit-8c00.bin"`
// MUST be placed at $8c00 using a custom linker script!
__attribute__((section(".zsm_section"),
               used)) static const uint8_t zsmkitinc[] = {
    0x4c, 0x9d, 0x8c, 0x4c, 0x3e, 0x8d, 0x4c, 0x7d, 0x99, 0x4c, 0x0d, 0x99,
    0x4c, 0x8d, 0x98, 0x4c, 0xdc, 0x98, 0x38, 0x60, 0xea, 0x38, 0x60, 0xea,
    0x38, 0x60, 0xea, 0x38, 0x60, 0xea, 0x4c, 0x03, 0x9a, 0x4c, 0x4c, 0x98,
    0x4c, 0x6e, 0x96, 0x4c, 0x99, 0x96, 0x4c, 0x4c, 0x96, 0x4c, 0xd4, 0x96,
    0x4c, 0xf3, 0x96, 0x4c, 0x0b, 0x97, 0x4c, 0x8c, 0x97, 0x4c, 0xe0, 0x97,
    0x4c, 0x34, 0x98, 0x4c, 0xac, 0x96, 0x38, 0x60, 0xea, 0x38, 0x60, 0xea,
    0x38, 0x60, 0xea, 0x4c, 0xbf, 0x8d, 0x4c, 0xe9, 0x8d, 0x4c, 0x6c, 0x8e,
    0x4c, 0xf6, 0x8c, 0x4c, 0x1b, 0x8d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x08, 0x78, 0x8d, 0x5a, 0x8c, 0xa5, 0x01, 0x48, 0xa9, 0x0a, 0x85,
    0x01, 0x20, 0x9f, 0xc0, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c,
    0x85, 0x00, 0xa2, 0x00, 0x9c, 0xc1, 0x8c, 0xa9, 0xa0, 0x8d, 0xc2, 0x8c,
    0x9e, 0x00, 0xa0, 0xe8, 0xd0, 0xfa, 0xc9, 0xa7, 0xb0, 0x09, 0xad, 0xc2,
    0x8c, 0x1a, 0x8d, 0xc2, 0x8c, 0x80, 0xed, 0xa9, 0x3c, 0x8d, 0x15, 0xa7,
    0x9c, 0x16, 0xa7, 0xa2, 0x01, 0x20, 0xa5, 0xc0, 0x8d, 0x14, 0xa7, 0xc9,
    0x01, 0xd0, 0x02, 0xa2, 0x09, 0x8e, 0x23, 0x93, 0x68, 0x85, 0x01, 0xad,
    0x5b, 0x8c, 0x85, 0x00, 0x28, 0x60, 0xea, 0x08, 0x78, 0xa9, 0xea, 0x8d,
    0x1b, 0x8d, 0xa9, 0x60, 0x8d, 0xf6, 0x8c, 0xad, 0x14, 0x03, 0x8d, 0x3c,
    0x8d, 0xad, 0x15, 0x03, 0x8d, 0x3d, 0x8d, 0xa9, 0x36, 0x8d, 0x14, 0x03,
    0xa9, 0x8d, 0x8d, 0x15, 0x03, 0x28, 0x60, 0x60, 0x08, 0x78, 0xa9, 0x60,
    0x8d, 0x1b, 0x8d, 0xa9, 0xea, 0x8d, 0xf6, 0x8c, 0xad, 0x3c, 0x8d, 0x8d,
    0x14, 0x03, 0xad, 0x3d, 0x8d, 0x8d, 0x15, 0x03, 0x28, 0x60, 0xa9, 0x00,
    0x20, 0x3e, 0x8d, 0x4c, 0xff, 0xff, 0x8d, 0x7a, 0x8d, 0xa5, 0x00, 0x8d,
    0x5c, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xa5, 0x01, 0x8d, 0xb5, 0x8d,
    0xa9, 0x0a, 0x85, 0x01, 0xad, 0x25, 0x9f, 0x8d, 0xb0, 0x8d, 0x9c, 0x25,
    0x9f, 0xad, 0x20, 0x9f, 0x8d, 0xab, 0x8d, 0xad, 0x21, 0x9f, 0x8d, 0xa6,
    0x8d, 0xad, 0x22, 0x9f, 0x8d, 0xa1, 0x8d, 0xa9, 0x01, 0x8d, 0x22, 0x9f,
    0xa9, 0xf9, 0x8d, 0x21, 0x9f, 0xa9, 0xff, 0x29, 0x01, 0xd0, 0x17, 0x20,
    0xc3, 0x94, 0x20, 0x6a, 0x95, 0xa2, 0x03, 0x8e, 0xbe, 0x8d, 0x20, 0x3d,
    0x92, 0xae, 0xbe, 0x8d, 0xca, 0x8e, 0xbe, 0x8d, 0x10, 0xf4, 0xad, 0x7a,
    0x8d, 0x29, 0x02, 0xd0, 0x03, 0x20, 0x97, 0x90, 0xa9, 0xff, 0x8d, 0x22,
    0x9f, 0xa9, 0xff, 0x8d, 0x21, 0x9f, 0xa9, 0xff, 0x8d, 0x20, 0x9f, 0xa9,
    0xff, 0x8d, 0x25, 0x9f, 0xa9, 0xff, 0x85, 0x01, 0xad, 0x5c, 0x8c, 0x85,
    0x00, 0x60, 0x00, 0x8d, 0xd6, 0x8d, 0xa5, 0x00, 0x8d, 0xdf, 0x8d, 0xa5,
    0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xe0, 0x20, 0xb0,
    0x0e, 0xa9, 0x00, 0x9d, 0xa3, 0xa6, 0x98, 0x9d, 0xc3, 0xa6, 0xa9, 0x00,
    0x9d, 0x83, 0xa6, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0x29, 0x0f, 0x09,
    0x80, 0x8d, 0x4a, 0x8e, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c,
    0x85, 0x00, 0xe0, 0x20, 0xb0, 0x68, 0xbd, 0xc3, 0xa6, 0xf0, 0x63, 0x8d,
    0xdc, 0x9c, 0xbd, 0xa3, 0xa6, 0x8d, 0xdb, 0x9c, 0xbd, 0x83, 0xa6, 0x85,
    0x00, 0xa2, 0x00, 0x20, 0xda, 0x9c, 0xc9, 0x00, 0xd0, 0x4c, 0xe8, 0xe0,
    0x03, 0x90, 0xf4, 0x08, 0x78, 0xa2, 0x05, 0x20, 0xda, 0x9c, 0x48, 0xca,
    0xd0, 0xf9, 0xa5, 0x00, 0x48, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x68, 0x8d,
    0x76, 0xa6, 0xad, 0xdb, 0x9c, 0x8d, 0x77, 0xa6, 0xad, 0xdc, 0x9c, 0x8d,
    0x78, 0xa6, 0x68, 0x8d, 0x3c, 0x9f, 0x68, 0x29, 0x30, 0x09, 0x8f, 0x8d,
    0x3b, 0x9f, 0x68, 0x8d, 0x7b, 0xa6, 0x68, 0x8d, 0x7a, 0xa6, 0x68, 0x8d,
    0x79, 0xa6, 0xa9, 0x80, 0x8d, 0x75, 0xa6, 0x8d, 0x74, 0xa6, 0x9c, 0x7f,
    0xa6, 0x28, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0xa5, 0x00, 0x8d, 0x5b,
    0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x08, 0x78, 0xad, 0x75, 0xa6, 0xf0,
    0x0b, 0xad, 0x74, 0xa6, 0x10, 0x06, 0x8d, 0x3b, 0x9f, 0x9c, 0x75, 0xa6,
    0x28, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0xdd, 0x64, 0xa6, 0xf0, 0x05,
    0x90, 0x03, 0x4c, 0x02, 0x90, 0xa8, 0xbd, 0x54, 0xa6, 0xd0, 0x03, 0x4c,
    0x01, 0x90, 0xad, 0x75, 0xa6, 0xf0, 0x08, 0xec, 0x74, 0xa6, 0xb0, 0x03,
    0x4c, 0x01, 0x90, 0xad, 0x3b, 0x9f, 0x29, 0x3f, 0x8d, 0xd6, 0x8e, 0xec,
    0x74, 0xa6, 0xf0, 0x19, 0xbd, 0x80, 0xa5, 0x29, 0x0f, 0x38, 0xfd, 0x88,
    0xa5, 0x10, 0x02, 0xa9, 0x00, 0x8d, 0xd6, 0x8e, 0xbd, 0x84, 0xa5, 0x8d,
    0x3c, 0x9f, 0x8e, 0x74, 0xa6, 0xa9, 0xff, 0x09, 0x80, 0x8d, 0x3b, 0x9f,
    0x8d, 0x75, 0xa6, 0xbd, 0x5c, 0xa6, 0x8d, 0xf7, 0x9c, 0xbd, 0x60, 0xa6,
    0x8d, 0xf8, 0x9c, 0xbd, 0x58, 0xa6, 0x85, 0x00, 0x98, 0x9c, 0x0b, 0x90,
    0x0a, 0x2e, 0x0b, 0x90, 0x0a, 0x2e, 0x0b, 0x90, 0x0a, 0x2e, 0x0b, 0x90,
    0x0a, 0x2e, 0x0b, 0x90, 0x6d, 0xf7, 0x9c, 0x8d, 0xf7, 0x9c, 0xad, 0x0b,
    0x90, 0x6d, 0xf8, 0x9c, 0x8d, 0xf8, 0x9c, 0x20, 0x01, 0x9d, 0x8c, 0x0b,
    0x90, 0x20, 0xf6, 0x9c, 0xcd, 0x0b, 0x90, 0xf0, 0x03, 0x4c, 0x02, 0x90,
    0x20, 0xf6, 0x9c, 0x29, 0x30, 0x8d, 0x0b, 0x90, 0xad, 0x3b, 0x9f, 0x29,
    0x0f, 0x0d, 0x0b, 0x90, 0x8d, 0x3b, 0x9f, 0xa2, 0x0a, 0x20, 0xf6, 0x9c,
    0x48, 0xca, 0xd0, 0xf9, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x68, 0x8d, 0x82,
    0xa6, 0x0a, 0x0a, 0x0a, 0x8d, 0x7c, 0xa6, 0x68, 0x8d, 0x81, 0xa6, 0xc9,
    0x20, 0x90, 0x07, 0xe9, 0x20, 0xee, 0x7c, 0xa6, 0x80, 0xf5, 0x8d, 0x7e,
    0xa6, 0x8d, 0x7e, 0xa6, 0x68, 0x8d, 0x7d, 0xa6, 0x8d, 0x80, 0xa6, 0x68,
    0x29, 0x80, 0x8d, 0x7f, 0xa6, 0x68, 0x8d, 0x7b, 0xa6, 0x68, 0x8d, 0x7a,
    0xa6, 0x68, 0x8d, 0x79, 0xa6, 0x68, 0x0a, 0x0a, 0x0a, 0x8d, 0x76, 0xa6,
    0x68, 0xc9, 0x20, 0x90, 0x07, 0xe9, 0x20, 0xee, 0x76, 0xa6, 0x80, 0xf5,
    0x8d, 0x78, 0xa6, 0x68, 0xae, 0x74, 0xa6, 0x18, 0x7d, 0x6c, 0xa6, 0x8d,
    0x77, 0xa6, 0xbd, 0x70, 0xa6, 0x6d, 0x78, 0xa6, 0xc9, 0xc0, 0x90, 0x05,
    0xe9, 0x20, 0xee, 0x76, 0xa6, 0x8d, 0x78, 0xa6, 0xbd, 0x68, 0xa6, 0x18,
    0x6d, 0x76, 0xa6, 0x8d, 0x76, 0xa6, 0xbd, 0x7f, 0xa6, 0xf0, 0x42, 0xad,
    0x77, 0xa6, 0x18, 0x6d, 0x7d, 0xa6, 0x8d, 0x7d, 0xa6, 0xad, 0x78, 0xa6,
    0x6d, 0x7e, 0xa6, 0xc9, 0xc0, 0x90, 0x05, 0xe9, 0x20, 0xee, 0x7c, 0xa6,
    0x8d, 0x7e, 0xa6, 0xad, 0x76, 0xa6, 0x18, 0x6d, 0x7c, 0xa6, 0x8d, 0x7c,
    0xa6, 0xad, 0x79, 0xa6, 0x38, 0xed, 0x80, 0xa6, 0x8d, 0x80, 0xa6, 0xad,
    0x7a, 0xa6, 0xed, 0x81, 0xa6, 0x8d, 0x81, 0xa6, 0xad, 0x7b, 0xa6, 0xed,
    0x82, 0xa6, 0x8d, 0x82, 0xa6, 0x60, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x9c,
    0x75, 0xa6, 0x60, 0x00, 0x8e, 0x3a, 0x90, 0xbd, 0x5c, 0xa6, 0x8d, 0xdb,
    0x9c, 0xbd, 0x60, 0xa6, 0x8d, 0xdc, 0x9c, 0xbd, 0x58, 0xa6, 0x85, 0x00,
    0xa2, 0x00, 0x20, 0xda, 0x9c, 0xdd, 0x94, 0x90, 0xd0, 0x61, 0xe8, 0xe0,
    0x03, 0x90, 0xf3, 0x20, 0xda, 0x9c, 0xa4, 0x00, 0xae, 0x5a, 0x8c, 0x86,
    0x00, 0xa2, 0xff, 0x9d, 0x64, 0xa6, 0x98, 0x9d, 0x58, 0xa6, 0x9d, 0x68,
    0xa6, 0xad, 0xdb, 0x9c, 0x9d, 0x5c, 0xa6, 0xad, 0xdc, 0x9c, 0x9d, 0x60,
    0xa6, 0x9c, 0x74, 0x90, 0xbd, 0x64, 0xa6, 0x1a, 0xd0, 0x03, 0xee, 0x74,
    0x90, 0x0a, 0x2e, 0x74, 0x90, 0x0a, 0x2e, 0x74, 0x90, 0x0a, 0x2e, 0x74,
    0x90, 0x0a, 0x2e, 0x74, 0x90, 0x7d, 0x5c, 0xa6, 0x9d, 0x6c, 0xa6, 0xa9,
    0xff, 0x7d, 0x60, 0xa6, 0xc9, 0xc0, 0x90, 0x05, 0xe9, 0x20, 0xfe, 0x68,
    0xa6, 0x9d, 0x70, 0xa6, 0xa9, 0x80, 0x9d, 0x54, 0xa6, 0x80, 0x03, 0x9e,
    0x54, 0xa6, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x60, 0x50, 0x43, 0x4d, 0xae,
    0x75, 0xa6, 0xd0, 0x03, 0x4c, 0x8c, 0x91, 0xae, 0x3c, 0x9f, 0x8e, 0x41,
    0x91, 0xca, 0xad, 0x27, 0x9f, 0x29, 0x08, 0xf0, 0x0b, 0xe0, 0xff, 0xd0,
    0x02, 0xa2, 0x7f, 0xbd, 0x27, 0x9d, 0x80, 0x08, 0xe0, 0xff, 0xd0, 0x01,
    0x60, 0xbd, 0xa7, 0x9d, 0x9c, 0x8e, 0x91, 0x0a, 0x2e, 0x8e, 0x91, 0x0a,
    0x2e, 0x8e, 0x91, 0x8d, 0x8d, 0x91, 0xad, 0x3b, 0x9f, 0x29, 0x10, 0xf0,
    0x06, 0x0e, 0x8d, 0x91, 0x2e, 0x8e, 0x91, 0xad, 0x3b, 0x9f, 0x29, 0x20,
    0xf0, 0x06, 0x0e, 0x8d, 0x91, 0x2e, 0x8e, 0x91, 0x9c, 0x46, 0x91, 0x2c,
    0x3b, 0x9f, 0x50, 0x03, 0x9c, 0x3c, 0x9f, 0xad, 0x7b, 0xa6, 0xd0, 0x24,
    0xad, 0x79, 0xa6, 0x38, 0xed, 0x8d, 0x91, 0xad, 0x7a, 0xa6, 0xed, 0x8e,
    0x91, 0xb0, 0x15, 0xae, 0x79, 0xa6, 0xac, 0x7a, 0xa6, 0xad, 0x7f, 0xa6,
    0xf0, 0x05, 0xee, 0x46, 0x91, 0x80, 0x26, 0x9c, 0x75, 0xa6, 0x80, 0x21,
    0xad, 0x79, 0xa6, 0x38, 0xed, 0x8d, 0x91, 0x8d, 0x79, 0xa6, 0xad, 0x7a,
    0xa6, 0xed, 0x8e, 0x91, 0x8d, 0x7a, 0xa6, 0xad, 0x7b, 0xa6, 0xe9, 0x00,
    0x8d, 0x7b, 0xa6, 0xae, 0x8d, 0x91, 0xac, 0x8e, 0x91, 0x20, 0x8f, 0x91,
    0xa9, 0x80, 0x8d, 0x3c, 0x9f, 0xa9, 0x00, 0xf0, 0x43, 0xad, 0x7c, 0xa6,
    0x8d, 0x76, 0xa6, 0xad, 0x7e, 0xa6, 0x8d, 0x78, 0xa6, 0xad, 0x7d, 0xa6,
    0x8d, 0x77, 0xa6, 0xad, 0x8d, 0x91, 0x38, 0xed, 0x79, 0xa6, 0x8d, 0x8d,
    0x91, 0xad, 0x8e, 0x91, 0xed, 0x7a, 0xa6, 0x8d, 0x8e, 0x91, 0xad, 0x80,
    0xa6, 0x38, 0xed, 0x8d, 0x91, 0x8d, 0x79, 0xa6, 0xad, 0x81, 0xa6, 0xed,
    0x8e, 0x91, 0x8d, 0x7a, 0xa6, 0xad, 0x82, 0xa6, 0xe9, 0x00, 0x8d, 0x7b,
    0xa6, 0x4c, 0xe8, 0x90, 0x60, 0x00, 0x00, 0xad, 0x78, 0xa6, 0x8d, 0xcc,
    0x91, 0x8d, 0xd3, 0x91, 0x8d, 0xda, 0x91, 0x8d, 0xe1, 0x91, 0x8a, 0xae,
    0x77, 0xa6, 0x18, 0x6d, 0x77, 0xa6, 0x8d, 0x3c, 0x92, 0x90, 0x01, 0xc8,
    0xad, 0x76, 0xa6, 0x85, 0x00, 0xc0, 0x00, 0xf0, 0x54, 0xa9, 0xd0, 0x8d,
    0xe6, 0x91, 0xa9, 0xe2, 0x8d, 0xe7, 0x91, 0x8a, 0x6a, 0x6a, 0x90, 0x04,
    0x30, 0x19, 0x80, 0x10, 0x30, 0x07, 0xbd, 0x00, 0xff, 0x8d, 0x3d, 0x9f,
    0xe8, 0xbd, 0x00, 0xff, 0x8d, 0x3d, 0x9f, 0xe8, 0xbd, 0x00, 0xff, 0x8d,
    0x3d, 0x9f, 0xe8, 0xbd, 0x00, 0xff, 0x8d, 0x3d, 0x9f, 0xe8, 0xd0, 0xe2,
    0xd0, 0xe0, 0xe0, 0x00, 0xd0, 0x34, 0xad, 0xcc, 0x91, 0x1a, 0xc9, 0xc0,
    0xf0, 0x40, 0x8d, 0xcc, 0x91, 0x8d, 0xd3, 0x91, 0x8d, 0xda, 0x91, 0x8d,
    0xe1, 0x91, 0xc0, 0x00, 0xf0, 0x1c, 0x88, 0xd0, 0xc1, 0xad, 0x3c, 0x92,
    0xf0, 0x14, 0x8d, 0xe7, 0x91, 0xa9, 0xe0, 0x8d, 0xe6, 0x91, 0x8a, 0x49,
    0xff, 0x38, 0x6d, 0x3c, 0x92, 0x49, 0xff, 0x1a, 0x80, 0x9e, 0xa4, 0x00,
    0xad, 0x5a, 0x8c, 0x85, 0x00, 0xad, 0xcc, 0x91, 0x8d, 0x78, 0xa6, 0x8e,
    0x77, 0xa6, 0x8c, 0x76, 0xa6, 0x60, 0xa9, 0xa0, 0xe6, 0x00, 0x80, 0xba,
    0x00, 0xbd, 0xec, 0xa5, 0xf0, 0x64, 0xbd, 0x48, 0xa6, 0x38, 0xfd, 0x3c,
    0xa6, 0x9d, 0x48, 0xa6, 0xbd, 0x4c, 0xa6, 0xfd, 0x40, 0xa6, 0x9d, 0x4c,
    0xa6, 0xbd, 0x50, 0xa6, 0xfd, 0x44, 0xa6, 0x9d, 0x50, 0xa6, 0x10, 0x46,
    0xbd, 0x1f, 0x9d, 0x69, 0x00, 0x8d, 0xcc, 0x92, 0xa9, 0xa4, 0x7d, 0x23,
    0x9d, 0x8d, 0xcd, 0x92, 0x8a, 0x18, 0x69, 0xa0, 0x8d, 0x33, 0x93, 0xbd,
    0x20, 0xa6, 0x8d, 0x30, 0x94, 0xbd, 0x24, 0xa6, 0x8d, 0x31, 0x94, 0x20,
    0x2a, 0x94, 0x10, 0x30, 0xc9, 0x80, 0xf0, 0x4a, 0x29, 0x7f, 0xc9, 0x30,
    0x18, 0x7d, 0x4c, 0xa6, 0x9d, 0x4c, 0xa6, 0x90, 0x03, 0xfe, 0x50, 0xa6,
    0x20, 0x3a, 0x94, 0xb0, 0x07, 0xbd, 0x50, 0xa6, 0x30, 0xdd, 0x60, 0x68,
    0xae, 0x3e, 0x93, 0x9e, 0xf0, 0xa5, 0xa0, 0x00, 0xa9, 0x80, 0x20, 0x9a,
    0x94, 0x4c, 0x32, 0x99, 0xc9, 0x40, 0xf0, 0x2b, 0xb0, 0x52, 0x8e, 0x3e,
    0x93, 0x48, 0x20, 0x3a, 0x94, 0xb0, 0xe0, 0x20, 0x2a, 0x94, 0xfa, 0x9d,
    0x00, 0xa4, 0x20, 0x5c, 0x94, 0xae, 0x3e, 0x93, 0x80, 0xc6, 0xbd, 0x28,
    0xa6, 0xd0, 0x6a, 0x9e, 0xec, 0xa5, 0xa0, 0x00, 0x20, 0x9a, 0x94, 0x20,
    0x32, 0x99, 0x60, 0x20, 0x3a, 0x94, 0xb0, 0xbc, 0x20, 0x2a, 0x94, 0xc9,
    0x40, 0xb0, 0x03, 0x4c, 0xb3, 0x93, 0xc9, 0x80, 0x90, 0x07, 0xc9, 0xc0,
    0xb0, 0x03, 0x4c, 0x70, 0x93, 0x29, 0x3f, 0xa8, 0xf0, 0x96, 0x20, 0x3a,
    0x94, 0xb0, 0x9d, 0x88, 0xd0, 0xf8, 0x80, 0x8c, 0x29, 0x3f, 0xa8, 0x20,
    0x3a, 0x94, 0xb0, 0x90, 0x20, 0x2a, 0x94, 0x8e, 0x3e, 0x93, 0xc9, 0x01,
    0xd0, 0x02, 0xa9, 0x01, 0x48, 0x20, 0x3a, 0x94, 0x90, 0x03, 0x4c, 0xa7,
    0x92, 0x20, 0x2a, 0x94, 0xfa, 0x9d, 0x00, 0xa0, 0x5a, 0x20, 0x71, 0x94,
    0x7a, 0xe0, 0x08, 0xf0, 0x4f, 0xa2, 0x00, 0x88, 0xd0, 0xd1, 0x4c, 0x9c,
    0x92, 0xfe, 0x2c, 0xa6, 0xd0, 0x03, 0xfe, 0x30, 0xa6, 0xbd, 0x2c, 0xa6,
    0xa0, 0x01, 0x20, 0x9a, 0x94, 0xbd, 0x10, 0xa6, 0x9d, 0x1c, 0xa6, 0xbd,
    0x14, 0xa6, 0x9d, 0x20, 0xa6, 0x8d, 0x30, 0x94, 0xbd, 0x18, 0xa6, 0x9d,
    0x24, 0xa6, 0x8d, 0x31, 0x94, 0x4c, 0x83, 0x92, 0x29, 0x3f, 0x48, 0x20,
    0x3a, 0x94, 0xb0, 0x60, 0x20, 0x2a, 0x94, 0xc9, 0x02, 0x90, 0x21, 0x20,
    0x3a, 0x94, 0xb0, 0x54, 0x68, 0x3a, 0x3a, 0xd0, 0xe7, 0x4c, 0x9c, 0x92,
    0x8d, 0x9a, 0x93, 0x29, 0x07, 0xae, 0x3e, 0x93, 0x18, 0x7d, 0x17, 0x9d,
    0xaa, 0xa9, 0x00, 0x9d, 0x20, 0xa5, 0x80, 0x9d, 0x69, 0x02, 0xa8, 0x20,
    0x3a, 0x94, 0xb0, 0x30, 0x20, 0x2a, 0x94, 0xae, 0x3e, 0x93, 0x20, 0x9a,
    0x94, 0x80, 0xd1, 0xae, 0x3e, 0x93, 0x48, 0x20, 0x3a, 0x94, 0xb0, 0x1c,
    0x20, 0x2a, 0x94, 0xf0, 0x1b, 0xc9, 0x01, 0xf0, 0x50, 0x20, 0x3a, 0x94,
    0xb0, 0x0f, 0x20, 0x2a, 0x94, 0x20, 0x8f, 0x8e, 0x68, 0x3a, 0x3a, 0xd0,
    0xde, 0x4c, 0x9c, 0x92, 0x68, 0x4c, 0xa8, 0x92, 0x20, 0x3a, 0x94, 0xb0,
    0xf8, 0x20, 0x2a, 0x94, 0x9d, 0x80, 0xa5, 0xec, 0x74, 0xa6, 0xd0, 0xe4,
    0x29, 0x0f, 0x38, 0xfd, 0x88, 0xa5, 0x10, 0x02, 0xa9, 0x00, 0x8d, 0xff,
    0x93, 0xbd, 0x80, 0xa5, 0x29, 0x80, 0x09, 0x0f, 0x8d, 0xff, 0x93, 0xad,
    0x3b, 0x9f, 0x29, 0x30, 0x0d, 0xff, 0x93, 0x8d, 0x3b, 0x9f, 0x10, 0x03,
    0x9c, 0x75, 0xa6, 0x80, 0xbb, 0x20, 0x3a, 0x94, 0xb0, 0xbf, 0x20, 0x2a,
    0x94, 0x9d, 0x84, 0xa5, 0xec, 0x74, 0xa6, 0xd0, 0xab, 0x8d, 0x3c, 0x9f,
    0x80, 0xa6, 0xbd, 0x1c, 0xa6, 0x85, 0x00, 0xad, 0xff, 0xff, 0x48, 0xad,
    0x5a, 0x8c, 0x85, 0x00, 0x68, 0x60, 0xee, 0x30, 0x94, 0xd0, 0x03, 0xee,
    0x31, 0x94, 0xad, 0x31, 0x94, 0xc9, 0xc0, 0x90, 0x09, 0xfe, 0x1c, 0xa6,
    0xa9, 0xa0, 0x8d, 0x31, 0x94, 0x18, 0x9d, 0x24, 0xa6, 0xad, 0x30, 0x94,
    0x9d, 0x20, 0xa6, 0x60, 0x8d, 0x6c, 0x94, 0x8a, 0x4a, 0x4a, 0xa8, 0xb9,
    0xeb, 0xa6, 0xcd, 0x3e, 0x93, 0xd0, 0x05, 0xa9, 0xff, 0x4c, 0xa2, 0xc0,
    0x60, 0x8d, 0x8d, 0x94, 0xe0, 0x08, 0xf0, 0x09, 0xe0, 0x0f, 0xf0, 0x19,
    0xe0, 0x20, 0x90, 0x11, 0x8a, 0x29, 0x07, 0xa8, 0xb9, 0xe3, 0xa6, 0xcd,
    0x3e, 0x93, 0xd0, 0x0d, 0xa9, 0xff, 0x4c, 0x8a, 0xc0, 0xa9, 0x00, 0x80,
    0xf2, 0xa0, 0x07, 0x80, 0xeb, 0x60, 0x3c, 0x00, 0xa6, 0x10, 0x23, 0x8d,
    0xb7, 0x94, 0x8e, 0xc1, 0x94, 0xbd, 0xf4, 0xa5, 0x8d, 0xb9, 0x94, 0xbd,
    0xf8, 0xa5, 0x8d, 0xba, 0x94, 0xbd, 0xfc, 0xa5, 0x85, 0x00, 0xa9, 0x00,
    0x20, 0xff, 0xff, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xa2, 0x00, 0x60, 0xad,
    0x13, 0xa7, 0xf0, 0x6f, 0xa2, 0x00, 0xbc, 0xe3, 0xa6, 0xc0, 0x04, 0xb0,
    0x28, 0xb9, 0xf0, 0xa5, 0xf0, 0x19, 0xb9, 0xec, 0xa5, 0xf0, 0x14, 0xb9,
    0x17, 0x9d, 0x69, 0x8c, 0x8d, 0xeb, 0x94, 0xa9, 0xa5, 0x69, 0x00, 0x8d,
    0xec, 0x94, 0xbd, 0x8c, 0xa5, 0xd0, 0x0a, 0xa9, 0x80, 0x9d, 0xfb, 0xa6,
    0xde, 0xe3, 0xa6, 0x80, 0xd1, 0xe8, 0xe0, 0x08, 0xd0, 0xcc, 0xa2, 0x00,
    0xbc, 0xeb, 0xa6, 0xc0, 0x04, 0xb0, 0x28, 0xb9, 0xf0, 0xa5, 0xf0, 0x19,
    0xb9, 0xec, 0xa5, 0xf0, 0x14, 0xb9, 0x1b, 0x9d, 0x69, 0xac, 0x8d, 0x21,
    0x95, 0xa9, 0xa5, 0x69, 0x00, 0x8d, 0x22, 0x95, 0xbd, 0xac, 0xa5, 0xd0,
    0x0a, 0xa9, 0x80, 0x9d, 0x03, 0xa7, 0xde, 0xeb, 0xa6, 0x80, 0xd1, 0xe8,
    0xe0, 0x10, 0xd0, 0xcc, 0x9c, 0x13, 0xa7, 0x60, 0x5a, 0x98, 0x18, 0x69,
    0xe0, 0x8d, 0x61, 0x95, 0x69, 0x08, 0x8d, 0x5c, 0x95, 0x69, 0x08, 0x8d,
    0x57, 0x95, 0x69, 0x08, 0x8d, 0x52, 0x95, 0xa9, 0xff, 0xa2, 0xe0, 0x20,
    0x8a, 0xc0, 0xa2, 0xe8, 0x20, 0x8a, 0xc0, 0xa2, 0xf0, 0x20, 0x8a, 0xc0,
    0xa2, 0xf8, 0x20, 0x8a, 0xc0, 0x68, 0x20, 0x84, 0xc0, 0x60, 0xa2, 0x00,
    0x8e, 0x4b, 0x96, 0xbd, 0xfb, 0xa6, 0xf0, 0x5b, 0xac, 0x4b, 0x96, 0x20,
    0x38, 0x95, 0xae, 0x4b, 0x96, 0xbd, 0xe3, 0xa6, 0xc9, 0x04, 0xb0, 0x4b,
    0xac, 0x4b, 0x96, 0xbe, 0xe3, 0xa6, 0xbd, 0x17, 0x9d, 0x69, 0x00, 0x8d,
    0xc9, 0x95, 0xa9, 0xa5, 0x69, 0x00, 0x8d, 0xca, 0x95, 0xb9, 0xe3, 0xa6,
    0x18, 0x69, 0xa0, 0x8d, 0xba, 0x95, 0x8d, 0xab, 0x95, 0xc0, 0x07, 0xd0,
    0x08, 0xad, 0x0f, 0xa0, 0xa2, 0x0f, 0x20, 0x8a, 0xc0, 0xa9, 0x20, 0x18,
    0x6d, 0x4b, 0x96, 0xaa, 0xbd, 0x00, 0xa0, 0x20, 0x8a, 0xc0, 0x8a, 0x18,
    0x69, 0x08, 0xaa, 0x90, 0xf3, 0xac, 0x4b, 0x96, 0xbe, 0x00, 0xa5, 0x98,
    0x20, 0x75, 0xc0, 0xae, 0x4b, 0x96, 0x9e, 0xfb, 0xa6, 0xe8, 0x8e, 0x4b,
    0x96, 0xe0, 0x08, 0x90, 0x92, 0xa2, 0x00, 0x8e, 0x4b, 0x96, 0xbd, 0x03,
    0xa7, 0xf0, 0x55, 0x8a, 0xa2, 0x00, 0x20, 0x5d, 0xc0, 0xae, 0x4b, 0x96,
    0xbd, 0xeb, 0xa6, 0xc9, 0x04, 0xb0, 0x45, 0xaa, 0xbd, 0x1f, 0x9d, 0x69,
    0x00, 0x8d, 0x28, 0x96, 0xa9, 0xa4, 0x7d, 0x23, 0x9d, 0x8d, 0x29, 0x96,
    0xac, 0x4b, 0x96, 0xbe, 0xeb, 0xa6, 0xbd, 0x1b, 0x9d, 0x18, 0x69, 0x40,
    0x8d, 0x36, 0x96, 0xa9, 0xa5, 0x69, 0x00, 0x8d, 0x37, 0x96, 0xad, 0x4b,
    0x96, 0x0a, 0x0a, 0xaa, 0xa0, 0x04, 0x5a, 0xbd, 0x00, 0xa4, 0x20, 0xa2,
    0xc0, 0x7a, 0xe8, 0x88, 0xd0, 0xf4, 0xac, 0x4b, 0x96, 0xbe, 0x40, 0xa5,
    0x98, 0x20, 0x54, 0xc0, 0xae, 0x4b, 0x96, 0x9e, 0x03, 0xa7, 0xe8, 0x8e,
    0x4b, 0x96, 0xe0, 0x10, 0x90, 0x98, 0x60, 0x00, 0xa5, 0x00, 0x8d, 0x5b,
    0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xbd, 0xec, 0xa5, 0xc9, 0x01, 0xbd,
    0xf0, 0xa5, 0x08, 0xbd, 0x2c, 0xa6, 0xbc, 0x30, 0xa6, 0xaa, 0xad, 0x5b,
    0x8c, 0x85, 0x00, 0x8a, 0x28, 0x60, 0x48, 0xa5, 0x00, 0x8d, 0x8a, 0x96,
    0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x68, 0x9e,
    0x00, 0xa6, 0x9d, 0xf4, 0xa5, 0x98, 0x9d, 0xf8, 0xa5, 0xa9, 0x00, 0x9d,
    0xfc, 0xa5, 0xa9, 0x80, 0x9d, 0x00, 0xa6, 0xad, 0x5b, 0x8c, 0x85, 0x00,
    0x60, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x9e,
    0x00, 0xa6, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0x48, 0xa5, 0x00, 0x8d,
    0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x68, 0x8d, 0x15, 0xa7, 0x8c,
    0x16, 0xa7, 0xa2, 0x03, 0xbd, 0xf0, 0xa5, 0xf0, 0x06, 0x08, 0x78, 0x20,
    0x5f, 0x9c, 0x28, 0xca, 0x10, 0xf2, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60,
    0x48, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x68,
    0x9d, 0x34, 0xa6, 0x98, 0x9d, 0x38, 0xa6, 0x08, 0x78, 0x20, 0x5f, 0x9c,
    0x28, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0xa5, 0x00, 0x8d, 0x5b, 0x8c,
    0xad, 0x5a, 0x8c, 0x85, 0x00, 0xbd, 0x34, 0xa6, 0xbc, 0x38, 0xa6, 0x48,
    0xad, 0x5b, 0x8c, 0x85, 0x00, 0x68, 0x60, 0x08, 0xa5, 0x00, 0x8d, 0x5b,
    0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xa9, 0x80, 0x28, 0xb0, 0x16, 0xa9,
    0x00, 0x9d, 0x28, 0xa6, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0xc9, 0x3f,
    0x90, 0x07, 0xa9, 0x7f, 0x8d, 0x74, 0x97, 0x80, 0x28, 0x8d, 0x51, 0x97,
    0x8d, 0x74, 0x97, 0x4a, 0x4a, 0x6d, 0x74, 0x97, 0x6a, 0x4a, 0x6d, 0x74,
    0x97, 0x6a, 0x4a, 0x6d, 0x74, 0x97, 0x6a, 0x4a, 0x6d, 0x74, 0x97, 0x6a,
    0x4a, 0x8d, 0x74, 0x97, 0xa9, 0x00, 0x38, 0xed, 0x74, 0x97, 0x8d, 0x74,
    0x97, 0x8e, 0x70, 0x97, 0xbd, 0x17, 0x9d, 0x18, 0x69, 0x00, 0x8d, 0x89,
    0x97, 0xa9, 0xa5, 0x69, 0x00, 0x8d, 0x8a, 0x97, 0xb9, 0xe3, 0xa6, 0xc9,
    0x00, 0xd0, 0x12, 0xa2, 0x00, 0xa5, 0x01, 0x48, 0xa9, 0x0a, 0x85, 0x01,
    0x98, 0x5a, 0x20, 0x75, 0xc0, 0x7a, 0x68, 0x85, 0x01, 0xad, 0x74, 0x97,
    0x99, 0x00, 0xa5, 0x60, 0x08, 0x48, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad,
    0x5a, 0x8c, 0x85, 0x00, 0x68, 0x78, 0x20, 0x26, 0x97, 0x28, 0xad, 0x5b,
    0x8c, 0x85, 0x00, 0x60, 0xc9, 0x3f, 0x90, 0x02, 0xa9, 0x3f, 0x8d, 0xc8,
    0x97, 0x8e, 0xc4, 0x97, 0xbd, 0x1b, 0x9d, 0x18, 0x69, 0x40, 0x8d, 0xdd,
    0x97, 0xa9, 0xa5, 0x69, 0x00, 0x8d, 0xde, 0x97, 0xb9, 0xeb, 0xa6, 0xc9,
    0x00, 0xd0, 0x12, 0xa2, 0x00, 0xa5, 0x01, 0x48, 0xa9, 0x0a, 0x85, 0x01,
    0x98, 0x5a, 0x20, 0x54, 0xc0, 0x7a, 0x68, 0x85, 0x01, 0xad, 0xc8, 0x97,
    0x99, 0x40, 0xa5, 0x60, 0x08, 0x48, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad,
    0x5a, 0x8c, 0x85, 0x00, 0x68, 0x78, 0x20, 0xa4, 0x97, 0x28, 0xad, 0x5b,
    0x8c, 0x85, 0x00, 0x60, 0xa0, 0x10, 0x88, 0xd9, 0x24, 0x98, 0x90, 0xfa,
    0x98, 0x9d, 0x88, 0xa5, 0xec, 0x74, 0xa6, 0xd0, 0x1a, 0xbd, 0x80, 0xa5,
    0x29, 0x0f, 0x38, 0xfd, 0x88, 0xa5, 0x10, 0x02, 0xa9, 0x00, 0x8d, 0x1f,
    0x98, 0xad, 0x3b, 0x9f, 0x29, 0x30, 0x09, 0x0f, 0x8d, 0x3b, 0x9f, 0x60,
    0x00, 0x05, 0x09, 0x0e, 0x12, 0x17, 0x1b, 0x1f, 0x24, 0x28, 0x2d, 0x31,
    0x36, 0x3a, 0x3d, 0x3f, 0x08, 0x48, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad,
    0x5a, 0x8c, 0x85, 0x00, 0x68, 0x78, 0x20, 0xf8, 0x97, 0x28, 0xad, 0x5b,
    0x8c, 0x85, 0x00, 0x60, 0x8d, 0x8c, 0x98, 0x8e, 0x8b, 0x98, 0xa5, 0x00,
    0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0x08, 0x78, 0xad, 0x8c,
    0x98, 0x20, 0xf8, 0x97, 0xa0, 0x00, 0xae, 0x8b, 0x98, 0xad, 0x8c, 0x98,
    0x20, 0xa4, 0x97, 0xc8, 0xc0, 0x10, 0xd0, 0xf2, 0xa0, 0x00, 0xae, 0x8b,
    0x98, 0xad, 0x8c, 0x98, 0x20, 0x26, 0x97, 0xc8, 0xc0, 0x08, 0xd0, 0xf2,
    0x28, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0x00, 0x00, 0x8e, 0xdb, 0x98,
    0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xbd, 0xec,
    0xa5, 0xf0, 0x15, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x20, 0x0d, 0x99, 0xa5,
    0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xae, 0xdb, 0x98,
    0xbd, 0x08, 0xa6, 0x9d, 0x20, 0xa6, 0xbd, 0x0c, 0xa6, 0x9d, 0x24, 0xa6,
    0xbd, 0x04, 0xa6, 0x9d, 0x1c, 0xa6, 0x9e, 0x48, 0xa6, 0x9e, 0x4c, 0xa6,
    0x9e, 0x50, 0xa6, 0x9e, 0x30, 0xa6, 0x9e, 0x2c, 0xa6, 0xad, 0x5b, 0x8c,
    0x85, 0x00, 0x60, 0x00, 0x8e, 0x0c, 0x99, 0xa5, 0x00, 0x8d, 0x5b, 0x8c,
    0xad, 0x5a, 0x8c, 0x85, 0x00, 0xbd, 0xec, 0xa5, 0xf0, 0x15, 0xad, 0x5b,
    0x8c, 0x85, 0x00, 0x20, 0x0d, 0x99, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad,
    0x5a, 0x8c, 0x85, 0x00, 0xae, 0x0c, 0x99, 0x9e, 0xf0, 0xa5, 0xad, 0x5b,
    0x8c, 0x85, 0x00, 0x60, 0x00, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a,
    0x8c, 0x85, 0x00, 0xa5, 0x01, 0x48, 0xa9, 0x0a, 0x85, 0x01, 0x08, 0x78,
    0xbd, 0xec, 0xa5, 0xf0, 0x03, 0x20, 0x32, 0x99, 0x28, 0x68, 0x85, 0x01,
    0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0x8e, 0x3b, 0x99, 0xa0, 0x00, 0xb9,
    0xeb, 0xa6, 0xc9, 0x00, 0xd0, 0x08, 0x5a, 0x98, 0xa2, 0x00, 0x20, 0x5d,
    0xc0, 0x7a, 0xc8, 0xc0, 0x10, 0xd0, 0xec, 0xa0, 0x00, 0xb9, 0xe3, 0xa6,
    0xcd, 0x3b, 0x99, 0xd0, 0x05, 0x5a, 0x20, 0x38, 0x95, 0x7a, 0xc8, 0xc0,
    0x08, 0xd0, 0xee, 0xae, 0x3b, 0x99, 0xec, 0x74, 0xa6, 0xd0, 0x0d, 0xad,
    0x3b, 0x9f, 0x29, 0x3f, 0x09, 0x80, 0x8d, 0x3b, 0x9f, 0x9c, 0x75, 0xa6,
    0x9e, 0xec, 0xa5, 0xa9, 0x80, 0x8d, 0x13, 0xa7, 0x60, 0xa5, 0x00, 0x8d,
    0x5b, 0x8c, 0xad, 0x5a, 0x8c, 0x85, 0x00, 0xbd, 0xec, 0xa5, 0xd0, 0x70,
    0xbd, 0xf0, 0xa5, 0xf0, 0x6b, 0xbd, 0x1c, 0xa6, 0xd0, 0x07, 0xbd, 0x24,
    0xa6, 0xc9, 0xa0, 0x90, 0x5f, 0x8e, 0x02, 0x9a, 0x08, 0x78, 0xbc, 0x17,
    0x9d, 0xa2, 0x00, 0xb9, 0x8c, 0xa5, 0xf0, 0x17, 0xbd, 0xe3, 0xa6, 0xc9,
    0xff, 0xf0, 0x05, 0xcd, 0x02, 0x9a, 0xb0, 0x0b, 0xa9, 0x80, 0x9d, 0xfb,
    0xa6, 0xad, 0x02, 0x9a, 0x9d, 0xe3, 0xa6, 0xc8, 0xe8, 0xe0, 0x08, 0x90,
    0xde, 0xae, 0x02, 0x9a, 0xbc, 0x1b, 0x9d, 0xa2, 0x00, 0xb9, 0xac, 0xa5,
    0xf0, 0x17, 0xbd, 0xeb, 0xa6, 0xc9, 0xff, 0xf0, 0x05, 0xcd, 0x02, 0x9a,
    0xb0, 0x0b, 0xa9, 0x80, 0x9d, 0x03, 0xa7, 0xad, 0x02, 0x9a, 0x9d, 0xeb,
    0xa6, 0xc8, 0xe8, 0xe0, 0x10, 0x90, 0xde, 0xae, 0x02, 0x9a, 0xa9, 0x80,
    0x9d, 0xec, 0xa5, 0x28, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0x60, 0x00, 0x8d,
    0x36, 0x9a, 0x8d, 0x6d, 0x8c, 0x8c, 0x37, 0x9a, 0x8c, 0x6e, 0x8c, 0xa5,
    0x00, 0x8d, 0x6f, 0x8c, 0xa5, 0x00, 0x8d, 0x5b, 0x8c, 0xad, 0x5a, 0x8c,
    0x85, 0x00, 0x8e, 0x3d, 0x9c, 0xbd, 0xec, 0xa5, 0xf0, 0x08, 0xad, 0x5b,
    0x8c, 0x85, 0x00, 0x20, 0xdc, 0x98, 0xad, 0x5b, 0x8c, 0x85, 0x00, 0xa0,
    0x00, 0xad, 0xff, 0xff, 0x99, 0x5d, 0x8c, 0xee, 0x36, 0x9a, 0xd0, 0x03,
    0xee, 0x37, 0x9a, 0xad, 0x37, 0x9a, 0xc9, 0xc0, 0x90, 0x07, 0xe9, 0x20,
    0x8d, 0x37, 0x9a, 0xe6, 0x00, 0xc8, 0xc0, 0x10, 0x90, 0xdf, 0xac, 0x5a,
    0x8c, 0x84, 0x00, 0xae, 0x3d, 0x9c, 0xad, 0x6f, 0x8c, 0x9d, 0x04, 0xa6,
    0x9d, 0x1c, 0xa6, 0xad, 0x36, 0x9a, 0x9d, 0x08, 0xa6, 0x9d, 0x20, 0xa6,
    0xad, 0x37, 0x9a, 0x9d, 0x0c, 0xa6, 0x9d, 0x24, 0xa6, 0xad, 0x5d, 0x8c,
    0xc9, 0x7a, 0xd0, 0x0e, 0xad, 0x5e, 0x8c, 0xc9, 0x6d, 0xd0, 0x07, 0xad,
    0x5f, 0x8c, 0xc9, 0x01, 0xf0, 0x05, 0x9e, 0xf0, 0xa5, 0x38, 0x60, 0xad,
    0x62, 0x8c, 0x0a, 0x0a, 0x0a, 0x18, 0x6d, 0x6f, 0x8c, 0x9d, 0x10, 0xa6,
    0xad, 0x61, 0x8c, 0x4a, 0x4a, 0x4a, 0x4a, 0x4a, 0x18, 0x7d, 0x10, 0xa6,
    0x9d, 0x10, 0xa6, 0xad, 0x61, 0x8c, 0x29, 0x1f, 0x8d, 0x70, 0x8c, 0xad,
    0x60, 0x8c, 0x18, 0x6d, 0x6d, 0x8c, 0x9d, 0x14, 0xa6, 0xad, 0x70, 0x8c,
    0x6d, 0x6e, 0x8c, 0xc9, 0xc0, 0x90, 0x07, 0xe9, 0x20, 0xfe, 0x10, 0xa6,
    0x80, 0xf5, 0x9d, 0x18, 0xa6, 0xad, 0x60, 0x8c, 0x0d, 0x61, 0x8c, 0x0d,
    0x62, 0x8c, 0xc9, 0x01, 0x9e, 0x28, 0xa6, 0x7e, 0x28, 0xa6, 0xd0, 0x19,
    0xa9, 0x10, 0x7d, 0x14, 0xa6, 0x9d, 0x14, 0xa6, 0xbd, 0x18, 0xa6, 0x69,
    0x00, 0xc9, 0xc0, 0x90, 0x05, 0xe9, 0x20, 0xfe, 0x10, 0xa6, 0x9d, 0x18,
    0xa6, 0x9e, 0x54, 0xa6, 0xad, 0x65, 0x8c, 0x0d, 0x64, 0x8c, 0x0d, 0x63,
    0x8c, 0xf0, 0x45, 0xad, 0x65, 0x8c, 0x0a, 0x0a, 0x0a, 0x18, 0x6d, 0x6f,
    0x8c, 0x9d, 0x58, 0xa6, 0xad, 0x64, 0x8c, 0x4a, 0x4a, 0x4a, 0x4a, 0x4a,
    0x18, 0x7d, 0x58, 0xa6, 0x9d, 0x58, 0xa6, 0xad, 0x64, 0x8c, 0x29, 0x1f,
    0x8d, 0x70, 0x8c, 0xad, 0x63, 0x8c, 0x18, 0x6d, 0x6d, 0x8c, 0x9d, 0x5c,
    0xa6, 0xad, 0x70, 0x8c, 0x6d, 0x6e, 0x8c, 0xc9, 0xc0, 0x90, 0x07, 0xe9,
    0x20, 0xfe, 0x58, 0xa6, 0x80, 0xf5, 0x9d, 0x60, 0xa6, 0x20, 0x0c, 0x90,
    0xad, 0x66, 0x8c, 0xac, 0x3d, 0x9c, 0xbe, 0x17, 0x9d, 0x4a, 0x9e, 0x8c,
    0xa5, 0x7e, 0x8c, 0xa5, 0x4a, 0x9e, 0x8d, 0xa5, 0x7e, 0x8d, 0xa5, 0x4a,
    0x9e, 0x8e, 0xa5, 0x7e, 0x8e, 0xa5, 0x4a, 0x9e, 0x8f, 0xa5, 0x7e, 0x8f,
    0xa5, 0x4a, 0x9e, 0x90, 0xa5, 0x7e, 0x90, 0xa5, 0x4a, 0x9e, 0x91, 0xa5,
    0x7e, 0x91, 0xa5, 0x4a, 0x9e, 0x92, 0xa5, 0x7e, 0x92, 0xa5, 0x4a, 0x9e,
    0x93, 0xa5, 0x7e, 0x93, 0xa5, 0xad, 0x67, 0x8c, 0xbe, 0x1b, 0x9d, 0x4a,
    0x9e, 0xac, 0xa5, 0x7e, 0xac, 0xa5, 0x4a, 0x9e, 0xad, 0xa5, 0x7e, 0xad,
    0xa5, 0x4a, 0x9e, 0xae, 0xa5, 0x7e, 0xae, 0xa5, 0x4a, 0x9e, 0xaf, 0xa5,
    0x7e, 0xaf, 0xa5, 0x4a, 0x9e, 0xb0, 0xa5, 0x7e, 0xb0, 0xa5, 0x4a, 0x9e,
    0xb1, 0xa5, 0x7e, 0xb1, 0xa5, 0x4a, 0x9e, 0xb2, 0xa5, 0x7e, 0xb2, 0xa5,
    0x4a, 0x9e, 0xb3, 0xa5, 0x7e, 0xb3, 0xa5, 0xad, 0x68, 0x8c, 0x4a, 0x9e,
    0xb4, 0xa5, 0x7e, 0xb4, 0xa5, 0x4a, 0x9e, 0xb5, 0xa5, 0x7e, 0xb5, 0xa5,
    0x4a, 0x9e, 0xb6, 0xa5, 0x7e, 0xb6, 0xa5, 0x4a, 0x9e, 0xb7, 0xa5, 0x7e,
    0xb7, 0xa5, 0x4a, 0x9e, 0xb8, 0xa5, 0x7e, 0xb8, 0xa5, 0x4a, 0x9e, 0xb9,
    0xa5, 0x7e, 0xb9, 0xa5, 0x4a, 0x9e, 0xba, 0xa5, 0x7e, 0xba, 0xa5, 0x4a,
    0x9e, 0xbb, 0xa5, 0x7e, 0xbb, 0xa5, 0xad, 0x69, 0x8c, 0x99, 0x34, 0xa6,
    0xad, 0x6a, 0x8c, 0x99, 0x38, 0xa6, 0xae, 0x3d, 0x9c, 0x9e, 0x48, 0xa6,
    0x9e, 0x4c, 0xa6, 0x9e, 0x50, 0xa6, 0x9e, 0x30, 0xa6, 0x9e, 0x2c, 0xa6,
    0xa9, 0x80, 0x9d, 0xf0, 0xa5, 0x20, 0x3e, 0x9c, 0x20, 0x5f, 0x9c, 0xad,
    0x5b, 0x8c, 0x85, 0x00, 0x60, 0x00, 0xda, 0xa9, 0x00, 0xbc, 0x1b, 0x9d,
    0xa2, 0x40, 0x99, 0x00, 0xa4, 0xc8, 0xca, 0xd0, 0xf9, 0xfa, 0xda, 0xa9,
    0x00, 0xbc, 0x17, 0x9d, 0xa2, 0x08, 0x99, 0x20, 0xa5, 0xc8, 0xca, 0xd0,
    0xf9, 0xfa, 0x60, 0x8e, 0xd9, 0x9c, 0xbd, 0x34, 0xa6, 0x1d, 0x38, 0xa6,
    0xd0, 0x05, 0xa9, 0x3c, 0x9d, 0x34, 0xa6, 0x9c, 0x5d, 0x8c, 0x9c, 0x5e,
    0x8c, 0x9c, 0x61, 0x8c, 0x9c, 0x62, 0x8c, 0xbd, 0x34, 0xa6, 0x8d, 0x63,
    0x8c, 0xbd, 0x38, 0xa6, 0x8d, 0x64, 0x8c, 0xad, 0x16, 0xa7, 0x8d, 0x65,
    0x8c, 0xad, 0x15, 0xa7, 0x8d, 0x66, 0x8c, 0xa2, 0x20, 0x0e, 0x61, 0x8c,
    0x2e, 0x62, 0x8c, 0x2e, 0x63, 0x8c, 0x2e, 0x64, 0x8c, 0x2e, 0x5d, 0x8c,
    0x2e, 0x5e, 0x8c, 0xad, 0x5d, 0x8c, 0x38, 0xed, 0x65, 0x8c, 0xa8, 0xad,
    0x5e, 0x8c, 0xed, 0x66, 0x8c, 0x90, 0x09, 0x8d, 0x5e, 0x8c, 0x8c, 0x5d,
    0x8c, 0xee, 0x61, 0x8c, 0xca, 0xd0, 0xd2, 0xae, 0xd9, 0x9c, 0xad, 0x61,
    0x8c, 0x9d, 0x3c, 0xa6, 0xad, 0x62, 0x8c, 0x9d, 0x40, 0xa6, 0xad, 0x63,
    0x8c, 0x9d, 0x44, 0xa6, 0x60, 0x00, 0xad, 0xff, 0xff, 0xee, 0xdb, 0x9c,
    0xd0, 0x13, 0xee, 0xdc, 0x9c, 0x48, 0xad, 0xdc, 0x9c, 0xc9, 0xc0, 0x90,
    0x07, 0xe9, 0x20, 0x8d, 0xdc, 0x9c, 0xe6, 0x00, 0x68, 0x60, 0xad, 0xff,
    0xff, 0xee, 0xf7, 0x9c, 0xd0, 0xf7, 0xee, 0xf8, 0x9c, 0x48, 0xad, 0xf8,
    0x9c, 0xc9, 0xc0, 0x90, 0xeb, 0xe9, 0x20, 0x8d, 0xf8, 0x9c, 0xe6, 0x00,
    0x60, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x10, 0x18, 0x00,
    0x10, 0x20, 0x30, 0x00, 0x40, 0x80, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x03,
    0x04, 0x06, 0x07, 0x09, 0x0b, 0x0c, 0x0e, 0x10, 0x11, 0x13, 0x15, 0x16,
    0x17, 0x19, 0x1a, 0x1c, 0x1e, 0x1f, 0x21, 0x22, 0x24, 0x26, 0x27, 0x29,
    0x2a, 0x2c, 0x2e, 0x2f, 0x31, 0x33, 0x34, 0x36, 0x37, 0x39, 0x3b, 0x3c,
    0x3e, 0x3f, 0x41, 0x43, 0x44, 0x46, 0x47, 0x49, 0x4b, 0x4c, 0x4e, 0x50,
    0x51, 0x53, 0x54, 0x56, 0x58, 0x59, 0x5b, 0x5c, 0x5e, 0x60, 0x61, 0x63,
    0x65, 0x66, 0x68, 0x69, 0x6b, 0x6d, 0x6e, 0x70, 0x71, 0x73, 0x75, 0x76,
    0x78, 0x79, 0x7b, 0x7d, 0x7e, 0x80, 0x82, 0x83, 0x85, 0x86, 0x88, 0x8a,
    0x8b, 0x8d, 0x8e, 0x90, 0x92, 0x93, 0x95, 0x97, 0x98, 0x9a, 0x9b, 0x9d,
    0x9f, 0xa0, 0xa2, 0xa3, 0xa5, 0xa7, 0xa8, 0xaa, 0xac, 0xad, 0xaf, 0xb0,
    0xb2, 0xb4, 0xb5, 0xb7, 0xb8, 0xba, 0xbc, 0xbd, 0xbf, 0xc0, 0xc2, 0xc4,
    0xc5, 0xc7, 0xc9, 0xca, 0xcc, 0xcd, 0xcf, 0x01, 0x02, 0x04, 0x05, 0x07,
    0x09, 0x0a, 0x0c, 0x0e, 0x0f, 0x11, 0x12, 0x14, 0x16, 0x17, 0x19, 0x1a,
    0x1c, 0x1e, 0x1f, 0x21, 0x22, 0x24, 0x26, 0x27, 0x29, 0x2a, 0x2c, 0x2e,
    0x2f, 0x31, 0x32, 0x34, 0x36, 0x37, 0x39, 0x3a, 0x3c, 0x3d, 0x3f, 0x41,
    0x42, 0x44, 0x45, 0x47, 0x49, 0x4a, 0x4c, 0x4d, 0x4f, 0x51, 0x52, 0x54,
    0x55, 0x57, 0x58, 0x5a, 0x5c, 0x5d, 0x5f, 0x60, 0x62, 0x64, 0x65, 0x67,
    0x68, 0x6a, 0x6c, 0x6d, 0x6f, 0x70, 0x72, 0x74, 0x75, 0x77, 0x78, 0x7a,
    0x7b, 0x7d, 0x7f, 0x80, 0x82, 0x83, 0x85, 0x87, 0x88, 0x8a, 0x8b, 0x8d,
    0x8f, 0x90, 0x92, 0x93, 0x95, 0x96, 0x98, 0x9a, 0x9b, 0x9d, 0x9e, 0xa0,
    0xa2, 0xa3, 0xa5, 0xa6, 0xa8, 0xaa, 0xab, 0xad, 0xae, 0xb0, 0xb1, 0xb3,
    0xb5, 0xb6, 0xb8, 0xba, 0xbc, 0xbe, 0xbf, 0xc1, 0xc2, 0xc4, 0xc6, 0xc7,
    0xc9, 0xca, 0xcc};
