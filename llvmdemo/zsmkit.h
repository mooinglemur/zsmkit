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
//
// Notes:
//
// - Todo: enable streaming and remaining wrappers
// - Section `.zsm_section` must be defined and start at $8c00; see link.ld
// - Included ZSMKit hard-coded to $8c00
// - Compile with `mos-cx16-clang -T link.ld ...`
// - More information:
//   - https://github.com/mooinglemur/zsmkit
//   - https://github.com/X16Community/x16-docs
//   - https://github.com/JimmyDansbo/x16maze

#pragma once

#ifndef __cplusplus
#include <stdint.h>
#endif

// Tell zsm_tick what to update
enum : uint8_t {
  ZCM_TICK_ALL = 0,
  ZCM_TICK_PCM_ONLY = 1,
  ZCM_TICK_MUSIC_ONLY = 2
};

struct ZsmState {
  uint8_t playing;
  uint8_t not_playable;
  union {
    uint16_t loopcnt;
    struct {
      uint8_t loopcnt_lo;
      uint8_t loopcnt_hi;
    };
  };
};

void zsm_init_engine(uint8_t bank);
void zsm_setmem(uint8_t priority, uint16_t addr, uint8_t bank);
void zsm_tick(uint8_t what);
void zsm_play(uint8_t priority);
void zsm_stop(uint8_t priority);
void zsm_rewind(uint8_t priority);
void zsm_close(uint8_t priority);
void zsm_setatten(uint8_t priority, uint8_t attenuation);
void zsm_setcb(uint8_t priority, uint16_t callback, uint8_t bank);
void zsm_clearcb(uint8_t priority);
void zsm_setrate(uint8_t priority, uint16_t rate);
uint16_t zsm_getrate(uint8_t priority);
struct ZsmState zsm_getstate(uint8_t priority);
