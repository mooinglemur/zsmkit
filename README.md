# ZSMKit
Advanced music and sound effects engine for the Commander X16

The minimum Commander X16 ROM release supported is R44.

This is **ZSMKit v2**. If you're looking for the legacy version which supports streaming from disk, check out the [v1 branch](https://github.com/mooinglemur/zsmkit/tree/v1).

## Overview

ZSMKit is a ZSM playback library for the Commander X16. It aims to be an alternative to ZSound, but with several new features and advantages. Features shared with ZSound include:

* Playback of ZSM files from high RAM
* Looping
* Pausing and resuming playback
* ZSM tick rates other than 60 are normalized to 60
* Ability to alter tick rate to change tempo
* ZCM playback support

It also has these features that ZSound currently lacks:

* Eight playback slots with priorities (0-7).
    * Priority slot 0 supports YM2151 (with LFO usage), PSG, and PCM events.
    * Priority slots 1-3 support YM2151 (except for LFO usage), PSG, and PCM events
    * Priority slots 4-7 support PSG and PCM events
* Multiple simultaneous slot playback, with priority-based channel arbitration and automatic restore of state when higher priorities end playback
* "Master volume" control for each playback slot
    * Individual voices' master volumes can also be overridden
* ZSM files with PCM tracks are now handled and their PCM data is played back
* ZSM synchronization messages are passed into an optional callback routine
* Uses YM chip detection routine in ROM >= R44 and redirects LFO reset writes to register $09 if the chip type is OPP/YM2164.
* Ability to suspend use of individual PSG and YM2151 channels in order to use them outside of ZSMKit, even if the song playback would otherwise use them.  Useful for stealing channels for programmed sound effects.

## Support

The main discussion area for help with ZSMKit is in the [Commander X16 Discord server](https://discord.gg/nS2PqEC) in the [ZSMKit channel](https://discord.com/channels/547559626024157184/1315189964077531177).

## Priority system

In the code and documentation, a song slot is also known as a **priority**. There are eight priorities, numbered from 0 to 7.

Priority 0 is the lowest priority, and thus can be interrupted by any other priority. It would typically used for playback of background game music, as an example.  Priority 0 is also the only slot in which LFO parameters are honored (YM2151 registers < $20)

Priorities 1-7 would typically be used for short jingles and sound effects. Priorities 4-7 handle VERA PSG and PCM events but lack support for YM2151 events.

When composing/arranging your music and sound effects, keep channel use in mind. For more seamless playback, sound effects are best written to be played on channels that are not used by your main BGM music, or choose channels whose absence in your BGM are less noticeable if they are taken over by the higher priority playback.

In addition, when a song that is currently playing has channels that are restored from being suspended, either by calling `zsm_play` after being paused, or via a higher priority song ending or being stopped, notes that were supposed to be playing on the YM2151 during the suspension are not restored mid-note. The channel will sound again once the next key down event occurs. Please be aware of this when putting lengthy legatos in your BGM as such passages may stay silent longer than you'd expect if they're interrupted.

The behavior in the previous paragraph is however not a concern on VERA PSG as notes are simply defined by their channel volume. A VERA channel being un-suspended will immediately play sound if the priority on the restored channel calls for it.

## Using in your project

ZSMKit is distributed as a binary, meant to be loaded at `$A000` in any available high RAM bank. An include file `"zsmkit.inc"` is available for ca65 and similar assemblers which map the calls to a stable jump table starting at `$A000`.

1. Choose a RAM bank that ZSMKit will live in, switch to that RAM bank and load the `zsmkit-a000.bin` file from disk to $A000.
2. Set aside 256 bytes of low RAM that ZSMKit is allowed to use.  Activate the ZSMKit RAM bank, and call `zsm_init_engine` with .X .Y (low, high) set to the address of this low RAM region.  A simple solution is to use part of the region between $400 and $7FF, but you can also designate any other 256 byte region in low ram that is not otherwise in use.
3. Use the rest of the ZSMKit API to set up and play back songs, taking care to activate the assigned ZSMKit bank before calling into the library.

## Building from scratch

This requires the `cc65` suite to rebuild.

To build the library, run  
`make`  
from the main project directory. This will create `lib/zsmkit-a000.bin`, which you can load in your project.

You will likely want to include the file `src/zsmkit.inc` into your project as well for the library's label names.

## Calling the library from assembly

All of the public API calls start at the beginning of the $A000 space 

## API Quick Reference

### API calls for main part of the program (ZSM)

All calls except for `zsm_tick` are meant to be called from the main loop of the program. `zsm_tick` is the only routine that is safe to call from IRQ.

---
#### `zsm_init_engine`
```
Inputs: .X .Y = (lo hi) Low RAM address of 256 bytes of data that ZSMKit will use for trampolines, the default IRQ handler code, and PCM FIFO-feeding code
```
This routine *must* be called once before any other library routines are called in order to initialize the state of the engine.

---
#### `zsm_midi_init`
```
Inputs: .A = MIDI device I/O base offset from $9F00, 0 to disable
        .X = serial/parallel toggle
        .C = callback flag
```
This function initializes ZSMKit's MIDI event handler and informs ZSMKit of the IO address of the MIDI device.  If this function is never called after `zsm_init_engine`, MIDI events in ZSMs are ignored.

MIDI events are encoded in ZSMs as EXTCMD expansion audio blocks with Chip ID 1 (MIDI 1).  ZSMKit does not process events for Chip ID 2 (MIDI 2).

If .A = 0, MIDI device output is disabled.

If .X = 0, the MIDI device is a serial UART (16C550 compatible), in which case .A should always be a multiple of 8.
If .X is nonzero, the MIDI device is a SAM2695 or similar with a parallel interface, with two adjacent memory-mapped registers.

If carry is set, all MIDI events are routed through the callback with event type $20. The callback will receive every byte as an individual callback.  The callback will be called for MIDI events even if device output is disabled (.A = 0).

If carry is clear, MIDI events will not be routed through the callback.

---
#### `zsm_setbank`
```
Inputs: .X = priority, .A = RAM bank
```
Call this prior to calling `zsm_setmem`.

This function expects the RAM bank where the ZSM data starts. After calling this routine, call `zsm_setmem` to finish the setup of a priority slot.

---
#### `zsm_setmem`
```
Inputs: .X = priority, .A .Y = memory location (lo hi)
Preparatory routine: `zsm_setbank`
```
Prior to calling, call `zsm_setbank` to set the bank where the ZSM data starts.

This function sets up the song pointers and parses the header based on a ZSM that was previously loaded into RAM. If the song is deemed valid, it marks the priority slot as playable.

---

#### `zsm_close`
```
Inputs: .X = priority
```
Resets the state of the slot. This routine can be used to permanently stop a song's playback.

---

#### `zsm_play`
```
Inputs: .X = priority
```
Starts playback of a song.  If `zsm_stop` was called, this function continues playback from the point that it was stopped.

---
#### `zsm_stop`
```
Inputs: .X = priority
```
Pauses playback of a song. Playback can optionally be resumed from that point later with `zsm_play`.

---
#### `zsm_rewind`
```
Inputs: .X = priority
```
Stops playback of a song (if it is already playing) and resets its pointer to the beginning of the song. Playback can then be started again with `zsm_play`.

---
#### `zsm_setatten`
```
Inputs: .X = priority, .A = attenuation value
```

Changes the master volume of a priority slot by setting an attenuation value. A value of $00 implies no attenuation (full volume) and a value of $3F is full mute.

Attenuation is set on all active channels for the priority, and will also affect PCM events played on the priority. The YM2151's attenuation (0.75 dB native) is scaled lower so that it matches the 0.5 dB per step of the VERA PSG. PCM attenuation is scaled to 1/4 the input value.

---

#### `zsm_setcb`
```
Inputs: .X = priority, .A .Y = pointer to callback
```

Sets up a callback address for ZSMKit to `jsr` into.  The callback is triggered whenever a song loops or ends on its own, or a synchronization message is processed in the ZSM data.

Inside the callback, .X will be set to the priority, .Y will be set to the event type, and .A will be the parameter value.

|Y|A|Meaning|
|-|-|-|
|$00|$00|Song has ended normally|
|$00|$80|Song has crashed|
|$01|LSB of loop number|Song has looped|
|$02|any|Synchronization message from ZSM (sync type 0)|
|$03|Signed byte: tuning offset in 256ths of a semitone|Song tuning change from ZSM (sync type 1)|
|$10|(undefined)|On deck song has been promoted to active song|
|$20|data|MIDI byte from ZSM|


Since this callback happens in the tick, usually the interrupt handler, it is important that your program process the event and then return as soon as possible. In addition, your callback routine should not fire off any KERNAL calls, or update the screen.

The callback does *not* need to take care to preserve any registers before returning, but the active RAM and ROM bank must be set to the values they were upon entry.

ZSM sync type 0 note: Furnace tracker can be used to create this type of event by placing the `EExx` effect in any VERA channel. However, please note that this effect will not be exported in ZSMs if placed in a YM2151 channel.  For example, the effect `EE64` will call the callback with Y = $02 and A = $64 at the moment of the event during playback. This can be useful for synchronization of game animations with the music, or for any other scenario when the application needs to do something at a certain point in the music.

ZSM sync type 1 note: ZSM exports from Furnace will have an event of sync type 1 in the first tick of the song (but not necessarily the first event). The only known user of this information is Melodius, which adjusts its visualizations based on this tuning.  A real world example is that for Furnace projects that are tuned to, for instance, A=432 rather than A=440, the tuning information is used to make it so that the note visualizations are not all shown as pitch-bent.


---
#### `zsm_clearcb`
```
Inputs: .X = priority
```
Clears the callback assigned to the priority.

Note: The callback settings for a priority are not cleared if the priority switches songs. If you have run `zsm_setcb` on a priority, it persists until `zsm_clearcb` (or `zsm_init_engine`) is called.

---

#### `zsm_getstate`
```
Inputs: .X = priority
Outputs: .C = playing, Z = not playable, .A .Y = (lo hi) loop counter
```
Returns the playback state of a priority.

If the priority is currently playing, carry will be set.

If the priority is in an unplayable state, the Z flag will be set.

The loop counter will indicate the number of times the song has looped.

---

#### `zsm_setrate`
```
Inputs: .X = priority, .A .Y = (lo hi) new tick rate
Outputs: none
```
Sets a new tick rate for the ZSM in this priority.

Note: ZSMKit expects to have its tick subroutine called at approximately 60Hz. If a ZSM file contains PCM events, it's critical that ZSMKit's tick is run at approximately 60 times a second.

ZSM files have a tick rate which usually matches, at 60 Hz, but this isn't always the case.  ZSMKit will scale the tempo based on the ratio between the ZSM's tick rate and 60 Hz. `zsm_setrate` can be used to override the value in the ZSM. It's mainly useful for changing the tempo of a song.

---


#### `zsm_getrate`
```
Inputs: .X = priority
Outputs: A .Y = (lo hi) tick rate
```
Returns the value of the tick rate for the ZSM in this priority.

---


#### `zsm_setloop`
```
Inputs: .X = priority, .C = whether to loop
Outputs: none
```
If carry is set, enable the looping behaivor. If carry is clear, disable looping.

By default, the ZSM file indicates whether it is meant to be looped, and will specify a loop point.

This routine can be used to override this behavior.

---

#### `zsm_opmatten`
```
Inputs: .X = priority, .Y = channel, .A = value
Outputs: none
```
Changes the volume of an individual OPM channel for a priority slot by setting an attenuation value. A value of $00 implies no attenuation (full volume) and a value of $3F is full mute.

---


#### `zsm_psgatten`
```
Inputs: .X = priority, .Y = channel, .A = value
Outputs: none
```
Changes the volume of an individual PSG channel for a priority slot by setting an attenuation value. A value of $00 implies no attenuation (full volume) and a value of $3F is full mute.

---

#### `zsm_pcmatten`
```
Inputs: .X = priority, .A = value
Outputs: none
```
Changes the volume of the PCM channel for a priority slot by setting an attenuation value. A value of $00 implies no attenuation (full volume) and a value of $3F is full mute.

Even though the PCM channel's volume has a 4-bit resolution, the attenuation value is scaled so that attentuation values affect all three outputs in a similar way.

---

#### `zsm_set_int_rate`
```
Inputs: .A = new rate (integer portion in Hz)
        .Y = new rate (fractional portion in 1/256th Hz)
Outputs: none
```
Sets a new global interrupt rate in Hz. This will be the number of times per second that ZSMKit expects to have its tick subroutine called to advance the music data.

Note: If you expect to play PCM sounds, either in songs or as ZCMs, you will still need to call `zsm_tick` with .A = 1 at a rate of approximately 60 times per second in order to keep the FIFO filled.  See [`zsm_tick`](#zsm_tick) for details.

Calling `zsm_init_engine` will reset this value to 60.

---
#### `zsm_set_ondeck_bank`
```
Inputs: .X = priority, .A = RAM bank
```
Call this prior to calling `zsm_set_ondeck_mem`.

This function expects the RAM bank where the ZSM data starts. After calling this routine, call `zsm_set_onbank_mem` to finish the setup of the "on deck" ZSM data for a priority slot.

---
#### `zsm_set_ondeck_mem`
```
Inputs: .X = priority, .A .Y = memory location (lo hi)
Preparatory routine: `zsm_set_ondeck_bank`
```
Prior to calling, call `zsm_set_ondeck_bank` to set the bank where the ZSM data starts.

This function sets up the song pointers and parses the header based on a ZSM that was previously loaded into RAM. If the song is deemed valid, it populates the on-deck data for this priority slot.

The on-deck song is simply the ZSM that will play once the active song completes.  If the active song is configured to loop, it will loop as normal.  It can be useful to use this mechanism with a looping song as an event-based song or musical section switch.  If the loop flag is cleared with the `zsm_setloop` call, the on-deck song will become active once the active song ends.

---
#### `zsm_clear_ondeck`
```
Inputs: .X = priority
```
This function clears the on-deck song previously set by `zsm_set_ondeck_mem`.  If the priority is playing, the priority will stop playback as normal once the song ends.

---
#### `zsm_getloop`
```
Inputs: .X = priority
Outputs: .C = looped flag, .A = bank, .X .Y (lo hi) = address
```
If the requested priority is playable and has a loop point, this function will return the address and bank of the loop point in registers, with carry clear.

If the priority is not playable or not looped, the function will return with carry set, and .A, .X, and .Y will be undefined.

---
#### `zsm_getptr`
```
Inputs: .X = priority
Outputs: .C = looped flag, .A = bank, .X .Y (lo hi) = address
```
If the requested priority is playable, this function will return the address and bank of the playback cursor in registers, with carry clear.

If the priority is not playable, the function will return with carry set, and .A, .X, and .Y will be undefined.

---
#### `zsm_getksptr`
```
Inputs: .X = priority
Outputs: .X .Y (lo hi) = address
```

This function returns a pointer to the location of the OPM KON shadow inside ZSMKit's RAM bank.
The KON shadow is an 8-byte region of memory which contains the most recent KON event processed for each of the eight OPM channels in the requested priority.  The first byte is for OPM channel 0, and the last byte is for channel 7.

The format of each shadow entry looks like this:

<table>
  <tr>
    <td>7</td>
    <td>6</td>
    <td>5</td>
    <td>4</td>
    <td>3</td>
    <td>2</td>
    <td>1</td>
    <td>0</td>
  </tr>
  <tr>
    <td> - </td>
    <td>C2</td>
    <td>M2</td>
    <td>C1</td>
    <td>M1</td>
    <td colspan="3">Channel</td>
  </tr>
</table>

If any of the M1, C1, M2, or C2 bits are set, the key has been "pressed", but if all of those bits are clear, then the key is "released".

The primary use case is for player visualizations.

---
#### `zsm_getosptr`
```
Inputs: .X = priority
Outputs: .X .Y (lo hi) = address
```

This function returns a pointer to the OPM shadow inside ZSMKit's RAM bank.
The OPM shadow is a 256-byte region of memory which contains the most recent register write for the OPM chip in the requested priority.  Regardless of whether the priority owns the channel, the shadow is updated with the intended register write, whether or not it was written to the chip in real time.

Internally, ZSMKit uses the OPM shadow to manage suspension and restoration of channel state.

Exposing the memory location via this function is mainly useful for player visualizations.

---
#### `zsm_getpsptr`
```
Inputs: .X = priority
Outputs: .X .Y (lo hi) = address
```

This function returns a pointer to the VERA PSG shadow inside ZSMKit's RAM bank.
The PSG shadow is a 64-byte region of memory which contains the most recent register write for the VERA PSG in the requested priority.  Regardless of whether the priority owns the channel, the shadow is updated with the intended register write, whether or not it was written to the chip in real time.

Internally, ZSMKit uses the PSG shadow to manage suspension and restoration of channel state.

Exposing the memory location via this function is mainly useful for player visualizations.

---
#### `zsm_psg_suspend`
```
Inputs: .Y = channel (0-15)
        .C = if set, suspend; if clear, release
```

This function suspends or restores ZSMKit's use of a VERA PSG channel.

This action is GLOBAL, and will prevent ZSMKit from touching registers for this channel for as long as it's suspended.

Suspension is useful to allow for programmed sound effects to play independent of ZSMKit.

---
#### `zsm_opm_suspend`
```
Inputs: .Y = channel (0-7)
        .C = if set, suspend; if clear, release
```

This function suspends or restores ZSMKit's use of an OPM channel.

This action is GLOBAL, and will prevent ZSMKit from touching registers for this channel for as long as it's suspended.

Suspension is useful to allow for programmed sound effects to play independent of ZSMKit.

---
#### `zsm_pcm_suspend`
```
Inputs: .C = if set, suspend; if clear, release
```

This function suspends or restores ZSMKit's use of the VERA PCM channel.

This action is GLOBAL, and will prevent ZSMKit from touching registers for this channel for as long as it's suspended.

While PCM is suspended, ZSMKit will not play ZCM files either.

Suspension is useful to allow for programmed sound effects to play independent of ZSMKit.

---


### API calls for main part of the program (ZCM)

ZCM files are PCM data files with an 8-byte header indicating their bit depth, number of channels, and length. In order for ZSMKit to play them, they must be loaded into memory first, and their location in memory given to ZSMKit via the `zcm_setbank` and `zcm_setmem` routines. ZSMKit can track up to 32 ZCMs in memory, slots 0-31, though it's likely you'd exhaust high RAM before having that many loaded at once.

#### `zcm_setbank`
```
Inputs: .X = slot, .A = RAM bank
```
Tells ZSMKit which bank to find a ZCM (PCM sample) image. After calling this routine, call `zcm_setmem` to pass the address to finish setting up the slot.


#### `zcm_setmem`
```
Inputs: .X = slot, .A .Y = memory location (lo hi)
Preparatory routines: `zcm_setbank`
```
Tells ZSMKit what address to find a ZCM (PCM sample) image.  This image has an 8-byte header followed by raw PCM

---
#### `zcm_play`
```
Inputs: .X = slot, .A = volume
```
Starts playback of a ZCM PCM sample. This playback will take priority over any other PCM events in progress until either playback finishes or it is explicitly stopped with `zcm_stop`.

---
#### `zcm_stop`
```
Inputs: none
```
If a ZCM is playing when this routine is called, playback is immediately stopped. If a non-ZCM PCM sound is playing, or nothing is playing on the PCM channel, this routine does nothing.

### API calls for interrupt handler

This routine is the only one that is safe to call from an IRQ handler.

---
#### `zsm_tick`
```
Inputs: .A = 0 (tick music data and PCM)
        .A = 1 (tick PCM only)
        .A = 2 (tick music data only)
```
This routine handles everything that is necessary to play the currently active songs, and to feed the PCM FIFO if any PCM events are in progress. If required, it will handle restoring channel states if, for instance, a higher priority ZSM ends or is stopped while a lower priority one is also playing.

Call this routine once per tick.  You will usually want to do this at the end of your interrupt handler routine.  You will usually want to call this with .A = 0 to tick both music data and PCM. The other values are useful if you want to tick the music at a rate different than 60 Hz. You will still want to tick the PCM at ~60 Hz, then use, for instance, a VIA timer to tick the music data at a different rate.

ZSMKit will need to know how often you plan to call its music data tick routine if the value is not the default of 60 Hz. Call `zsm_set_int_rate` to change this value.

### Miscellaneous API calls

---
#### `zsmkit_setisr`
```
Inputs: none
```
This sets up a default interrupt service routine that calls `zsm_tick` on every interrupt. The existing IRQ handler is called afterwards. This will work for most simple use cases of ZSMKit if there's only one interrupt per frame: VERA's VSYNC interrupt.

---
#### `zsmkit_clearisr`
```
Inputs: none
```
This routine removes the interrupt service routine that was injected by `zsmkit_setisr`

---
#### `zsmkit_version`
```
Inputs: none
Outputs: .A = major version, .X = minor version
```
This returns the ZSMKit version.  Even-numbered minor versions are releases. Odd-numbered minor-versions are in development.

