#include <stdio.h>
#include <cbm.h>
#include "zsmckit.h"

//Used for directly setting the RAM bank
#ifndef RAM_BANK  // older versions of CC65 does not have RAM_BANK defined
#define RAM_BANK (*(unsigned char *)0x00)
#endif

// Assign memory area used as trampoline and storage for ZSMkit
// It is also possible to just use something like golden RAM at 0x0400
u8 trampoline[256];

/*
  Set the RAM bank
*/
void set_ram_bank(u8 bank) {
	RAM_BANK = bank;
}

/*
  Load a headerless file from specified device
*/
u16 load_headerless(u8 dev, u16 addr, char* name) {
	cbm_k_setlfs(1, dev, 2);
	cbm_k_setnam(name);
	return cbm_k_load(0, addr);
}

/*
  This is the prototype of a callback function
*/
// void mycbfunc(u8 eventtype, u8 priority, u8 paramval) {
// }

/*
  Entry point of the program
*/
int main() {
	struct _zsm_version zsmver;

	// Switch back to Upper/GFX font (cc65 switches to mixedcase font)
	cbm_k_bsout(CH_FONT_UPPER);
	printf("loading canyon.zsm into ram...\n");

	// Load the ZSMkit binary into RAM bank 1
	set_ram_bank(1);
	load_headerless(8, 0xA000, "zsmkit-a000.bin");

	// Initialize the ZSM engine and enable the ISR
	zsm_init_engine((u16)trampoline, 1);
	zsmkit_setisr();

	// Load the ZSM file into RAM bank 2
	set_ram_bank(2);
	load_headerless(8, 0xA000, "canyon.zsm");

	// Tell ZSMkit that priority 0 should play from RAM bank 2, address 0xA000
	zsm_setbank(0, 2);
	zsm_setmem(0, 0xA000);

	// Get version of ZSMkit used and print it
	zsmver = zsmkit_version();
	printf("version %d.%d\n", zsmver.majorVersion, zsmver.minorVersion);

	// Wait for the user to press return before starting playback
	printf("press return to start playing the song\n");
	cbm_k_basin();
	zsm_play(0);

//	zsm_setcb(0, mycbfunc);

	// Wait for user to press return again to stop playback and exit program
	printf("\npress return to stop playback and exit\n");
	cbm_k_basin();

	zsmkit_clearisr();
	zsm_stop(0);

	return 0;
}
