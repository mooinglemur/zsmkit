# zsmkit
Advanced music and sound effects engine for the Commander X16

Code is in an early alpha state. Some features may not work correctly.

Due to bugs in the audio bank routine `psg_write` in earlier ROMs, the minimum earliest release supported will be R44. It should work with current master of x16-rom.

## Overview

ZSMKit is a ZSM playback library for the Commander X16. It aims to be an alternative to ZSound, but with several new features and advantages. Features shared with ZSound include:

* Playback of ZSM files from high RAM
* Looping
* Pausing and resuming playback
* ZSM tick rates other than 60 are normalized to 60
* Ability to alter tick rate to change tempo
* ZCM playback support

It also has these features that ZSound currently lacks:

* Playback of ZSM files streamed from open files on SD card
* Four playback slots (0-3)
* Multiple simultaneous slot playback, with priority-based channel arbitration and automatic restore of state when higher priorities end playback
* "Master volume" control for each playback slot
    * Individual voices' master volumes can also be overridden
* ZSM files with PCM tracks are now handled and their PCM data is played back
* ZSM synchronization messages are passed into an optional callback routine
* Uses YM chip detection routine in ROM >= R44 and redirects LFO reset writes to register $09 if the chip type is OPP. (code has been written but the logic is currently disabled)

These features are planned but not yet implemented

* Feature to suspend specific channels for all priorities, allowing the channel/voice to be used outside of ZSMKit, such as simple in-game sound effects, for instance.


### Priority system

In the code and documentation, a song slot is also known as a **priority**. There are four priorities, numbered from 0 to 3.  

Priority 0 is the lowest priority. It would typically used for playback of background game music, as an example.  Priority 0 is also the only slot in which LFO parameters are honored (YM2151 registers < $20)

Priorities 1-3 would typically be used for short jingles and sound effects.

When composing/arranging your music and sound effects, keep channel use in mind. For more seamless playback, sound effects are best written to be played on channels that are not used by your main BGM music, or choose channels whose absence in your BGM are less noticeable if they are taken over by the higher priority playback.

## Building and using in your project

This library was written for the `cc65` suite.  As of the writing of this documentation, it is geared toward including in assembly language projects.

To build the library, run
`make`
from the main project directory. This will create `lib/zsmkit.lib`, which you can build into your project.

You will likely want to include the file `src/zsmkit.inc` into your project as well for the library's label names.

## Alternative builds

For non-ca65/cc65 projects, there is one existing option. The build can produce the file `lib/8010.bin` by calling
`make incbin`
This file can be included at orign $0810 in your project.  The jump table addresses can be found the file `src/zsmkit8010.inc`.

## Prerequisites

This library requires a custom linker config in order to specify two custom segments.  This documentation assumes you are familiar with creating custom cc65 linker configs.

Specifically, this library requires the `ZSMKITLIB` segment and the `ZSMKITBANK` segment.  The `ZSMKITLIB` **must** be located in low RAM, and the `ZSMKITBANK` segment is meant to point to high RAM. The linker config is only responsible for assembly of the addresses in the lib. The bank that's assigned to zsmkit is chosen at runtime, and zsmkit assumes that it has full control of that 8k bank.

NOTE: this is an incomplete linker config file, but rather a relevant example of what must be in a custom one.  You can copy the stock cx16.cfg one and make sire it includes the HIRAM region and the two custom segments.

```
MEMORY {
    ...
    MAIN:     file = %O, start = $0801,  size = $96FF;
    HIRAM:    file = "", start = $A000,  size = $2000;
    ...
}

SEGMENTS {
    ...
    CODE:       load = MAIN,     type = ro;
    ZSMKITLIB:  load = MAIN,     type = ro;
    ZSMKITBANK: load = HIRAM,    type = bss, define = yes;
    ...
}
```

## API Quick Reference

### API calls for main part of the program (ZSM)

All calls except for `zsm_tick` are meant to be called from the main loop of the program. `zsm_tick` is the only routine that is safe to call from IRQ.

---
#### `zsm_init_engine`
```
Inputs: .A = RAM bank to assign to zsmkit
```
This routine *must* be called once before any other library routines are called in order to initialize the state of the engine.

---
#### `zsm_setmem`
```
Inputs: .X = priority, .A .Y = memory location (lo hi), $00 = RAM bank
```
Sets up the song pointers and parses the header based on a ZSM that was previously loaded into RAM. If the song is valid, it marks the priority slot as playable.

---
#### `zsm_setfile`
```
Inputs: .X = priority, .A .Y = pointer (lo hi) in low RAM to null-terminated filename
```
This is an alternate song-loading method. It sets up a priority slot to stream a ZSM file from disk (SD card). The file is opened and stays open for as long as the song is playable (i.e. until `zsm_close` is called, or another song is loaded into the priority).  Instead of holding the entire ZSM in memory, it is streamed from the file in small chunks and held in a small ring buffer inside the bank assigned to ZSMKit.

For ZSM files that contain PCM data, the song will play without triggering the PCM events unless `zsm_loadpcm` is called after `zsm_setfile`.

Whenever this method is used to play a song, `zsm_fill_buffers` must be called in the main part of the program in between ticks.

See `zsm_setlfs` for LFN/device/SA defaults that are used by the engine.

---
#### `zsm_loadpcm`
```
Inputs: .X = priority, .A .Y = memory location (lo hi), $00 = RAM bank
Outputs: .A .Y = next memory location after end of load, $00 = RAM bank
```
For streamed ZSM files that have PCM data, this routine can be used to load the PCM data into memory at the specified memory location. This should be done immediately after calling `zsm_setfile` and before `zsm_play`.

---

#### `zsm_close`
```
Inputs: .X = priority
```
Cleans up any file I/O associated with a priority slot (if it's a song in streaming mode) and resets the state of the slot.

---

#### `zsm_play`
```
Inputs: .X = priority
```
Starts playback of a song.  If `zsm_stop` was called, this function continues playback from the point that it was stopped.  If the file is being streamed rather than played back from memory, this routine will ensure that the ring buffer is at least partially filled.

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

#### `zsm_fill_buffers`
```
Inputs: none
```
If you are using the streaming mode of ZSMKit (with `zsm_setfile`), call this routine once per frame/tick from the main loop of the program (not in the interrupt handler!). This will, if necessary, read some data from open files to keep the ring buffers sufficiently primed so that the `zsm_tick` call has sufficient data to process for the tick.

---
#### `zsm_setlfs`
```
Inputs: .A = lfn/sa, .X = priority, .Y = device
```
Sets the logical file number, secondary address, and IEC device for a particular priority

Must only be called from main loop routines.

Calling this function is not necessary if you wish to use defaults that have been set at engine init:

```
Priority 0: lfn/sa 11, device 8
Priority 1: lfn/sa 12, device 8
Priority 2: lfn/sa 13, device 8
Priority 3: lfn/sa 14, device 8
```

---

#### `zsm_setcb`
```
Inputs: .X = priority, .A .Y = pointer to callback, $00 = RAM bank
```

Sets up a callback address for ZSMKit to `jsr` into.  The callback is triggered whenever a song loops or ends on its own.

Inside the callback, the RAM bank will be set to whatever bank was active at the time `zsb_setcb` was called.  .X will be set to the priority, .Y will be set to the event type, and .A will be the parameter value.

|Y|A|Meaning|
|-|-|-|
|$00|$00|Song has ended normally|
|$00|$80|Song has crashed|
|$01|LSB of loop number|Song has looped|
|$02|any|Synchronization message from ZSM (sync type 0)|
|$03|Signed byte: tuning offset in 256ths of a semitone|Song tuning change from ZSM (sync type 1)|

Since this callback happens in the interrupt handler, it is important that your program process the event and then return as soon as possible. In addition, your callback routine should not fire off any KERNAL calls, or update the screen.

The callback does *not* need to take care to preserve any registers before returning.

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


### API calls for main part of the program (ZCM)

ZCM files are PCM data files with an 8-byte header indicating their bit depth, number of channels, and length. In order for ZSMKit to play them, they must be loaded into memory first, and their location in memory given to ZSMKit via the `zcm_setmem` routine. ZSMKit can track up to 32 ZCMs in memory, slots 0-31, though it's likely you'd exhaust high RAM before having that many loaded at once.

#### `zcm_setmem`
```
Inputs: .X = slot, .A .Y = memory location (lo hi), $00 = RAM bank
```
Tells ZSMKit where to find a ZCM (PCM sample) image.  This image has an 8-byte header followed by raw PCM

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
Inputs: none
```
This routine handles everything that is necessary to play the currently active songs, and to feed the PCM FIFO if any PCM events are in progress. If required, it will handle restoring channel states if, for instance, a higher priority ZSM ends or is stopped while a lower priority one is also playing.

Call this routine once per tick.  You will usually want to do this at the end of your interrupt handler routine.

---
#### `zsmkit_setisr`
```
Inputs: none
```
This sets up a default interrupt service routine that calls `zsm_tick` on every interrupt. This will work for most simple use cases of zsmkit if there's only one interrupt per frame.

---
#### `zsmkit_clearisr`
```
Inputs: none
```
This routine removes the interrupt service routine that was injected by `zsmkit_setisr`

