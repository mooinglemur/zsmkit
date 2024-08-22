#include <cbm.h>
#include <stdio.h>
#include <zsmkit.h>

// Labelled memory banks ($a000-$bfff)
enum : uint8_t {
  RESERVED_BANK = 0,
  ZSMKIT_BANK,
  SONGDATA_BANK,
};

// Load file into banked ram area (0xa000); spill over to next bank
void load_song(const char *filename) {
  constexpr uint8_t LFN = 15;            // Logical file number
  constexpr uint8_t SECONDARY_ADDR = 15; // Secondary address
  constexpr uint8_t MAIN_DISK_DEV = 8;   // First try SD card; then serial
  constexpr uint8_t CBM_LOAD_RAM = 0;    // KERNAL LOAD into RAM

  cbm_k_setnam(filename);
  cbm_k_setlfs(LFN, MAIN_DISK_DEV, SECONDARY_ADDR);
  RAM_BANK = SONGDATA_BANK; // switch bank
  cbm_k_load(CBM_LOAD_RAM, (void *)BANK_RAM);
}

int main(void) {
  const char *filename = "BACK_AGAIN.ZSM";
  printf("Loading \"%s\" to bank %d ...\n", filename, SONGDATA_BANK);
  load_song(filename);

  // Set up ZSMKit
  constexpr uint8_t PRIORITY = 0;
  zsm_init_engine(ZSMKIT_BANK);
  zsm_setmem(PRIORITY, (uint16_t)BANK_RAM, SONGDATA_BANK);

  // Check state
  struct ZsmState state = zsm_getstate(PRIORITY);
  printf("Playable = %d\n", !state.not_playable);
  printf("Playing  = %d\n", state.playing);
  if (state.not_playable) {
    printf("Unable to play loaded zsm file. Exiting.\n");
    return 0;
  }

  zsm_setloop(PRIORITY, true);

  printf("Start playing.\n");
  zsm_play(PRIORITY);
  state = zsm_getstate(PRIORITY);
  printf("Playing   = %d\n", state.playing);
  printf("Org. rate = %d\n", zsm_getrate(PRIORITY));
  zsm_setrate(PRIORITY, 59);
  printf("New rate  = %d\n", zsm_getrate(PRIORITY));

  while (true) {
    waitvsync();
    zsm_tick(ZCM_TICK_ALL);
  }
}
