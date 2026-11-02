# Project112
ZX Spectrum Pentagon 1024 project

## UnrealSpeccy configuration for the 384x304 test

The fifth test mode writes the complete 384x304 Pentagon display area. UnrealSpeccy must be configured to expose the full border area; setting port #EFF7 to $40 does not change the host display geometry.

Use the following settings in the active UnrealSpeccy configuration:

```ini
[MISC]
HIMEM=PENTAGON
RAMSize=1024
EFF7mask=0

[ULA]
Preset=PENTAGON
PRESET.PENTAGON=71680,17989,224,50,32,0,0,0,0,0,320,240,24,32,384,304,48,64

[VIDEO]
Border=wide
```

Important:
- `Border=wide` selects `conf.bordersize=2`, which makes `temp.scx=384`.
- `PRESET.PENTAGON` must set `mcx_full=384` and `mcy_full=304`. The stock preset's `mcy_full=288` is insufficient for this test.
- `EFF7mask=0` allows the program to set D6 (384x304).
- Restart UnrealSpeccy after changing the configuration, then load `project112.TRD`.
- Do not change the address routines in `112/src/mode_384.asm` to compensate for a 320x240 or 384x288 host display: that would make the Pentagon memory layout incorrect.

The other four test modes remain available; the wide border setting changes the emulator's visible border area, not the hardware mode selected by the test program.
