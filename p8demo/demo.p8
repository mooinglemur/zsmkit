%import textio
%import palette
%import zsmkit
%zeropage basicsafe

;; Proof Of Concept ZSM player using a binary blob version of zsmkit by MooingLemur

main $0830 {
	; this has to be the first statement to make sure it loads at the specified module address $0830
	%asmbinary "zsmkit-0830.bin"

	const ubyte zsmkit_bank = 1

	sub start() {
		txt.print("zsmkit demo program (drive 8)!\n")

		zsmkit.zsm_init_engine(zsmkit_bank)
		play_music()
	}

	sub play_music() {
		uword next_free
		zsmkit.zsm_setfile(0, iso:"MUSIC.ZSM")
		cx16.rambank(2)

		txt.print(iso:"STARTING IN BANK 2, ADDRESS $A000")
		txt.nl()
		txt.print(iso:"NOW LOADING PCM FROM MUSIC.ZSM")
		txt.nl()

		next_free = zsmkit.zsm_loadpcm(0, $a000)

		txt.print(iso:"NOW AT BANK ")
		txt.print_ub(cx16.getrambank())
		txt.print(iso:", ADDRESS ")
		txt.print_uwhex(next_free, true)
		txt.nl()

		zsmkit.zsm_play(0)

		bool paused = false
		uword oldjoy = $ffff

		repeat {
			uword newjoy = cx16.joystick_get2(0)
			if (newjoy != oldjoy and (newjoy & $10) == 0) {
				if (paused) {
					zsmkit.zsm_play(0)
					paused = false
				} else {
					zsmkit.zsm_stop(0)
					paused = true
				}
				zsmkit.zsm_close(1)
				zsmkit.zsm_setfile(1, iso:"PAUSE.ZSM")
				zsmkit.zsm_play(1)
			}
			oldjoy = newjoy

			sys.waitvsync()
			if (not paused) {
				txt.print(".")
			}
			zsmkit.zsm_tick()
			zsmkit.zsm_fill_buffers()
		}
	}
}
