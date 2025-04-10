#ifndef _ZSMCKIT_H
#define _ZSMCKIT_H

// Used to make code shorter and more readable
typedef unsigned char u8;
typedef unsigned int u16;

// These values are used to tell zsm_tick what to update
#define MUSIC_PCM  0
#define PCM_ONLY   1
#define MUSIC_ONLY 2

// These values are used to interpret the state of a priority
#define PLAYING    1
#define UNPLAYABLE 2

// This structure is used as return value from zsm_getloop and zsm_getptr
typedef struct _zsm_priority_info {
	u8 bank;
	u16 address;
};

// This structure is used as return value from zsm_getstate
typedef struct _zsm_priority_state {
	u8 state;
	u16 loopcounter;
};

// This structure is used as return value from zsmkit_version
typedef struct _zsm_version {
	u8 majorVersion;
	u8 minorVersion;
};

// void callbackfunction(u8 eventtype, u8 priority, u8 paramval)
typedef void(*zsm_callback)(u8, u8, u8);

extern void			  __fastcall__ zsm_init_engine(u16 addr, u8 bank);
extern void			  __fastcall__ zsm_tick(u8 what);
extern void			  __fastcall__ zsm_play(u8 priority);
extern void			  __fastcall__ zsm_stop(u8 priority);
extern void			  __fastcall__ zsm_rewind(u8 priority);
extern void			  __fastcall__ zsm_close(u8 priority);
						 // Returns all 0's if not playable or not looped
extern struct _zsm_priority_info  __fastcall__ zsm_getloop(u8 priority);
						// Returns all 0's if priority not playable
extern struct _zsm_priority_info  __fastcall__ zsm_getptr(u8 priority);
extern u16			  __fastcall__ zsm_getksptr(u8 priority);
extern void			  __fastcall__ zsm_setbank(u8 priority, u8 bank);
extern void			  __fastcall__ zsm_setmem(u8 priority, u16 addr);
extern void			  __fastcall__ zsm_setatten(u8 priority, u8 attenuation);
extern void			  __fastcall__ zsm_setcb(u8 priority, zsm_callback);
extern void			  __fastcall__ zsm_clearcb(u8 priority);
extern struct _zsm_priority_state __fastcall__ zsm_getstate(u8 priority);
extern void			  __fastcall__ zsm_setrate(u8 priority, u16 tickrate);
extern u16			  __fastcall__ zsm_getrate(u8 priority);
extern void 			  __fastcall__ zsm_setloop(u8 priority, u8 loop);
extern void			  __fastcall__ zsm_opmatten(u8 priority, u8 channel, u8 value);
extern void			  __fastcall__ zsm_psgatten(u8 priority, u8 channel, u8 value);
extern void			  __fastcall__ zsm_pcmatten(u8 priority, u8 value);
extern void			  __fastcall__ zsm_set_int_rate(u8 rate, u8 fractional);
extern u16			  __fastcall__ zsm_getosptr(u8 priority);
extern u16			  __fastcall__ zsm_getpsptr(u8 priority);
extern void			  __fastcall__ zcm_setbank(u8 slot, u8 bank);
extern void			  __fastcall__ zcm_setmem(u8 slot, u16 addr);
extern void			  __fastcall__ zcm_play(u8 slot, u8 volume);
extern void			  __fastcall__ zcm_stop();
extern void			  __fastcall__ zsmkit_setisr();
extern void			  __fastcall__ zsmkit_clearisr();
extern struct _zsm_version	  __fastcall__ zsmkit_version();
extern void			  __fastcall__ zsm_set_ondeck_bank(u8 priority, u8 bank);
extern void			  __fastcall__ zsm_set_ondeck_mem(u8 priority, u16 addr);
extern void			  __fastcall__ zsm_clear_ondeck(u8 priority);
extern void			  __fastcall__ zsm_midi_init(u8 device_offset, u8 ser_par, u8 cb);
extern void			  __fastcall__ zsm_psg_suspend(u8 channel, u8 suspend);
extern void			  __fastcall__ zsm_opm_suspend(u8 channel, u8 suspend);
extern void			  __fastcall__ zsm_pcm_suspend(u8 suspend);

#endif
