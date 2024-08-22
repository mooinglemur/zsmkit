# LLVM-MOS C/C++ wrapper library for zsmkit

## Details

- `zsmkit.c` contains the `lib/zsmkit-8c00.bin` binary
  blob, and is placed at `0x8C00` using a custom memory section.
  To compile you must therefore use the provided custom CX16 linker script with
  `-T link.ld`.
  By enabling `-DZSMKIT_EMBED_BINARY` in the `Makefile`, the binary from the
  parent ZSMKIT directory is included instead of the inlined byte list.
  This can be useful for testing updates. Requires `make basicbin` in the parent
  directory.
- In the provided example, `test.c`, a zsm file is loaded into banked
  memory. If too large to fit in one bank, data spills into the following banks.
  The included zsm file `BACK_AGAIN.ZSM` is by [nicco1690](https://www.youtube.com/nicco1690)
  and sourced from the [Melodius repository](https://github.com/mooinglemur/melodius.git).
- Two headers included: `zsmkit.h` (C) and `zsmkit.hpp` (C++).

## Todo

- [ ] Add wrappers for streaming functions
- [ ] Try to link against `lib/zsmkit.lib` using LLVM-MOS [xo65 support](https://llvm-mos.org/wiki/Cc65_integration).
- [ ] Alternative linker script where zsmkit is placed right after the BASIC snippet at `0x0801`.

