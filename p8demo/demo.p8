%import textio
%import palette
%import zsmkit
%zeropage basicsafe

;; Proof Of Concept ZSM player using a binary blob version of zsmkit by MooingLemur

main $0830 {
	; this has to be the first statement to make sure it loads at the specified module address $0830
	%asmbinary "zsmkit-0830.bin"

	const ubyte zsmkit_bank = 1
	bool loopchanged = false
	uword loop_number = 0

	sub start() {
		txt.print("zsmkit demo program (drive 8)!\n")

		zsmkit.zsm_init_engine(zsmkit_bank)
		play_music()
	}

	asmsub cb(ubyte prio @X, ubyte type @Y, ubyte arg @A) {
		%asm {{
			cpy #1
			bne _endcb
			inc p8_loopchanged
_endcb:
			rts
		}}
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
		zsmkit.zsm_setcb(0, &cb)

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
			if (loopchanged) {
				txt.nl()
				loop_number += 1
				loopchanged = false
				txt.print(iso:"LOOP NUMBER: ")
				txt.print_uw(loop_number)
				txt.nl()
			}
			if (not paused) {
				txt.print(".")
			}
			zsmkit.zsm_tick()
			zsmkit.zsm_fill_buffers()
		}
	}
}
