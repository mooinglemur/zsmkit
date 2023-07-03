%import textio
%import palette
%zeropage basicsafe

;; Proof Of Concept ZSM player using a binary blob version of zsmkit by MooingLemur
;; Can play ZSM (music).

; "issues":
; - prog8 (or rather, 64tass) cannot "link" other assembly object files so we have to incbin a binary blob.
; - prog8 main has to be set to a fixed address (in this case $0830) to which the special zsmkit binary has been compiled as well.


main $0830 {

zsmkit_lib:
	; this has to be the first statement to make sure it loads at the specified module address $0830
	%asmbinary "zsmkit-0830.bin"

	romsub $0830 = zsm_init_engine(ubyte bank @A) clobbers(A, X, Y)
	romsub $0833 = zsm_tick() clobbers(A, X, Y)

	romsub $0836 = zsm_play(ubyte prio @X) clobbers(A, X, Y)
	romsub $0839 = zsm_stop(ubyte prio @X) clobbers(A, X, Y)
	romsub $083c = zsm_rewind(ubyte prio @X) clobbers(A, X, Y)
	romsub $083f = zsm_close(ubyte prio @X) clobbers(A, X, Y)
	romsub $0842 = zsm_fill_buffers() clobbers(A, X, Y)
	romsub $0845 = zsm_setlfs(ubyte prio @X, ubyte lfn_sa @A, ubyte device @Y) clobbers(A, X, Y)
	romsub $0848 = zsm_setfile(ubyte prio @X, str filename @AY) clobbers(A, X, Y)
	romsub $084b = zsm_setmem(ubyte prio @X, uword data_ptr @AY) clobbers(A, X, Y)
	romsub $084e = zsm_setatten(ubyte prio @X, ubyte value @A) clobbers(A, X, Y)

	romsub $0851 = zcm_setmem(ubyte slot @X, uword data_ptr @AY) clobbers(A, X, Y)
	romsub $0854 = zcm_play(ubyte slot @X, volume @A) clobbers(A, X, Y)
	romsub $0857 = zcm_stop() clobbers(A, X, Y)

	const ubyte zsmkit_bank = 1

	sub start() {
		txt.print("zsmkit demo program (drive 8)!\n")

		zsm_init_engine(zsmkit_bank)
		play_music()
	}

	sub play_music() {
		zsm_setfile(0, iso:"MUSIC.ZSM")
		zsm_play(0)

		bool paused = false
		uword oldjoy = $ffff

		repeat {
			uword newjoy = cx16.joystick_get2(0)
			if (newjoy != oldjoy and (newjoy & $10) == 0) {
				if (paused) {
					zsm_play(0)
					paused = false
				} else {
					zsm_stop(0)
					paused = true
				}
				zsm_close(1)
				zsm_setfile(1, iso:"PAUSE.ZSM")
				zsm_play(1)
			}
			oldjoy = newjoy

			sys.waitvsync()
			if (not paused) {
				txt.print(".")
			}
			zsm_tick()
			zsm_fill_buffers()
		}
	}
}
