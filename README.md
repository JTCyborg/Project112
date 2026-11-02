# Project112 — ATM Turbo 2+ video-mode demonstrator

Target: ATM Turbo 2+ v7.10 / UnrealSpeccy.

## Build

Run `build.bat` from the `112` directory. It assembles `src/main.asm` and creates:
- `project112.TRD`
- `list.txt` — SjASMPlus listing
- `map.txt` — symbol map

## Keyboard

Press Space to cycle through all four ATM video modes.

## Implemented video modes

1. Sinclair 256x192 — standard Spectrum bitmap and attributes.
2. ATM 640x200 — hardware multicolor; page 5 bitmap, page 1 attributes.
3. ATM 320x200 — EGA-style 16-color graphics; four 8K layers across pages 1 and 5.
4. ATM 80x25 — hardware text generator; character codes in page 5, attributes in page 1.

The system port is addressed as full I/O address `#FF77`. Mode values are `3, 2, 0, 6`; bit 7 is set for ATM 7.10. See `112/src/video_mode_control.asm`.

## Memory and mode switching

The ATM hi-res modes use page 5 at `$4000` and page 1 at `$C000`. For 640x200 and 80x25, even and odd columns occupy separate 8K halves. EGA 320x200 uses the four layer bases `$C000`, `$4000`, `$E000`, `$6000`.

The mode-switch trampoline is placed in the first 32-byte block at `$8000`, where A5..A7 and A8..A10 match. It jumps to a re-entry point instead of returning through a stack across the mode transition.

## UnrealSpeccy configuration

The repository `unreal.ini` selects ATM Turbo 2+ v7.10:
- `HIMEM=ATM710`
- `RAMSize=1024`
- `EFF7mask=0`
- `AtmMemSwap=0`
- `UsePalette=1`
- `ROMSET=ATM2`

The configured ATM2 BIOS file must be present in the emulator directory. The current setting is `ATM2=bios_1_07_13.rom`.

## Validation status

The source has been migrated to ATM-native memory layouts and the four ATM mode values. It has **not yet been assembled or run in UnrealSpeccy in this environment**. The first test must confirm mode transitions and visible output in all four modes. In particular, verify the ATM 80x25 character generator and EGA color-pair encoding against the emulator/real board.
