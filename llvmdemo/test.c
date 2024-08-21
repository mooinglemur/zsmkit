#include <cbm.h>
#include <stdio.h>
#include <zsmkit.h>

//
// Example usage of zsmkit.h
//
// This is C23-style but can easily
// be converted to lower C versions or C++.
//

// Labelled memory banks ($a000-$bfff)
enum : uint8_t {
  RESERVED_BANK = 0,
  ZSMKIT_BANK,
  SONGDATA_BANK,
};

// Kernal LOAD destination flags
enum : uint8_t {
  LOAD_RAM = 0,    //!< Load into RAM
  LOAD_VERIFY = 1, //!< Performs verify
  LOAD_VRAM0 = 2,  //!< Loads into VRAM $00000 + address
  LOAD_VRAM1 = 3,  //!< Loads into VRAM $10000 + address
};

constexpr uint16_t SONGDATA_ADDR = 0xa000; // Start of banked ram

// Load file into banked ram area
// (if bank is exceeded, continue loading into next bank)
void load_song(const char *filename) {
  constexpr uint8_t LFN = 15;            // Logical file number
  constexpr uint8_t SECONDARY_ADDR = 15; // Secondary address
  constexpr uint8_t MAIN_DISK_DEV = 8;   // First try SD card; then serial

  RAM_BANK = SONGDATA_BANK;
  cbm_k_setnam(filename);
  cbm_k_setlfs(LFN, MAIN_DISK_DEV, SECONDARY_ADDR);
  cbm_k_load(LOAD_RAM, (uint8_t *)SONGDATA_ADDR);
}

int main(void) {
  const char *filename = "BACK_AGAIN.ZSM";
  printf("Loading \"%s\" to bank %d ...\n", filename, SONGDATA_BANK);
  load_song(filename);

  // Set up ZSMKit
  constexpr uint8_t PRIORITY = 0;
  zsm_init_engine(ZSMKIT_BANK);
  zsm_setmem(PRIORITY, SONGDATA_ADDR, SONGDATA_BANK);

  // Check state
  struct ZsmState state = zsm_getstate(PRIORITY);
  printf("Playable = %d\n", !state.not_playable);
  printf("Playing  = %d\n", state.playing);
  if (state.not_playable) {
    printf("Unable to play loaded zsm file. Exiting.\n");
    return 0;
  }

  printf("Start playing.\n");
  zsm_play(PRIORITY);
  state = zsm_getstate(PRIORITY);
  printf("Playing  = %d\n", state.playing);

  while (true) {
    waitvsync();
    zsm_tick(ZCM_TICK_ALL);
  }
}
