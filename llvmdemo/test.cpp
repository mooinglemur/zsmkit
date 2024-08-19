#include <cstdio>
#include <zsmkit.h>

static const uint8_t songdata[] = {
#embed "../demo/SONG1.ZSM"
};

int main() {
  constexpr uint8_t PRIORITY = 0;
  constexpr uint8_t ZSM_BANK = 1;
  zsm_init_engine(ZSM_BANK);
  zsm_setmem(PRIORITY, (uint16_t)&songdata, ZSM_BANK);
  zsm_play(PRIORITY);

  auto state = zsm_getstate(PRIORITY);
  printf("Song addr = %d\n", (uint16_t)&songdata);
  printf("Playable  = %d\n", !state.not_playable);
  printf("Playing   = %d\n", state.playing);

  while (true) {
    waitvsync();
    zsm_tick(MUSIC_PCM);
  }
}
