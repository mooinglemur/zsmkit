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

It also has these features that ZSound currently lacks:

* Playback of ZSM files streamed from open files on SD card
* Four playback slots (0-3)
* Multiple simultaneous slot playback, with priority-based channel arbitration and automatic restore of state when higher priorities end playback.
* "Master volume" control for each playback slot.

These features are planned but not yet implemented
* Callback from library into the application for loop/end notification
* Ability to dynamically alter the tempo
* Ability to fetch current song state
* Feature to suspend specific channels for all priorities, allowing the channel/voice to be used outside of ZSMKit, such as simple in-game sound effects, for instance.

This potential ZSM feature is missing from both ZSound and ZSMkit:

* PCM channel playback

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

### API calls for main part of the program

All calls except for `zsm_tick` are meant to be called from the main loop of the program. `zsm_tick` is the only routine that is safe to call from IRQ.

---
#### `init_engine`
```
Inputs: .A = RAM bank to assign to zsmkit
```
This routine *must* be called once before any other library routines are called in order to initialize the state of the engine.

---
#### `zsm_setmem`
```
Inputs: .X = priority, .A .Y = memory loction (lo hi), $00 = RAM bank
```
Sets up the song pointers and parses the header based on a ZSM that was previously loaded into RAM. If the song is valid, it marks the priority slot as playable.

---
#### `zsm_setfile`
```
Inputs: .X = priority, .A .Y = pointer (lo hi) in low RAM to null-terminated filename
```
This is an alternate song-loading method. It sets up a priority slot to stream a ZSM file from disk (SD card). The file is opened and stays open for as long as the song is playable (i.e. until `zsm_close` is called, or another song is loaded into the priority).  Instead of holding the entire ZSM in memory, it is streamed from the file in small chunks and held in a small ring buffer inside the bank assigned to ZSMKit.

Whenever this method is used to play a song, `zsm_fill_buffers` must be called in the main part of the program in-between ticks.

See `zsm_setlfs` for LFN/device/SA defaults that are used by the engine.

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
Starts playback of a song.  If `zsm_stop` was called, this function continues playback from the point that it was stopped.  If the file is being streamed rather than played back from memory

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

Changes the master volume of a priority slot by setting an attenuation value. A value of 0 implies no attenuation (full volume) and a value of $7F is full mute.  A value of $3F will be quiet enough to mute all PSG channels and the YM2151 should effectively be muted but may be minimally audible. A value of $7F should be sufficient to mute all audio.

Attenuation is set on all active channels for the priority. The YM2151's attenuation (0.75 dB native) is scaled lower so that it matches the 0.5 dB per step of the VERA PSG.

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

### API calls for interrupt handler

This routine is the only one that is safe to call from an IRQ handler.

---
#### `zsm_tick`
```
Inputs: none
```
This routine handles everything that is necessary to play the currently active songs. If required, it will handle restoring channel states if, for instance, if two songs are playing, then the higher priority song stops playing.

Call this routine once per tick.  You will usually want to do this at the end of your interrupt handler routine.

