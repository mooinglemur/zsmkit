%import textio
%import diskio
%import palette
%import zsmkit
%zeropage basicsafe

;; Proof Of Concept ZSM player using zsmkit v2 by MooingLemur
;; zsmkit is hardcoded in the module import above
main {
	ubyte[255] zsmkit_lowram

	sub start() {
		cx16.rambank(zsmkit.ZSMKitBank)
		void diskio.load_raw(iso:"zsmkit-a000.bin",$A000)
		cx16.rambank(2)
		void diskio.load_raw(iso:"MUSIC.ZSM",$A000)

		zsmkit.zsm_init_engine(&zsmkit_lowram)

		setup_isr()
		play_music()
	}

	sub setup_isr() {
		zsmkit.zsmkit_setisr()
	}

	sub play_music() {
		uword zsmptr
		ubyte zsmbank

		txt.cls()

		zsmkit.zsm_setbank(0, 2)
		zsmkit.zsm_setmem(0, $A000)

		zsmkit.zsm_play(0)
		repeat {
			sys.waitvsync()
			void, zsmptr, zsmbank = zsmkit.zsm_getptr(0)
			txt.home()
			txt.print_ubhex(zsmbank, true)
			txt.print(":")
			txt.print_uwhex(zsmptr, false)
		}
	}
}
